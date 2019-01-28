import 'package:flutter/material.dart';
import 'package:myusica/helpers/myuser.dart';
import 'package:myusica/subs/myuser_profile.dart';

/// Myuser item to show on the results tab
class MyuserItem extends StatelessWidget {
  final Myuser myuser;
  MyuserItem({
    @required this.myuser
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.face),
      title: Text(myuser.name),
      subtitle: Text(myuser.city + ", " + myuser.state),
      onTap: () { 
        Navigator.push(
          context, 
          MaterialPageRoute(settings: RouteSettings(),
            builder: (context) => MyuserProfile(myuser: myuser,)));}
    );
  }
}