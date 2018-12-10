import 'package:flutter/material.dart';
import 'package:autocomplete_textfield/autocomplete_textfield.dart';

class SpecializationQuery extends StatefulWidget {
  _SpecializationQueryState createState() => _SpecializationQueryState();
}

class _SpecializationQueryState extends State<SpecializationQuery> {
  String selected;
  String previous = "";
  String currentText = "";
  var isLoading = false;
  final specTextController = TextEditingController();
  List<String> suggestions = [
    "Pianist",
    "Organist",
    "Guitarist",
    "Violinist",
    "Cellist",
    "Trumpeter",
    "Flautist",
    "Clarinetist"
    "Oboist",
    "Saxophonist",
    "Bassoonist",
    "French Horn",
    "Horn",
    "Tuba",
    "Trombonist",
    "Drummer"
    "Choir",
    "Band"
  ];

  SimpleAutoCompleteTextField specTextField;
  GlobalKey<AutoCompleteTextFieldState<String>> key = new GlobalKey();

  var snackBar;

  @override
  void dispose() {
    specTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //resizeToAvoidBottomPadding: false,
      appBar: AppBar(
        title: Text("Specialization"),
      ),
      body: new Container(
        margin: const EdgeInsets.only(top: 30.0),
        child: new Column(
          children: <Widget>[
            new ListTile(
              title: specTextField = SimpleAutoCompleteTextField(
                key: key,
                suggestions: suggestions,
                decoration: InputDecoration(
                    hintText: "Enter specialization"
                ),
                textChanged: (text) => currentText = text,
                textSubmitted: (text) => setState(() {
                  //added.add(text);
                  //snackBar = SnackBar(content: Text(text + " selected"),);
                  //Scaffold.of(context).showSnackBar(snackBar);
                  Navigator.pop(context, text);
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

}