import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:connectivity/connectivity.dart';
import 'package:myusica/root.dart';
import 'package:myusica/routes.dart';
import 'package:myusica/helpers/auth.dart';
import 'package:myusica/helpers/dialogs.dart';
import 'package:dart_ping/dart_ping.dart';

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
  bool isConnected = true;
  startTime() async {
    var _duration = new Duration(seconds: 1);
    return new Timer(_duration, navigationPage);
  }

  void navigationPage() {
    // we don't want to come back to Welcome screen if user hits "BACK" so we use pushReplacement
    // instead of push
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(
        builder: (context) => RootPage(auth: new Auth())
      ),
    );
  }

  @override
  void initState() {
    // Connectivity().checkConnectivity().then((val) {
    //   print("connectivitiy is " + val.toString());
    // });
    _checkForInternetConnectivity();
    super.initState();
  }

  _checkForInternetConnectivity() async {
    try {
      final result = await InternetAddress.lookup("google.com");
      // print("result is " + result.toString());
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print("Connected to the internet!");
        setState(() {
         isConnected = true;
         startTime(); 
        });
      }
    } on SocketException catch(_) {
      showAlertDialog(context, ["Okay"], "No network connection", "Please check your internet connectivity");
      setState(() {
       isConnected = false; 
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: isConnected ? new Center(
        child: new Image.asset('images/Myusica logo.png'),
      ) : 
        Center(
        // margin: const EdgeInsets.fromLTRB(50.0, 90.0, 20.0, 0.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              new Image.asset('images/Myusica logo.png'),
              ButtonTheme(
                buttonColor: Colors.lightBlue,
                child: RaisedButton(
                  child: Text("LAUNCH", style: TextStyle(fontSize: 18.0),),
                  onPressed: () => _checkForInternetConnectivity(),
                ),
              ),
            ],
          ),
      ),
    );
  }
}

//keytool -list -v -keystore "C:\Users\Levi\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android