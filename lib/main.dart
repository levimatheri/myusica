import 'dart:async';

import 'package:flutter/material.dart';
import 'package:myusica/root.dart';
import 'package:myusica/routes.dart';
import 'package:myusica/helpers/auth.dart';

void main() {
  runApp(MaterialApp(
    title: "Myusica",
    theme: new ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.green[800],
      accentColor: Colors.cyan[600],
      fontFamily: 'Roboto',
    ),
    routes: routes,
    home: WelcomeScreen(),
  ));
}

// LOGIN PAGE
class WelcomeScreen extends StatefulWidget {
  _WelcomeScreenState createState() => new _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  startTime() async {
    var _duration = new Duration(seconds: 2);
    return new Timer(_duration, navigationPage);
  }

  void navigationPage() {
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => RootPage(auth: new Auth())
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    startTime();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Center(
        child: new Image.asset('images/Myusica logo.png'),
      ),
    );
  }
}

//keytool -list -v -keystore "C:\Users\Levi\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android