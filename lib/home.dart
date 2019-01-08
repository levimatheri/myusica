import 'package:flutter/material.dart';
import 'package:myusica/subs/location_query.dart';
import 'package:myusica/subs/specialization_query.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:android_intent/android_intent.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myusica/subs/availability_query.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController (
      length: 2,
      child: Scaffold (
        appBar: AppBar(
          bottom: TabBar(
              tabs: [
                Tab(icon: Icon(Icons.list)), // List of matching Myusers
                Tab(icon: Icon(Icons.search)), // Search criteria page
              ],
          ),
          title: Text("Home"),
        ),
        body: TabBarView(
            children: [
              Center( child: Text("Page 1") ),
              Container (
                margin: const EdgeInsets.only(top: 30.0, left: 20.0, right: 20.0),
                child: Column(
                  children: <Widget>[
                    Criteria(),
                  ],
                ),
              ),
            ],
        ),
      ),
    );
  }
}

/// ==========RESULTS FROM DATABASE SEARCH================
class Results extends StatefulWidget {
  ResultsState createState() => new ResultsState();
}

class ResultsState extends State<Results> {
  @override
    Widget build(BuildContext context) {
      return new Container(

        child: new StreamBuilder<QuerySnapshot>(
          //stream: Firestore.instance,
        ),
      );
    }
}

/// =============SEARCH CRITERIA=====================
class Criteria extends StatefulWidget {
  CriteriaState createState() => new CriteriaState();
}

class CriteriaState extends State<Criteria> with
AutomaticKeepAliveClientMixin<Criteria> {
  FocusNode _locationFocusNode = new FocusNode();
  FocusNode _specFocusNode = new FocusNode();

  final locationEditingController = new TextEditingController();
  final specializationEditingController = new TextEditingController();

  double _sliderVal = 5.0;

  Position _position;
  var _positionIsLoading = false;

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
          _specFocusNode, SpecializationQuery(), specializationEditingController
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
  Future getResult(dynamic destination, TextEditingController controller) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => destination,
      ),
    ).then((result) {
      if (result != null) {
        controller.text = "$result";
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
    return _positionIsLoading ? CircularProgressIndicator() :
      new Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Text(
              "Location",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            new TextField(
              decoration: InputDecoration(
                  hintText: "Input location"
              ),
              focusNode: _locationFocusNode,
              controller: locationEditingController,
            ),
            separator(20.0),
            new RaisedButton(
              child: Text("Use current location"),
              onPressed: _positionIsLoading ? null : () {
                Geolocator().checkGeolocationPermissionStatus()
                    .then((permStatus) async {
                  if (permStatus == GeolocationStatus.denied) {
                    _showAlertDialog(
                      ["Close", ""],
                      "Location access denied",
                      "Allow access for this app using device settings");
                  }
                  if (permStatus == GeolocationStatus.disabled) {
                   // _openLocationSettings();
                    _showAlertDialog(
                        ["Okay", ""],
                        "Location services disabled",
                        "Turn on location then try again");
                  }
                  if (permStatus == GeolocationStatus.granted) {
                    await _initPlatformState();
                    locationEditingController.text = _position.toString();
                  }
                  if (permStatus == GeolocationStatus.unknown) {
                    _showAlertDialog(
                        ["Close", ""],
                        "Unknown error",
                        "Please contact developer");
                  }
                });
              }
            ),
            separator(30.0),
            new Text(
              "Specialization",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            new TextField(
              decoration: InputDecoration(
                  hintText: "Input specialization"
              ),
              focusNode: _specFocusNode,
              controller: specializationEditingController,
            ),
            separator(50.0),
            new Text(
              "Charge",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            new Slider(
              activeColor: Colors.indigoAccent,
              value: _sliderVal,
              min: 0.0,
              max: 100.0,
              divisions: 20,
              onChanged: (double newCharge) {
                setState(() => _sliderVal = newCharge);
              },
            ),
            separator(20.0),
            // TODO: Change me to a range slider or max
            new Container(
              alignment: Alignment.center,
              child: Text("\$${_sliderVal.toInt()}/hour"),
            ),
            separator(20.0),
            new RaisedButton(
              child: Text('Availability'),
              onPressed: () => Navigator.push(context, 
                MaterialPageRoute(builder: (context) => AvailabilityQuery())).then((result) {
                  if (result != null) {
                    print("$result['Sunday']");
                  }
                }),
            ),
          ],
        ),
      );
  }

  // alert dialog to show if location services aren't available
  void _showAlertDialog(List<String> actions, String title, String content) {
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
            new FlatButton(
              onPressed: actions[1] != "Accept" ? null : () {
                _openLocationSettings();
                Navigator.of(context).pop();
              },
              child: new Text(actions[1]),
            ) ,
          ],
        );
      },
    );
  }

  /// open location settings on device 
  /// TODO: Implement an iOS version
  void _openLocationSettings() async {
    final AndroidIntent intent = new AndroidIntent(
        action: 'android.settings.LOCATION_SOURCE_SETTINGS',
    );
    await intent.launch();
  }

  @override
  void dispose() {
    locationEditingController.dispose();
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