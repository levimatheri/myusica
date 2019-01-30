import 'package:flutter/material.dart';

/// Myuser registration
class Register extends StatefulWidget {
  RegisterState createState() => new RegisterState();
}

class RegisterState extends State<Register> {
  final _formKey = new GlobalKey<FormState>();

  Widget _showBody() {
    return new Container(
      padding: EdgeInsets.all(16.0),
      child: new Form(
        key: _formKey,
        child: new ListView(
          shrinkWrap: true,
          children: <Widget>[
            
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Register"),
      ),
      body: Stack(
        children: <Widget>[
          _showBody(),
        ],
      ),
    );
  }
}