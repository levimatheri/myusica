import 'package:flutter/material.dart';
import 'package:google_maps_webservice/places.dart';

class LocationQuery extends StatefulWidget {
  _LocationQueryState createState() => _LocationQueryState();
}

class _LocationQueryState extends State<LocationQuery> with
AutomaticKeepAliveClientMixin<LocationQuery> {
  List<DropdownMenuItem<String>> results = [];

  String selected;
  String previous = "";
  String currentText = "";

  var isLoading = false;
  var isGoClicked = false;

  final locationTextController = TextEditingController();
  FocusNode _locationFocusNode = new FocusNode();


  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    locationTextController.dispose();
    super.dispose();
  }


  _fetchData() async {
    results.clear();
    String searchQuery = locationTextController.text;
    // we don't want to send another api request if nothing's changed
    if (searchQuery == previous) return;

    setState(() {
      isLoading = true;
      isGoClicked = true;
    });
    previous = searchQuery;
    final places = new GoogleMapsPlaces(apiKey: 'AIzaSyCvu_XwzNjF33uBV5kS9XHJdpUMnqooFrA');

    PlacesSearchResponse response =
      await places.searchByText(searchQuery);
    results = response.results.map((val) => new DropdownMenuItem(
        child: new Text(
            val.name + "...",
            overflow: TextOverflow.ellipsis,
            style: new TextStyle(fontSize: 12.0)
        ),
        value: val.formattedAddress
    )).toList();

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Text("Location"),
      ),
      body: Column(
        children: <Widget>[
          new Container(
            padding: const EdgeInsets.only(top: 20.0, bottom: 10.0),
            child: new Text(
              "Enter location (upto street name for best results)",
              style: new TextStyle(
                  fontSize: 11.5
              ),
            ),
          ),
          new Container(
            child: Padding(
                padding: const EdgeInsets.only(bottom: 30.0, left: 10.0, right: 10.0),
                child: Row(
                  children: <Widget>[
                    new Container(
                      child: new Flexible (
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "Enter location",
                          ),
                          focusNode: _locationFocusNode,
                          controller: locationTextController,
                        ),
                      ),
                    ),
                    new Container(
                      //margin: const EdgeInsets.only(bottom: 50.0),
                      child: new RaisedButton(
                        child: new Text("Go"),
                        onPressed: _fetchData,
                      ),
                    ),
                  ],
                ),
            ),
          ),
          new Container(
            child: generateOptions(),
          ),
        ],
      ),
    );
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;

  dynamic generateOptions() {
    if (isGoClicked) {
      return isLoading ? new CircularProgressIndicator() :
        new DropdownButton(
            value: selected,
            items: results,
            hint: new Text("Select location"),
            onChanged: (value) {
              selected = value;
              currentText = selected;
              setState(() {
                isGoClicked = false;
              });
              // return user selection to home page
              Navigator.pop(context, selected);
            }
        );
    } else {

    }
  }
}

//  _fetchData() async {
//    setState(() {
//      isLoading = true;
//    });
//    final response =
//        await http.get('https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=637%20Circle%20Hill%20Rd%20SE&inputtype=textquery&fields=formatted_address,name&key=AIzaSyCvu_XwzNjF33uBV5kS9XHJdpUMnqooFrA');
//
//    if (response.statusCode == 200) {
//      //debugPrint(json.decode(response.body)['candidates'][0]['formatted_address'].toString());
//      list = (json.decode(response.body)['candidates'] as List)
//              .map((data) => new Candidates.from(data)).toList();
//    } else throw Exception('Failed to load addresses');
//  }