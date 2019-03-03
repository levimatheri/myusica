import 'package:flutter/material.dart';
import 'package:myusica/helpers/auth.dart';
import 'package:myusica/helpers/user.dart';
import 'package:myusica/subs/chat.dart';
import 'package:myusica/helpers/myuser_picture.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatMain extends StatefulWidget {
  final List<Map<String, dynamic>> chats;
  final BaseAuth auth;
  final String id;
  ChatMain({this.chats, this.auth, this.id});
  ChatMainState createState() => ChatMainState();
}

class ChatMainState extends State<ChatMain> {
  List<String> peerPicUrlList;
  List<String> peerNames;
  List<String> peerIds;
  List<bool> messageSeen;
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
    peerIds = List<String>(widget.chats.length);
    messageSeen = List<bool>(widget.chats.length);

    isLoading = false;

    // print(widget.chats.length);

    if (widget.chats.length > 0) _initChatList();
  }

  // grab all chat ids
  _initChatList() async {
    isLoading = true;
    Map<String, dynamic> map;
    for (var j = 0; j < widget.chats.length; j++) {
      if (widget.chats[j] != null) {
        setState(() {
          peerIds[j] = widget.chats[j]['peerId'];
        });    
        // get peer object
        map = await widget.auth.getUser(peerIds[j]);
        User user = User.fromMap(map, peerIds[j]);
        setState(() {
          peerNames[j] = user.name;
        });

        setState(() {
          messageSeen[j] = widget.chats[j]['seen'];
        });
        
        if (user.picture != null && user.picture.length != 0) {
          dynamic picUrlResult = await getUserProfilePicture(user);
          if (picUrlResult != null) {
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

  _navigateToChat(String pa, String pid, String id, bool seen, int listItemNo) {
    Navigator.push(
      context, 
      MaterialPageRoute(settings: RouteSettings(), 
        builder: (context) => Chat(auth: widget.auth, peerAvatar: pa, peerId: pid, id: id, seen: seen, itemNo: listItemNo, chatObj: widget.chats)
      )
    );
  }

  _buildChatList() {
    return Container(
      margin: EdgeInsets.only(top: 30.0, left: 5.0, right: 5.0),
      child: widget.chats.length > 0 ? ListView.builder(
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
            contentPadding: EdgeInsets.symmetric(vertical: 15.0),
            trailing: messageSeen != null ? (messageSeen[index] ? null : Icon(Icons.notifications_active)) : null,
            onTap: () => _navigateToChat(peerPicUrlList[index], peerIds[index], widget.id, messageSeen[index], index),
          );
        },
        itemCount: widget.chats.length,
      ) : Center(child: Text("No chats found"),),
    );  
  }
}