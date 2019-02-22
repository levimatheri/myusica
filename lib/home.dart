import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:myusica/root.dart';
import 'package:myusica/subs/location_query.dart';
import 'package:myusica/subs/autocomplete_query.dart';
import 'package:myusica/subs/availability_query.dart';
import 'package:myusica/subs/register.dart';
import 'package:myusica/subs/my_account.dart';
import 'package:myusica/helpers/myuser_item.dart';
import 'package:myusica/helpers/myuser.dart';
import 'package:myusica/helpers/access.dart';
import 'package:myusica/helpers/auth.dart';
import 'package:myusica/helpers/specializations.dart';

import 'package:geolocator/geolocator.dart';
// import 'package:android_intent/android_intent.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong/latlong.dart';

class HomePage extends StatefulWidget {
  final BaseAuth auth;
  // final VoidCallback onSignedOut;
  final String userId;
  final String username;
  final bool isMyuser;

  HomePage({Key key, this.auth, this.userId, this.username, this.isMyuser}) : super(key: key);

  @override
  HomePageState createState() => new HomePageState();
}
class HomePageState extends State<HomePage> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final GlobalKey<FormState> formKey = new GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  final List<Tab> homeTabs = <Tab>[
    Tab(text: 'Results', icon: Icon(Icons.list)), // List of matching Myusers
    Tab(text: 'Search', icon: Icon(Icons.search)), // Search criteria page
  ];
  TabController _tabController;
  Access access = new Access();

  @override
  void initState() {
    super.initState();
    _tabController = new TabController(vsync: this, length: homeTabs.length);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  _signOut() async {
    try {
      await widget.auth.signOut();
      // widget.onSignedOut();
      Navigator.push(
        context, 
        MaterialPageRoute(settings: RouteSettings(), 
          builder: (context) => RootPage(auth: widget.auth)
        )
      );
    } catch (e) {
      print(e);
    }
  }

  // Go to Myuser registration page
  _navigateToRegister() {
    Navigator.push(
      context, 
      MaterialPageRoute(settings: RouteSettings(), 
        builder: (context) => Register(userId: widget.userId, isFromProfile: false,))
    );
  }

  // Go to Profile page
  _navigateToProfile() {
    Navigator.push(
      context, 
      MaterialPageRoute(settings: RouteSettings(), 
        builder: (context) => MyAccount(auth: widget.auth, userId: widget.userId))
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController (
      length: 2,
      child: Scaffold (
        key: _scaffoldKey,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => _scaffoldKey.currentState.openDrawer(),
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: homeTabs,
          ),
          title: Text("Home"),
          automaticallyImplyLeading: false, // removes back button so that user can only use log out
        ),
        // side menu
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                child: Text(
                  "Hello " + widget.username + "!", style: TextStyle(fontStyle: FontStyle.italic, fontSize: 20.0)
                ),
                decoration: BoxDecoration(
                  color: Colors.green[800],
                ),
              ),
              ListTile(
                title: Text('My account', style: TextStyle(fontSize: 18.0)),
                onTap:  _navigateToProfile,
              ),
              // TODO: Add chat link
              // ListTile(
              //   title: Text('Chats'),
              //   onTap: null,
              // ),
              ListTile(
                title: Text('Log out', style: TextStyle(fontSize: 18.0)),
                onTap: _signOut,
              ),
              Divider(),
              // check to see if user is a myuser. If so, don't allow them to register themselves again
              !widget.isMyuser ? ListTile(
                title: Text('Register to be a myuser', style: TextStyle(fontSize: 18.0)),
                onTap: _navigateToRegister,
              ) : Container(height: 0.0, width: 0.0,),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
            children: [
              Container(
                child: Results(access: access)
              ),
              Container (
                margin: EdgeInsets.only(top: 30.0, left: 20.0, right: 20.0),
                child: Criteria(_tabController, access: access),
              ),
            ],
        ),
      ),
    );
  }

  @override
    bool get wantKeepAlive => true;
}

/// ==========RESULTS FROM DATABASE SEARCH================
class Results extends StatefulWidget {
  final Access access;
  Results({this.access});
  ResultsState createState() => new ResultsState();
}

class ResultsState extends State<Results> {
  /// Build the myuser results based on the stream from the database
  /// Filter by location and availability from the stream
  static String currCoordinates;
  static var availability;

  List<Widget> myuserItems = new List<Widget>();

  /// check if availabilities pass
  bool _areAvailabilitiesSame(Map<String, dynamic> myuserAvail, 
                              Map<String, List<String>> searchAvail) {
    // print(searchAvail);
    if (searchAvail.isEmpty) return true; // if availability is not specified, do not bother
    List<String> searchAvailKeys = searchAvail.keys.toList();
    bool areSame = false;
    searchAvailKeys.forEach((key) {
      if (myuserAvail.containsKey(key)) {
        searchAvail[key].forEach((val) {
          areSame = areSame || myuserAvail[key].containsKey(val.toLowerCase());
        });
      }
    });
    return areSame;
  }

