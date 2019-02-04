import 'dart:io';
import 'dart:isolate';
import 'dart:async';

import 'package:flutter/material.dart';
// import 'package:myusica/helpers/isolate.dart';
import 'package:flutter/services.dart';
import 'package:flutter_masked_text/flutter_masked_text.dart';
import 'package:myusica/subs/availability_query.dart';
import 'package:myusica/helpers/countries.dart';
import 'package:myusica/subs/autocomplete_query.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;


/// Myuser registration
class Register extends StatefulWidget {
  final String userId;
  Register({this.userId});
  RegisterState createState() => new RegisterState();
}

class RegisterState extends State<Register> {
  final _formKey = new GlobalKey<FormState>();
  final _scaffoldKey = new GlobalKey<ScaffoldState>();

  String _name;
  String _city;
  String _state;
  String _country;
  String _email;
  String _phone;
  String _charge;
  File _picture;
  File _compressedPic;

  Map<String, List<String>> _availabilityMap = new Map<String, List<String>>();
  List<int> _selectedItemsPositions = new List<int>();
  int _availabilityItemsSelected = 0;

  var _controller = new MoneyMaskedTextController(leftSymbol: 'US\$', 
                            decimalSeparator: '.');

  FocusNode _countryFocusNode = new FocusNode();
  TextEditingController _countryTextController = new TextEditingController();                            

  bool _isLoading;
  bool _isIos;
  bool _isPictureSelected;
  bool _isPictureCompressed;

  String _errorMessage;

  @override
  void initState() {
    super.initState();
    _isLoading = false;
    _isPictureSelected = false;
    _isPictureCompressed = false;

    _countryFocusNode.addListener(() {
      if (_countryFocusNode.hasFocus) {
        _countryFocusNode.unfocus();
        return;
      }
      getResult();
    });
  }

  @override
  void dispose() {
    _countryTextController.dispose();
    super.dispose();
  }

