import 'package:flutter/material.dart';
import 'package:myusica/home.dart';
import 'package:myusica/subs/location_query.dart';

void main() {
  runApp(MaterialApp(
    title: "Myusica",
    home: LoginPage(),
  ));
}

// LOGIN PAGE
class LoginPage extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Scaffold (
      appBar: AppBar(
        title: Text("First screen"),
      ),
      body: Center (
        child: RaisedButton(
            child: Text('Launch home'),
            onPressed: () {
              // Send user to home page if successful login
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
              );
            },
        ),
      ),
    );
  }
}