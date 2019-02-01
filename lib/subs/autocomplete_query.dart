import 'package:flutter/material.dart';
import 'package:autocomplete_textfield/autocomplete_textfield.dart';

class AutocompleteQuery<T> extends StatefulWidget {
  final List<T> dictionary;
  final String title;
  AutocompleteQuery(List<T> dictionary, String title) : dictionary = dictionary, title = title;
  AutocompleteQueryState createState() => AutocompleteQueryState(dictionary, title);
}

class AutocompleteQueryState<T> extends State<AutocompleteQuery> with
AutomaticKeepAliveClientMixin<AutocompleteQuery> {
  List<String> _dictionary;
  String _title;
  String selected;
  String previous = "";
  String currentText = "";
  var isLoading = false;
  final textController = TextEditingController();

  Type typeOf<T>() => T;
  
  AutocompleteQueryState(List<T> dictionary, String title) {
    // convert dictionary to List<String> so we can feed to the suggestions
    _dictionary = List<String>.from(dictionary);
    _title = title;
  } 

  SimpleAutoCompleteTextField specTextField;
  GlobalKey<AutoCompleteTextFieldState<String>> key = new GlobalKey();

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      //resizeToAvoidBottomPadding: false,
      appBar: AppBar(
        title: Text(_title),
      ),
      body: new Container(
        margin: const EdgeInsets.only(top: 30.0),
        child: new Column(
          children: <Widget>[
            new ListTile(
              title: specTextField = SimpleAutoCompleteTextField(
                key: key,
                suggestions: _dictionary,
                decoration: InputDecoration(
                    hintText: "Enter " + _title,
                ),
                textChanged: (text) => currentText = text,
                textSubmitted: (text) => Navigator.pop(context, text)
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}