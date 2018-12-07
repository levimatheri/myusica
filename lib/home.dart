import 'package:flutter/material.dart';
import 'package:myusica/subs/location_query.dart';

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
  FocusNode _focusNode = new FocusNode();
  final locationEditingController = new TextEditingController();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() async {
    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
      return;
    }

    // return a Future that will complete after
    // Navigator.pop on location_query screen
    final result = Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationQuery(),
      ),
    );

    // set location text field to the result from location query
    locationEditingController.text = result.toString();
  }

    //fill location text box

  @override
  Widget build(BuildContext context) {
    return new Container(
      child: new TextField(
        decoration: InputDecoration(
          hintText: "Location"
        ),
        focusNode: _focusNode,
        controller: locationEditingController,
      ),
    );
  }

  @override
  void dispose() {
    locationEditingController.dispose();
    super.dispose();
  }
}