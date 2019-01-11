import 'package:flutter/material.dart';

// alert dialog to show if location services aren't available
  void showAlertDialog(BuildContext context, List<String> actions, String title, String content) {
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