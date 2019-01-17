import 'dart:async';

import 'package:flutter/material.dart';
import 'package:myusica/home.dart';

void main() {
  runApp(MaterialApp(
    title: "Myusica",
    theme: new ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.green[800],
      accentColor: Colors.cyan[600],
      fontFamily: 'Montserrat',
    ),
    routes: <String, WidgetBuilder>{
      '/home': (BuildContext context) => HomePage()
    },
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
    Navigator.of(context).pushReplacementNamed('/home');
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