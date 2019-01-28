import 'package:flutter/material.dart';
import 'package:myusica/helpers/auth.dart';
import 'package:myusica/login.dart';
import 'package:myusica/home.dart';

class RootPage extends StatefulWidget {
  final BaseAuth auth;

  RootPage({this.auth});

  @override
  _RootPageState createState() => new _RootPageState();
}

enum AuthStatus {
  NOT_DETERMINED,
  NOT_LOGGED_IN,
  LOGGED_IN
}

class _RootPageState extends State<RootPage> {
  AuthStatus authStatus = AuthStatus.NOT_DETERMINED;
  String _userId = "";
  String _username = "";

  @override
  void initState() {
    super.initState();
    // determine logged in status
    widget.auth.getCurrentUser().then((user) {
      setState(() {
        if (user != null) 
        {
          _userId = user?.uid;
        }
        // if user id is null, set status to not logged in otherwise set it to logged in
        authStatus = 
          user?.uid == null ? AuthStatus.NOT_LOGGED_IN : AuthStatus.LOGGED_IN;
      });
      
      widget.auth.getUsername(_userId).then((username) {
        setState(() {
          if (username != null) {
            _username = username;
          } 
        });
      });
    });
  }

  // after logging in get current user id and name
  void _onLoggedIn() {
    widget.auth.getCurrentUser().then((user) {
      setState(() {
        if (user != null) 
        {
          _userId = user?.uid;
          widget.auth.getUsername(_userId).then((username) {
            if (username != null) {
              _username = username;
            } 
          });
        }
      });
    });
    setState(() {
      authStatus = AuthStatus.LOGGED_IN;
    });
  }

  // set user id to empty and set status to not logged in
  void _onSignedOut() {
    setState(() {
      authStatus = AuthStatus.NOT_LOGGED_IN;
      _userId = "";    
    });
  }

  Widget _buildWaitingScreen() {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        child: CircularProgressIndicator(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (authStatus) {
      case AuthStatus.NOT_DETERMINED:
        return _buildWaitingScreen();
        break;
      case AuthStatus.NOT_LOGGED_IN:
        return LoginPage(
          auth: widget.auth,
          onSignedIn: _onLoggedIn,
        );
        break;
      case AuthStatus.LOGGED_IN:
        if (_userId != null) {
          return HomePage(
            userId: _userId,
            username: _username,
            auth: widget.auth,
            onSignedOut: _onSignedOut,
          );
        } else return _buildWaitingScreen();
        break;
      default:
        return _buildWaitingScreen();
    }
  }
}