  /// check if the location of a prospective myuser is within the select distance range
  bool _isWithinDistance(double lat1, double long1, double lat2, double long2, double acceptableRange) {
    final double dist = Distance().as(LengthUnit.Mile,
          new LatLng(lat1, long1), new LatLng(lat2, long2));
    return dist <= acceptableRange;
  }

  /// go through document snapshots from database
  List<Widget> _buildMyuserItems(List<DocumentSnapshot> docs) {
    /// filter through documents and remove what doesn't match availability and distance range
    List<String> toRemove = [];
    docs.forEach((d) {
      List<String> myuserCoordinates = (d.data['coordinates']).split(",");
      List<String> currCoordinates = ResultsState.currCoordinates.split(",");
      // check availability
      if(!_areAvailabilitiesSame(
        Map<String, dynamic>.from(d.data['availability']), 
        ResultsState.availability)) toRemove.add(d.documentID);
      // check distance
      if(!_isWithinDistance(
        double.parse(myuserCoordinates[0]), 
        double.parse(myuserCoordinates[1]), 
        double.parse(currCoordinates[0]), 
        double.parse(currCoordinates[1]), 
        CriteriaState._distSliderVal)) toRemove.add(d.documentID);
    });

    // remove what doesn't match. We feed the unwanted to an external list to prevent
    // the error of trying to remove while iterating
    docs.removeWhere((d) => toRemove.contains(d.documentID));

    List<Widget> _myuserList = new List<Widget>();
    // Map the prospective myuser(s) to a MyuserItem to be fed into the ListView
    _myuserList = docs.map((document) {
      return MyuserItem(
        myuser: Myuser.fromMap(document.data, document.documentID),
      ); 
    }).toList();

    // return list if there are result. Otherwise, show 'No results found'
    return _myuserList.length > 0 ? _myuserList : 
      [Container(margin: EdgeInsets.only(top: 60.0), child: Center(child: Text("No results found"),))];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: widget.access.query != null ? StreamBuilder(
        stream: widget.access.query.snapshots(),
        builder: (BuildContext context, 
            AsyncSnapshot<QuerySnapshot> snapshot) {
          return snapshot.hasData ? ListView(
            children: _buildMyuserItems(snapshot.data.documents)
          ) : Center(child: Text("No Myusers found."),);
        }
      ) : Center(child: Text("Click on the Search tab.")),
    );
  }
}

/// =============SEARCH CRITERIA=====================
class Criteria extends StatefulWidget {
  final TabController tabController;
  final Access access;
  Criteria(TabController tabController, {this.access}) : tabController = tabController;

  static const routeName = "/criteria";
  CriteriaState createState() => new CriteriaState();
}

