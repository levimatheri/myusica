import 'package:flutter/material.dart';


import 'package:myusica/root.dart';

import 'package:myusica/subs/register.dart';
import 'package:myusica/subs/my_account.dart';
import 'package:myusica/subs/chat_main.dart';
import 'package:myusica/subs/criteria.dart';
import 'package:myusica/subs/results.dart';
import 'package:myusica/helpers/access.dart';
import 'package:myusica/helpers/auth.dart';

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

  @override
  void initState() {
    super.initState();
    // _tabController = new TabController(vsync: this, length: homeTabs.length);
  }

  @override
  void dispose() {
    // _tabController.dispose();
    super.dispose();
  }

  _signOut() async {
    setState(() {
      access = null;
    });
   
    try {
      await widget.auth.signOut();
      // widget.onSignedOut();
      Navigator.push(
        context, 
        MaterialPageRoute(settings: RouteSettings(), 
          builder: (context) => RootPage(auth: widget.auth)
        )
      );
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
    );
  }

  _navigateToSearch() {
    Navigator.push(
      context, 
      MaterialPageRoute(settings: RouteSettings(), 
        builder: (context) => Criteria(access: access,))
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
        Container(
          child: Results(access: access, id: widget.userId, auth: widget.auth, chats: widget.chats)
        )
    );
  }

  @override
    bool get wantKeepAlive => true;
}





//518-000-916-7427