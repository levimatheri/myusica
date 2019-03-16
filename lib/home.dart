import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:myusica/root.dart';

import 'package:myusica/subs/register.dart';
import 'package:myusica/subs/my_account.dart';
import 'package:myusica/subs/chat_main.dart';
import 'package:myusica/subs/criteria.dart';
import 'package:myusica/subs/results.dart';
import 'package:myusica/helpers/access.dart';
import 'package:myusica/helpers/auth.dart';
import 'package:myusica/helpers/user.dart';

class HomePage extends StatefulWidget {
  final BaseAuth auth;
  // final VoidCallback onSignedOut;
  final String userId;
  final String username;
  final bool isMyuser;
  final List<Map<String, dynamic>> chats;
  HomePage({Key key, this.auth, this.userId, this.username, this.isMyuser, this.chats}) : super(key: key);

  @override
  HomePageState createState() => new HomePageState();
}
class HomePageState extends State<HomePage> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final GlobalKey<FormState> formKey = new GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  // final List<Tab> homeTabs = <Tab>[
  //   Tab(text: 'Results', icon: Icon(Icons.list)), // List of matching Myusers
  //   Tab(text: 'Search', icon: Icon(Icons.search)), // Search criteria page
  // ];
  // TabController _tabController;
  Access access = new Access();
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  bool newChatMessage = false;
  String currToken;
  bool _isLoading = false;
  List<String> globalPushTokens;
  // HomePageState(List<Map<String, dynamic>> chats) {
    
  // }

  @override
  void initState() {
    super.initState();
    // _tabController = new TabController(vsync: this, length: homeTabs.length);
    for (int i = 0; i < widget.chats.length; i++) {
      if (!widget.chats[i]['seen']) {
        newChatMessage = true; 
        break;
      }
    }
    _initCloudMessaging();
  }

  @override
  void dispose() {
    // _tabController.dispose();
    super.dispose();
  }

  _initCloudMessaging() async {
    setState(() {
     _isLoading = true; 
    });
    if (Platform.isIOS) _iOSPermission();

    _firebaseMessaging.getToken().then((token) {
      currToken = token;
      print("token is $currToken");
    });

    await _updateToken();

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        setState(() {
         newChatMessage = true; 
        });
        print('on message $message');
      },
      onResume: (Map<String, dynamic> message) async {
        print('on resume $message');
      },
      onLaunch: (Map<String, dynamic> message) async {
        print('on launch $message');
      },
    );
  }

  _updateToken() async {
    List<String> pushTokens = await widget.auth.getPushTokens(widget.userId);
    if (pushTokens == null) {
      // create pushToken object
      List<String> ptObj = [currToken];
      // final Firestore _firestoreRecord = Firestore.instance;
      // await _firestoreRecord
      //   .collection('users')
      //   .document(widget.userId).setData({"pushtokens": ptObj});

      DocumentReference docRef = Firestore.instance
            .collection("users")
            .document(widget.userId);

      Firestore.instance.runTransaction((transaction) async {
        await transaction.update(docRef, {'pushtokens': ptObj});
      });

    } else {
      // go through pushTokens for this user and check if currToken is in the list
      // if not add it in
      if (!pushTokens.contains(currToken)) {
        pushTokens.add(currToken);
        // final Firestore _firestoreRecord = Firestore.instance;
        // await _firestoreRecord
        //   .collection('users')
        //   .document(widget.userId).setData({"pushtokens": pushTokens});

        DocumentReference docRef = Firestore.instance
            .collection("users")
            .document(widget.userId);

        Firestore.instance.runTransaction((transaction) async {
          await transaction.update(docRef, {'pushtokens': pushTokens});
        });
      }
      globalPushTokens = pushTokens;
    }

    // print("gt: " + globalPushTokens.toString());
    setState(() {
     _isLoading = false; 
    });
  }

  void _iOSPermission() {
    _firebaseMessaging.requestNotificationPermissions(
      IosNotificationSettings(sound: true, badge: true, alert: true)
    );
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings)
    {
      print("Settings registered: $settings");
    });
  }

  _signOut() async {
    setState(() {
      access = null;
    });
   
    globalPushTokens.remove(currToken);
    print('gltokens ' + globalPushTokens.toString());

    try {
      DocumentReference docRef = Firestore.instance
            .collection("users")
            .document(widget.userId);

      Firestore.instance.runTransaction((transaction) async {
        await transaction.update(docRef, {'pushtokens':globalPushTokens});
      }).then((_) async {
        await widget.auth.signOut();
          Navigator.push(
          context, 
          MaterialPageRoute(settings: RouteSettings(), 
            builder: (context) => RootPage(auth: widget.auth)
          )
        );
      });      
    } catch (e) {
      print(e);
    }
  }

  // Go to Myuser registration page
  _navigateToRegister() {
    Navigator.push(
      context, 
      MaterialPageRoute(settings: RouteSettings(), 
        builder: (context) => Register(userId: widget.userId, auth: widget.auth, isFromProfile: false,))
    );
  }

  // Go to Profile page
  _navigateToProfile() {
    Navigator.push(
      context, 
      MaterialPageRoute(settings: RouteSettings(), 
        builder: (context) => MyAccount(auth: widget.auth, userId: widget.userId))
    );
  }

  // Go to Chat main page
  _navigateToChatMain() {
    Navigator.push(
      context, 
      MaterialPageRoute(settings: RouteSettings(), 
        builder: (context) => ChatMain(chats: widget.chats, auth: widget.auth, id: widget.userId))
    ).then((result) {
      setState(() {
        if (result != null) {
          print("result length " + result.length.toString());
          if (result.length != 0) {
            setState(() {
              result.forEach((item) {
                widget.chats[item]['seen'] = true;
              });
            });
          } else {
            setState(() {
              newChatMessage = false; 
            });
          }
        }
      });
    });
  }

  _navigateToSearch() {
    Navigator.push(
      context, 
      MaterialPageRoute(settings: RouteSettings(), 
        builder: (context) => Criteria(auth: widget.auth, access: access,))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold (
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.settings),
          onPressed: () => _scaffoldKey.currentState.openDrawer(),
        ),
        actions: <Widget>[
          newChatMessage ? IconButton(
            icon: Icon(Icons.chat),
            onPressed: _navigateToChatMain,
          ) : Container(width: 0.0, height: 0.0,),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: _navigateToSearch,
          )
        ],
        title: Text("Home"),
        automaticallyImplyLeading: false, // removes back button so that user can only use log out
      ),
      // side menu
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Text(
                "Hello " + widget.username + "!", style: TextStyle(fontStyle: FontStyle.italic, fontSize: 20.0)
              ),
              decoration: BoxDecoration(
                color: Colors.green[800],
              ),
            ),
            ListTile(
              title: Text('My account', style: TextStyle(fontSize: 18.0)),
              onTap:  _navigateToProfile,
            ),
            ListTile(
              title: Text('Chats', style: TextStyle(fontSize: 18.0)),
              onTap: _navigateToChatMain,
            ),
            ListTile(
              title: Text('Log out', style: TextStyle(fontSize: 18.0)),
              onTap: _signOut,
            ),
            Divider(),
            // check to see if user is a myuser. If so, don't allow them to register themselves again
            !widget.isMyuser ? ListTile(
              title: Text('Register to be a myuser', style: TextStyle(fontSize: 18.0)),
              onTap: _navigateToRegister,
            ) : Container(height: 0.0, width: 0.0,),
          ],
        ),
      ),
      body: 
        _isLoading ? Center(child:CircularProgressIndicator()) : Container(
          child: Results(access: access, id: widget.userId, auth: widget.auth, chats: widget.chats, fromHome: true,)
        )
    );
  }

  @override
    bool get wantKeepAlive => true;
}
//518-000-916-7427