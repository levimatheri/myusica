import 'package:flutter/material.dart';

import 'package:myusica/helpers/auth.dart';
import 'package:myusica/login.dart';
import 'package:myusica/home.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  bool _isMyuser = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> _chats = List<Map<String, dynamic>>();
  @override
  void initState() {
    super.initState();
    // determine logged in status
    // initialize stuff 
     _initPlatform();   
  }

  _initPlatform() async {
    FirebaseUser user = await widget.auth.getCurrentUser();
    // print('user ' + user.toString());
    setState(() {
      if (user != null) 
      {
        _userId = user?.uid;
      }     
      else {
        setState(() {
         authStatus = AuthStatus.NOT_LOGGED_IN; 
        });
      }
      authStatus = 
          user?.uid == null ? AuthStatus.NOT_LOGGED_IN : AuthStatus.LOGGED_IN;
    });
    print(_userId);
    if (user?.uid != null) {
      await initStuff();
    }
  }

  initStuff() async {
    setState(() {
     _isLoading = true; 
    });
    String username = await widget.auth.getUsername(_userId);  
    setState(() {
      if (username != null) {
        _username = username;
      } 
    });

    bool isMyuser = await widget.auth.isMyuser(_userId);
    setState(() {
      if (isMyuser != null) {
        _isMyuser = isMyuser;
      } 
    });

    List<dynamic> chats = await widget.auth.getChats(_userId);
    setState(() {
      if (chats != null) {
        chats.forEach((item) {
          Map<String, dynamic> map = Map<String, dynamic>.from(item);
          _chats.add(map);
        });
      }
      setState(() {
        _isLoading = false;
      });
    });
  }

  // after logging in get current user id and name and chats
  void _onLoggedIn() {
    widget.auth.getCurrentUser().then((user) async {
      if (user != null) 
      {
        _userId = user?.uid;
        await initStuff();
      }
    });
    
    setState(() {
      authStatus = AuthStatus.LOGGED_IN;
    });
  }

  // set user id to empty and set status to not logged in
  // void _onSignedOut() {
  //   setState(() {
  //     authStatus = AuthStatus.NOT_LOGGED_IN;
  //     _userId = "";    
  //   });
  // }

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
          return _isLoading ? _buildWaitingScreen() : HomePage(
            userId: _userId,
            username: _username,
            auth: widget.auth,
            isMyuser: _isMyuser,
            chats: _chats,
            // onSignedOut:  _onSignedOut,
          );
        } else return _buildWaitingScreen();
        break;
      default:
        return _buildWaitingScreen();
    }
  }
}