  Future getResult() {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AutocompleteQuery(country_list, "Country"),
      ),
    ).then((result) {
      if (result != null) {
        _countryTextController.text = "$result";
      }
    }); // put result in text field
  }

  Widget _showBody() {
    return new Container(
      padding: EdgeInsets.all(15.0),
      child: new Form(
        key: _formKey,
        child: new ListView(
          shrinkWrap: true,
          children: <Widget>[
            _showNameInput(),
            _showCityInput(),
            _showStateInput(),
            _showCountryInput(),
            _showChargeInput(),
            _showAvailabilityInput(),
            _showPictureInput(),
            _showDoneButton()
          ],
        ),
      ),
    );
  }

  Widget _showNameInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 6.0, 0.0, 10.0),
      child: TextFormField(
        maxLines: 1,
        autofocus: false,
        decoration: InputDecoration(
          hintText: "Name",
          icon: Icon(
            Icons.account_circle,
            color: Colors.blue[200],
          ),
        ),
        validator: (value) => value.isEmpty ? 'Name cannot be emtpy' : null,
        onSaved: (value) => _name = value,
      ),
    );
  }

  Widget _showCityInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 10.0),
      child: TextFormField(
        maxLines: 1,
        autofocus: false,
        decoration: InputDecoration(
          hintText: "City/Town",
          icon: Icon(
            Icons.location_city,
            color: Colors.blue[200],
          ),
        ),
        validator: (value) => value.isEmpty ? 'City/Town cannot be empty' : null,
        onSaved: (value) => _city = value,
      ),
    );
  }

  Widget _showStateInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 10.0),
      child: TextFormField(
        maxLines: 1,
        autofocus: false,
        decoration: InputDecoration(
          hintText: "State",
          icon: Icon(
            Icons.flag,
            color: Colors.blue[200],
          ),
        ),
        validator: (value) => value.isEmpty ? 'State cannot be empty' : null,
        onSaved: (value) => _state = value,
      ),
    );
  }

  Widget _showCountryInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 10.0),
      child: TextFormField(
        focusNode: _countryFocusNode,
        controller: _countryTextController,
        decoration: InputDecoration(
          hintText: "Country",
          icon: Icon(
            Icons.landscape,
            color: Colors.blue[200],
          ),
        ),
        validator: (value) => value.isEmpty ? 'Country cannot be empty' : null,
        onSaved: (value) => _country = value,
      ),
    );
  }

  Widget _showEmailInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 20.0),
      child: TextFormField(
        maxLines: 1,
        keyboardType: TextInputType.emailAddress,
        autofocus: false,
        decoration: InputDecoration(
          hintText: "Email",
          icon: Icon(
            Icons.account_circle,
            color: Colors.blue[200],
          ),
        ),
        validator: (value) => value.isEmpty ? 'Email cannot be empty' : null,
        onSaved: (value) => _email = value,
      ),
    );
  }

  Widget _showPhoneInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 20.0),
      child: TextFormField(
        maxLines: 1,
        autofocus: false,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          hintText: "Phone",
          icon: Icon(
            Icons.account_circle,
            color: Colors.blue[200],
          ),
        ),
        validator: (value) => value.isEmpty ? 'Phone cannot be empty' : null,
        onSaved: (value) => _phone = value,
      ),
    );
  }

  Widget _showChargeInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 10.0),
      child: TextFormField(
        maxLines: 1,
        autofocus: false,
        keyboardType: TextInputType.number,
        controller: _controller,
        decoration: InputDecoration(
          hintText: "Charge per hour",
          icon: Icon(
            Icons.account_circle,
            color: Colors.blue[200],
          ),
        ),
        inputFormatters: [
          WhitelistingTextInputFormatter.digitsOnly,
        ],
        validator: (value) => value.isEmpty ? 'Charge cannot be empty' : null,
        onSaved: (value) => _charge = value,
      ),
    );
  }

  Widget _showAvailabilityInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 10.0),
      child: Row(
        children: [
          ButtonTheme(
            buttonColor: Colors.lightBlue,
            child: new RaisedButton(
              child: Text('Click to select availability'),
              onPressed: () => Navigator.push(context, 
                MaterialPageRoute(settings: RouteSettings(),
                builder: (context) => AvailabilityQuery(_selectedItemsPositions, _availabilityMap))).then((result) {
                  if (result != null) {
                    _availabilityMap = result[0];
                    setState(() {
                      _availabilityItemsSelected = result[1].length;
                      _selectedItemsPositions = result[1];
                    });
                  }
                }),
            ),
          ),
          Text("   " + _availabilityItemsSelected.toString() + " items selected"), // really bad hack!
        ],
      ),
    );
  }

  Widget _showPictureInput() {
     return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 10.0),
      child: Row(
        children: [
          ButtonTheme(
            buttonColor: Colors.lightBlue,
            child: new RaisedButton(
              child: Text('Click to add picture'),
              onPressed: _pictureOptionsDialogBox
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 10.0),
          ),
          // if user hasn't clicked add picture yet, show empty container
          // if picture compressed has been completed, show an avatar with the compressed image,
          // otherwise show a circular progress indicator
          _isPictureSelected ? 
          (_isPictureCompressed ? CircleAvatar(
            backgroundImage: Image.file(_compressedPic).image,
          ) : CircularProgressIndicator()) 
          : Container(height: 0.0, width: 0.0,),
        ],
      ),
    );
  }

  Future<void> _pictureOptionsDialogBox() {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  child: Text('Take a picture'),
                  onTap: () => _pictureFunction(ImageSource.camera),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 20.0, bottom: 20.0),
                ),
                GestureDetector(
                  child: Text('Select from gallery'),
                  onTap: () => _pictureFunction(ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  // Function to execute to either get picture from camera or gallery
  _pictureFunction(ImageSource selectedSource) async {
    _picture = await ImagePicker.pickImage(
      source: selectedSource,
    );

    setState(() {
      _isPictureSelected = true; 
    });
    // close pop-up dialog
    Navigator.of(context).pop();

    // if picture has been selected, set _isPictureSelected and show snackbar for 2 seconds
    if (_picture != null) {
      _isLoading = false;
      // Compress image
      File compressedImage = await _initCompress(_picture);
      if (compressedImage != null)
      {
        print("File compressed successfully! " + compressedImage.path);
        final snackBar = SnackBar(content: Text('Picture added'), duration: Duration(seconds: 2),);
        _scaffoldKey.currentState.showSnackBar(snackBar);

        setState(() {
          _isPictureCompressed = true;
          // since _compressedPic is in the Widget.build context, set its state here
          _compressedPic = compressedImage;
        });
      }
    }
  }

  Widget _showDoneButton() {
    return new Padding(
      padding: EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 10.0),
      child: new MaterialButton(
        elevation: 5.0,
        minWidth: 200.0,
        height: 42.0,
        color: Colors.orange,
        child: Text('Done',
                    style: new TextStyle(fontSize: 20.0, color: Colors.white)),
        onPressed: _validateAndSubmit,
      ),
    );
  }

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
      try {
        // Implement transaction to Firebase
        // First upload *COMPRESSED* picture to firebase
        if (_picture != null) {
          
        }
        
        // Create new document for user collection
        
      } on PlatformException catch (e) {
        print('Error: $e');
        setState(() {
          _isLoading = false;
          if (_isIos) _errorMessage = e.details;
          else _errorMessage = e.message;
        });
      }
    }
    setState(() {
      _isLoading = false;        
    });
  }

  // Run a firebase storage upload transaction
  _uploadNewPicture() {
    
  }

  // create *pipe* to connect main thread and the new isolate being spawned
  /// Takes in [picture] as parameter to ensure changes to [_picture] are maintained
  Future<dynamic> _initCompress(File picture) async {
    final response = new ReceivePort();
    await Isolate.spawn(isolate, response.sendPort);
    final sendPort = await response.first as SendPort;
    final answer = new ReceivePort();
    sendPort.send([widget.userId, _picture.path, answer.sendPort, picture]);
    return answer.first;
  }

  // The heavy lifting part of compressing Image
  static Future<File> compressImage(String userId, String path, File picture) async {
    String newPath = path.substring(0, path.lastIndexOf("/")+1);

    try {
      print(picture == null);
      img.Image image = img.decodeImage(picture.readAsBytesSync());
      // Resize image to 120x? thumbnail
      img.Image thumbnail = img.copyResize(image, 120);

      return File(newPath + userId + "-profile.png").writeAsBytes(img.encodePng(thumbnail));
    } catch (e) { print(e); return null; }
  }

  // isolate entry that will go off to compress image. This avoids freezing the UI on the main thread
  static void isolate(SendPort initialReplyTo) {
    final port = new ReceivePort();
    initialReplyTo.send(port.sendPort);
    port.listen((message) async {
      final userId = message[0] as String;
      final picturePath = message[1] as dynamic;
      final send = message[2] as SendPort;
      final pic = message[3] as File;
      send.send(await compressImage(userId, picturePath, pic));
    });
  }

  Widget _showCircularProgress() {
    return _isLoading ? CircularProgressIndicator() 
               : Container(height: 0.0, width: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    _isIos = Theme.of(context).platform == TargetPlatform.iOS;
    return new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: new Text("Register"),
      ),
      body: Stack(
        children: <Widget>[
          _showBody(),
          _showCircularProgress()
        ],
      ),
    );
  }
}