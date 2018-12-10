import 'package:flutter/material.dart';
import 'package:myusica/subs/location_query.dart';
import 'package:myusica/subs/specialization_query.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController (
      length: 2,
      child: Scaffold (
        appBar: AppBar(
          bottom: TabBar(
              tabs: [
                Tab(icon: Icon(Icons.list)),
                Tab(icon: Icon(Icons.search)),
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
                    TextFieldFocus(),
                  ],
                ),
              ),
            ],
        ),
      ),
    );
  }
}

class TextFieldFocus extends StatefulWidget {
  TextFieldFocusState createState() => new TextFieldFocusState();
}

class TextFieldFocusState extends State<TextFieldFocus> {
  FocusNode _locationFocusNode = new FocusNode();
  FocusNode _specFocusNode = new FocusNode();
  final locationEditingController = new TextEditingController();
  final specializationEditingController = new TextEditingController();

  @override
  void initState() {
    super.initState();
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
    locationEditingController.clear();
    specializationEditingController.clear();
  }

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
      if (result != null) controller.text = "$result";
    }); // put result in text field
  }

  @override
  Widget build(BuildContext context) {
    return new Container(
      child: Column(
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
          new Container(margin: const EdgeInsets.only(bottom: 50.0),),
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
        ],
      ),
    );
  }

  @override
  void dispose() {
    locationEditingController.dispose();
    super.dispose();
  }
}