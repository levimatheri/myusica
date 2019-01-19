import 'package:flutter/material.dart';
import 'package:myusica/helpers/myuser.dart';

class MyuserItem extends StatelessWidget {
  final Myuser myuser;
  final Function onMyuserClicked;

  MyuserItem({
    @required this.myuser,
    this.onMyuserClicked // TODO: Change this to required and implement function
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.face),
      title: Text(myuser.name),
      subtitle: Text(myuser.city + ", " + myuser.state),
    );
  }
}