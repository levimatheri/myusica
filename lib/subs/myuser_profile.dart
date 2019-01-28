import 'package:flutter/material.dart';
import 'package:myusica/helpers/myuser.dart';
import 'package:firebase_storage/firebase_storage.dart';

class MyuserProfile extends StatefulWidget {
  final Myuser myuser;
  MyuserProfile({this.myuser});

  @override
  MyuserProfileState createState() => new MyuserProfileState();  
}

class MyuserProfileState extends State<MyuserProfile> {
  String ppString = "";
  List<String> days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  @override
  void initState() {
    super.initState();
    getProfilePicture(widget.myuser).then((value) {
      setState(() {
        ppString = value.toString();
      });
    });
  }

  // get myuser profile picture url from firebase
  Future<dynamic> getProfilePicture(Myuser myuser) async {
    FirebaseStorage storage = new FirebaseStorage(
      storageBucket: 'gs://myusica-4818e.appspot.com'
    );
    StorageReference imageLink = 
      storage.ref().child('myuser-profile-pictures').child(myuser.picture + ".jpg");
    final imageUrl = await imageLink.getDownloadURL();
   // print(imageUrl.toString());
    return imageUrl;
  }

  // create availability tile item from availability map
  List<TextSpan> _createAvailabilityTile() {
    var keyList = widget.myuser.availability.keys.toList()..sort((a, b) => days.indexOf(a).compareTo(days.indexOf(b)));
    List<TextSpan> textSpanList = new List<TextSpan>();
  
    // create a new line to separate days if this isn't the first item
    keyList.forEach((key) {
      if (keyList.indexOf(key) != 0) {
        textSpanList.add(
          new TextSpan(text: "\n"),
        );
      }

      // add day item
      textSpanList.add(
        new TextSpan(text: key, style: new TextStyle(fontWeight: FontWeight.bold)),
      );

      // if myuser has >1 available times in a day, add them individually else just get the one time option
      if (widget.myuser.availability[key] is List) {
        widget.myuser.availability[key].forEach((Map item) {
          textSpanList.add(new TextSpan(text: item.keys.take(1).toString()));
        });
      } else {
        textSpanList.add(
          new TextSpan(text: widget.myuser.availability[key].keys.take(1).toString())
        );
      }
    });
    return textSpanList;
  }

  @override
  Widget build(BuildContext context) {
    String specs = widget.myuser.specializations.toString();
    return Scaffold(
      appBar: AppBar(title: Text("Myuser profile"),),
      body: Scrollbar(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: 5.0
            ),
            child: Column(
              children: <Widget>[
                SizedBox(
                  // height: 210.0,
                  child: Card(
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(widget.myuser.name,
                              style: TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text(widget.myuser.city + ", " + widget.myuser.state),
                          leading: CircleAvatar(
                            radius: 30.0,
                            backgroundImage: Image.network(ppString).image,
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                        Divider(),
                        ListTile(
                          title: Text(widget.myuser.phone,
                              style: TextStyle(fontWeight: FontWeight.w500)),
                          leading: Icon(
                            Icons.contact_phone,
                            color: Colors.blue[500],
                          ),
                        ),
                        ListTile(
                          title: Text(widget.myuser.email),
                          leading: Icon(
                            Icons.contact_mail,
                            color: Colors.blue[500],
                          ),
                        ),
                        ListTile(
                          title: Text(specs.substring(1, specs.length-1)),
                          leading: Icon(
                            Icons.work,
                            color: Colors.blue[500],
                          ),
                        ),
                        ListTile(
                          title: RichText(
                            text: TextSpan(
                              style: TextStyle(fontSize: 15.0),
                              children: _createAvailabilityTile()
                            ),
                          ),
                          leading: Icon(
                            Icons.access_time,
                            color: Colors.blue[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),  
      ) 
    );
  }
}