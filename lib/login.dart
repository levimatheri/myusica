import 'package:flutter/material.dart';
import 'package:myusica/helpers/auth.dart';
import 'package:flutter/services.dart';
import 'package:myusica/helpers/dialogs.dart';

class LoginPage extends StatefulWidget {
  LoginPage({this.auth, this.onSignedIn});

  final BaseAuth auth;
  final VoidCallback onSignedIn;
  
  @override
  LoginPageState createState() => new LoginPageState();
}

enum FormMode { LOGIN, SIGNUP }

class LoginPageState extends State<LoginPage> {
  final _formKey = new GlobalKey<FormState>();

  FormMode _formMode = FormMode.LOGIN; // initialize as login
  bool _isLoading;

  bool _isIos;

  String _username;
  String _email;
  String _password;
  String _errorMessage;

  // check if form is valid before logging in or signing up
  bool _validateAndSave() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  _validateAndSubmit() async {
    setState(() {
      _errorMessage = "";
      _isLoading = true;    
    });

    if (_validateAndSave()) {
      String userId = "";
      try {
        if (_formMode == FormMode.LOGIN) {
          userId = await widget.auth.signIn(_email, _password);
          print('Signed in user: $userId');
        } else {
          userId = await widget.auth.signUp(_username, _email, _password);
          print('Signed up user: $userId');
        }

        setState(() {
          _isLoading = false;        
        });

        if (userId != null) widget.onSignedIn();
      } on PlatformException catch (e) {
        print('Error: $e');
        setState(() {
          _isLoading = false;
          if (_isIos) _errorMessage = e.details;
          else _errorMessage = e.message;
        });
      }
    }
  }

  @override
  void initState() {
    _errorMessage = "";
    _isLoading = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _isIos = Theme.of(context).platform == TargetPlatform.iOS;
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Log in"),
        automaticallyImplyLeading: false, // removes back button so that user can only use log out
      ),
      body: Stack(
        children: <Widget>[
          _showBody(),
          _showCircularProgress(),
        ],
      ),
    );
  }

  Widget _showCircularProgress() {
    if (_isLoading) return Center(child: CircularProgressIndicator(),);
    return Container(height: 0.0, width: 0.0);
  }

  Widget _showLogo() {
    return new Hero(
      tag: 'hero',
      child: Padding(
        padding: _formMode == FormMode.LOGIN ? EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0) 
                                : EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
        child: CircleAvatar(
          backgroundColor: Colors.transparent,
          radius: 70.0,
          child: Image.asset('images/Myusica logo.png'),
        ),
      ),
    );
  }

  Widget _showUsernameInput() {
    return _formMode == FormMode.SIGNUP ? Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 2.0, 0.0, 10.0),
      child: new TextFormField(
        maxLines: 1,
        keyboardType: TextInputType.emailAddress,
        autofocus: false,
        decoration: new InputDecoration(
          hintText: 'Username',
          icon: new Icon(
            Icons.person,
            color: Colors.blue[200],
          ),
        ),
        validator: (value) => value.isEmpty ? 'Username cannot be empty' : null,
        onSaved: (value) => _username = value,
      ),
    ) : Container();
  }

  Widget _showEmailInput() {
    return Padding(
      padding: _formMode == FormMode.LOGIN ? EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 20.0) 
                                    : EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 10.0),
      child: new TextFormField(
        maxLines: 1,
        keyboardType: TextInputType.emailAddress,
        autofocus: false,
        decoration: new InputDecoration(
          hintText: 'Email',
          icon: new Icon(
            Icons.mail,
            color: Colors.blue[200],
          ),
        ),
        validator: (value) => value.isEmpty ? 'Email cannot be empty' : null,
        onSaved: (value) => _email = value,
      ),
    );
  }

  Widget _showPasswordInput() {
    return Padding(
      padding: _formMode == FormMode.LOGIN ? EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 20.0) 
                                  : EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 10.0),
      child: new TextFormField(
        maxLines: 1,
        obscureText: true,
        autofocus: false,
        decoration: new InputDecoration(
          hintText: 'Password',
          icon: new Icon(
            Icons.lock,
            color: Colors.blue[200],
          ),
        ),
        validator: (value) => value.isEmpty ? 'Password cannot be empty' : null,
        onSaved: (value) => _password = value,
      ),
    );
  }

  Widget _showConfirmPasswordInput() {
    return _formMode == FormMode.SIGNUP ? Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: new TextFormField(
        maxLines: 1,
        obscureText: true,
        autofocus: false,
        decoration: new InputDecoration(
          hintText: 'Confirm password',
          icon: new Icon(
            Icons.lock,
            color: Colors.blue[200],
          ),
        ),
        validator: (value) {
          if (value.isEmpty) 
          {
            showAlertDialog(context, ["Okay"], "Error", "Please confirm password");
            return;
          }
          else {
            if (value != _password) 
            {
              showAlertDialog(context, ["Okay"], "Error", "Passwords do not match");
              return;
            }
          }
        }
      ),
    ) : Container();
  }

  Widget _showPrimaryButton() {
    return new Padding(
      padding: EdgeInsets.fromLTRB(0.0, 45.0, 0.0, 0.0),
      child: new MaterialButton(
        elevation: 5.0,
        minWidth: 200.0,
        height: 42.0,
        color: Colors.orange,
        child: _formMode == FormMode.LOGIN
              ? new Text('Login',
                    style: new TextStyle(fontSize: 20.0, color: Colors.white))
              : new Text('Create account',
                    style: new TextStyle(fontSize: 20.0, color: Colors.white)),
        onPressed: _validateAndSubmit,
      ),
    );
  }

  Widget _showSecondaryButton() {
    return new FlatButton(
      child: _formMode == FormMode.LOGIN
              ? new Text('Create an account',
                style: new TextStyle(fontSize: 16.0, 
                fontWeight: FontWeight.w300))
              : new Text('Have an account? Sign in',
                style: new TextStyle(fontSize: 18.0, 
                fontWeight: FontWeight.w300)),
      onPressed: _formMode == FormMode.LOGIN
                  ? _changeFormToSignUp
                  : _changeFormToLogin,
    );
  }

  void _changeFormToSignUp() {
    _formKey.currentState.reset();
    _errorMessage = "";
    print("Changing to sign up");
    setState(() {
      _formMode = FormMode.SIGNUP;
    });
  }

  void _changeFormToLogin() {
    _formKey.currentState.reset();
    _errorMessage = "";
    print("Changing to login");
    setState(() {
      _formMode = FormMode.LOGIN;
    });
  }

  Widget _showErrorMessage() {
    if (_errorMessage != null) {
      return new Text(
        _errorMessage,
        style: TextStyle(
          fontSize: 13.0,
          color: Colors.red,
          height: 1.0,
          fontWeight: FontWeight.w300
        ),
      );
    } else {
      return new Container(height: 0.0,);
    }
  }

  Widget _showBody() {
    return new Container(
      padding: EdgeInsets.all(16.0),
      child: new Form(
        key: _formKey,
        child: new ListView(
          shrinkWrap: true,
          children: <Widget>[
            _showLogo(),
            _showUsernameInput(),
            _showEmailInput(),
            _showPasswordInput(),
            _showConfirmPasswordInput(),
            _showPrimaryButton(),
            _showSecondaryButton(),
            _showErrorMessage(),
          ],
        ),
      ),
    );
  }
}