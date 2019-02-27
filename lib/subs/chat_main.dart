import 'package:flutter/material.dart';
import 'package:myusica/helpers/auth.dart';
import 'package:myusica/helpers/user.dart';
import 'package:myusica/helpers/myuser_picture.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatMain extends StatefulWidget {
  final List<Map<String, dynamic>> chats;
  final BaseAuth auth;
  ChatMain({this.chats, this.auth});
  ChatMainState createState() => ChatMainState();
}

class ChatMainState extends State<ChatMain> {
  List<String> peerPicUrlList;
  List<String> peerNames;
  bool isLoading;
  int i = 0;
  @override
  void initState() {
    super.initState();
    // get all chats from database
    // 1. Grab chatId
    // 2. Get user associated with the peerId in the chatId map
    // 3. Use the peer user object to build the listtile
    // 4. Navigate to search Chat page when user taps on the list tile (supply logged in userId, peer avatar (picture url) & peerId)
    peerPicUrlList = List<String>(widget.chats.length);
    peerNames = List<String>(widget.chats.length);

    isLoading = false;

    print(widget.chats);

    _initChatList();
  }

  // grab all chat ids
  _initChatList() async {
    isLoading = true;
    Map<String, dynamic> map;
    for (var j = 0; j < widget.chats.length; j++) {
      if (widget.chats[j] != null) {
        String peerId = widget.chats[j]['peerId'];
        // get peer object
        map = await widget.auth.getUser(peerId);
        User user = User.fromMap(map, peerId);
        setState(() {
          peerNames[j] = user.name;
        });
        
        if (user.picture != null && user.picture.length != 0) {
          dynamic picUrlResult = await getUserProfilePicture(user);
          if (picUrlResult != null) {
            print(picUrlResult.toString());
            setState(() {
              peerPicUrlList[j] = picUrlResult;
            });
          }
        } else {
          setState(() {
           peerPicUrlList[j] = user.name.substring(0,1); 
          });
        }
      }
    }
    if (map != null) {
      setState(() {
       isLoading = false; 
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chats"),
      ),
      body: isLoading ? Center(child:CircularProgressIndicator()) : _buildChatList(),
    );
  }

  _buildChatList() {
    return Container(
      margin: EdgeInsets.only(top: 30.0),
      child: ListView.builder(
        itemBuilder: (context, index) {
          return ListTile(
            // if url given has length 1, the url doesn't exist
            leading: peerPicUrlList[index].length == 1 ?
              CircleAvatar(
                radius: 30.0,
                child: Text(peerPicUrlList[index]),
              )
              : CircleAvatar(
                radius: 30.0,
                backgroundImage: CachedNetworkImageProvider(peerPicUrlList[index]),
                backgroundColor: Colors.transparent,
              ),
            title: Text(peerNames[index], style: TextStyle(fontSize: 20.0),),
          );
        },
        itemCount: widget.chats.length,
      ),
    );  
  }
}