class CriteriaState extends State<Criteria> with
AutomaticKeepAliveClientMixin<Criteria> {
  FocusNode _locationFocusNode = new FocusNode();
  FocusNode _specFocusNode = new FocusNode();

  final locationEditingController = new TextEditingController();
  final specializationEditingController = new TextEditingController();

  double _chargeSliderVal = 5.0;
  static double _distSliderVal = 5.0;

  Position _position;
  var _positionIsLoading = false;
  var _hasInputChanged = false;

  // Availability map
  Map<String, List<String>> _availabilityMap = new Map<String, List<String>>();
  int _availabilityItemsSelected = 0;
  List<int> _selectedItemsPositions = new List<int>();
  /// Results map
  Map<String, dynamic> finalCriteria = Map();
  List<String> criteria = ['Location', 'Specialization', 'Max Charge', 'Distance', 'Availability'];

  // constructor
  CriteriaState() {
    // initialize finalCriteria map to be added to as we go
    for (int i = 0; i < criteria.length; i++) finalCriteria[criteria[i]] = null;
  }

  @override
  void initState() {
    super.initState();
    // add listener
    _locationFocusNode.addListener(
      () => _onFocusChange(
          _locationFocusNode, LocationQuery(), locationEditingController
      )
    );
    _specFocusNode.addListener(
      () => _onFocusChange(
          _specFocusNode, AutocompleteQuery(specialization_list, "Specialization"), specializationEditingController
      )
    );
//    locationEditingController.clear();
//    specializationEditingController.clear();
    _initPlatformState();
  }

  /// open specific criteria [destination] page 
  /// when user clicks on the corresponding criteria option [fn]
  void _onFocusChange(
      FocusNode fn, dynamic destination, TextEditingController controller
      ) async {
    if (fn.hasFocus) {
      fn.unfocus();
      return;
    }
    getResult(destination, controller);
  }

  // return a Future that will complete after
  // Navigator.pop on query screen
  getResult(dynamic destination, TextEditingController controller) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => destination,
      ),
    ).then((result) {
      if (result != null) {
        controller.text = "$result";
        setState(() {
          _hasInputChanged = true;
        });
      }
    }); // put result in text field
  }

  // get current position
  Future<void> _initPlatformState() async {
    setState(() {
      _positionIsLoading = true;
    });

    final Geolocator geolocator = Geolocator()
      ..forceAndroidLocationManager = true;
    Position position;
    try {
      position = await geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low);
    } on PlatformException {
      position = null;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.s
    if (!mounted) return;

    setState(() {
      _position = position;
      _positionIsLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); //must call super.build to ensure persistence between tabs
    return
      Scrollbar(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: 5.0
            ),
            child: Container(
              margin: const EdgeInsets.only(right: 20.0),
              child: Column(
                children: <Widget>[
                  new Text(
                    "Location",
                    style: Theme.of(context).textTheme.title,
                  ),
                  _positionIsLoading ? CircularProgressIndicator() : new TextField(
                    decoration: InputDecoration(
                        hintText: "Input location"
                    ),
                    focusNode: _locationFocusNode,
                    controller: locationEditingController,
                  ),
                  separator(20.0),
                  ButtonTheme(
                    buttonColor: Colors.lightBlue,
                    child: new RaisedButton(
                      child: Text("Use current location"),
                      onPressed: _positionIsLoading ? null : () {
                        Geolocator().checkGeolocationPermissionStatus()
                            .then((permStatus) async {
                          if (permStatus == GeolocationStatus.denied) {
                            showAlertDialog(
                              ["Close", ""],
                              "Location access denied",
                              "Allow access for this app using device settings");
                          }
                          if (permStatus == GeolocationStatus.disabled) {
                          // _openLocationSettings();
                            showAlertDialog(
                                ["Okay", ""],
                                "Location services disabled",
                                "Turn on location then try again");
                          }
                          if (permStatus == GeolocationStatus.granted) {
                            await _initPlatformState();
                            locationEditingController.text = _position.toString();
                          }
                          if (permStatus == GeolocationStatus.unknown) {
                            showAlertDialog(
                                ["Close", ""],
                                "Unknown error",
                                "Please contact developer");
                          }
                        });
                      }
                    ),
                  ),
                  separator(30.0),
                  new Text(
                    "Specialization",
                    style: Theme.of(context).textTheme.title),
                  new TextField(
                    decoration: InputDecoration(
                        hintText: "Input specialization"
                    ),
                    focusNode: _specFocusNode,
                    controller: specializationEditingController,
                  ),
                  separator(35.0),
                  new Text(
                    "Max charge",
                    style: Theme.of(context).textTheme.title,
                  ),
                  new Slider(
                    activeColor: Colors.indigoAccent,
                    value: _chargeSliderVal,
                    min: 5.0,
                    max: 100.0,
                    divisions: 20,
                    onChanged: (double newCharge) {
                      setState(() {
                        _chargeSliderVal = newCharge;
                        _hasInputChanged = true;
                      });
                    },
                  ),
                  separator(10.0),
                  new Container(
                    alignment: Alignment.center,
                    child: Text("\$${_chargeSliderVal.toInt()}/hour"),
                  ),
                  separator(30.0),
                  new Text(
                    "Distance",
                    style: Theme.of(context).textTheme.title,
                  ),
                  new Slider(
                    activeColor: Colors.indigoAccent,
                    value: _distSliderVal,
                    min: 0.0,
                    max: 100.0,
                    divisions: 20,
                    onChanged: (double newDist) {
                      setState(() {
                        _distSliderVal = newDist;
                        _hasInputChanged = true;
                      });
                    },
                  ),
                  separator(10.0),
                  new Container(
                    alignment: Alignment.center,
                    child: Text("${_distSliderVal.toInt()} miles"),
                  ),
                  separator(30.0),
                  new Text(
                    "Availability",
                    style: Theme.of(context).textTheme.title
                  ),
                  separator(10.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ButtonTheme(
                        buttonColor: Colors.lightBlue,
                        child: new RaisedButton(
                          child: Text('Click to select'),
                          onPressed: () => Navigator.push(context, 
                            MaterialPageRoute(settings: RouteSettings(name: Criteria.routeName),
                            builder: (context) => AvailabilityQuery(_selectedItemsPositions, _availabilityMap))).then((result) {
                              if (result != null) {
                                _availabilityMap = result[0];
                                setState(() {
                                  _hasInputChanged = true;
                                  _availabilityItemsSelected = result[1].length;
                                  _selectedItemsPositions = result[1];
                                });
                              }
                            }),
                        ),
                      ),
                      Text("   " + _availabilityItemsSelected.toString() + " items selected"), // really bad hack!
                    ],
                  ),
                  separator(10.0),
                  ButtonTheme(
                    minWidth: 300.0,
                    buttonColor: Color(0xEFFFA500),
                    child: new RaisedButton(
                      child: Text("SEARCH"),
                      onPressed: () => _completeSearch(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),    
      );    
  }

  /// Complete the search conveyer and show user to results
  void _completeSearch() async {
    if (_hasInputChanged) {
      // user database
      //final CollectionReference users = Firestore.instance.collection("users");
      // feed our finalCriteria map with user selections
      _feedFinalCriteria();

      // translate location input to coordinates
      String currCoordinates = "";
      if (locationEditingController.text.length == 0) {
        showAlertDialog(["Okay"], "Empty location input", "Input location cannot be empty");
        return;
      }
      if (!locationEditingController.text.startsWith("Lat:"))
        currCoordinates = await _addressToCoordinates(finalCriteria['Location']);
      else currCoordinates = finalCriteria['Location'];

      ResultsState.currCoordinates = currCoordinates;
      ResultsState.availability = _availabilityMap;
      _buildQuery();
      // Call database to fetch myusers matching the criteria
      // Navigate to Results tab
      widget.tabController.animateTo(
        (widget.tabController.index + 1) % 2,
        duration: Duration(seconds: 5),
      );  

      setState(() {
        _hasInputChanged = false;
      });
    } 
  }

  void _buildQuery() {
    widget.access.query = Firestore.instance.collection("users").where("type", isEqualTo: "myuser");
    finalCriteria.forEach((k, v) {
      if (v != null) {
        switch(k) {
          case 'Specialization':
            widget.access.query = widget.access.query.where('specializations', arrayContains: finalCriteria['Specialization']);
            break;
          case 'Max Charge':
            widget.access.query = widget.access.query.where('typical_hourly_charge', isLessThanOrEqualTo: finalCriteria['Max Charge']);
            break;
        }
      }
    });
  }

  /// Convert an address to coordinates. Useful when we'll want to find distances
  Future<String> _addressToCoordinates(String address) async {
    List<Placemark> placemark = await Geolocator().placemarkFromAddress(address);
    String coordinates = "";
    placemark.forEach((p) {
      coordinates = p.position.latitude.toString() + ", " + p.position.longitude.toString();
    });
    return coordinates;
  }

  /// Gather all user search criteria input into a map
  void _feedFinalCriteria() {
    // get input location value
    if (locationEditingController.text.length != 0) {
      if (locationEditingController.text.startsWith("Lat:")) {
        var buffer = StringBuffer();
        locationEditingController.text.split(",").forEach((s) {
          buffer.write(s.split(":")[1]);
          buffer.write(",");
        });

        String loc = buffer.toString();
        finalCriteria['Location'] = loc.substring(0, loc.length-1);
      }
      else {
        finalCriteria['Location'] = locationEditingController.text;
      }
    } else return;
    

    // get input specialization value
    if (specializationEditingController.text.length != 0) {
      finalCriteria['Specialization'] = specializationEditingController.text;
    }
    // get Max Charge slider value
    finalCriteria['Max Charge'] = _chargeSliderVal;
    // get distance slider value
    finalCriteria['Distance'] = _distSliderVal;
    // get Availability Map
    if (_availabilityMap.isNotEmpty)
      finalCriteria['Availability'] = _availabilityMap;
  }

  // alert dialog to show if location services aren't available
  // TODO: Abstract this to use as a template
  void showAlertDialog(List<String> actions, String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: new Text(title),
          content: new Text(content),
          actions: <Widget>[
            new FlatButton(
              onPressed: () => Navigator.of(context).pop(),
              child: new Text(actions[0]),
            ),
            // new FlatButton(
            //   onPressed: actions[1] != "Accept" ? null : () {
            //     _openLocationSettings();
            //     Navigator.of(context).pop();
            //   },
            //   child: new Text(actions[1]),
            // ) ,
          ],
        );
      },
    );
  }

  /// open location settings on device 
  /// TODO: Implement an iOS version
  // void _openLocationSettings() async {
  //   final AndroidIntent intent = new AndroidIntent(
  //       action: 'android.settings.LOCATION_SOURCE_SETTINGS',
  //   );
  //   await intent.launch();
  // }

  /// Dispose controllers
  @override
  void dispose() {
    locationEditingController.dispose();
    specializationEditingController.dispose();
    super.dispose();
  }

  /// For neat separation between criteria options
  Container separator(double size) {
    return new Container(margin: EdgeInsets.only(bottom: size),);
  }

  /// Ensures persistence while switching between tabs or pages
  @override
  bool get wantKeepAlive => true;
}

//518-000-916-7427