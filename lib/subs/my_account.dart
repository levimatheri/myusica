import 'package:flutter/material.dart';
import 'package:myusica/helpers/auth.dart';
import 'package:myusica/subs/myuser_profile.dart';
import 'package:myusica/helpers/myuser.dart';
import 'package:myusica/helpers/myuser_picture.dart';

class MyAccount extends StatefulWidget {
  final BaseAuth auth;
  final String userId;
  MyAccount({@required this.auth, @required this.userId});
  MyAccountState createState() => MyAccountState();
}

class MyAccountState extends State<MyAccount> {
  bool isMyuser = false;
  Myuser thisMyuser;
  String myuserPicUrl;
  bool isLoading = false;
  @override
  void initState() {
    super.initState();
    // check if current user is a myuser
    widget.auth.isMyuser(widget.userId).then((result) {
      if (result != null) {
        setState(() {
        isMyuser = result; 
        isLoading = true;
        });
        if (result) {
          // if this user is a Myuser, get the myuser object and their profile picture
          widget.auth.getUser(widget.userId).then((result) {
            if (result != null) {
              setState(() {
                  thisMyuser = Myuser.fromMap(result, widget.userId);
              });
              if (thisMyuser != null) {
                getProfilePicture(thisMyuser).then((url) {
                  setState(() {
                  myuserPicUrl = url; 
                  isLoading = false;
                  });
                });
              }
            }
          });
        }
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return !isMyuser ? Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
      ),
      body: Center(child: Text("Nothing to show", style: TextStyle(fontSize: 17.0),)),
    ) : isLoading ? Center(child: CircularProgressIndicator()) 
                  : MyuserProfile(auth: widget.auth, myuser: thisMyuser, imageUrl: myuserPicUrl, isFromMyAccount: true,);
  }
}