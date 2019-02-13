import 'dart:io';
import 'dart:isolate';
import 'dart:async';

import 'package:myusica/helpers/dialogs.dart';
import 'package:myusica/helpers/countries.dart';
import 'package:myusica/helpers/states.dart';
import 'package:myusica/helpers/country_codes.dart';
import 'package:myusica/helpers/currency_codes.dart';
import 'package:myusica/subs/availability_query.dart';
import 'package:myusica/subs/specialization_query.dart';
import 'package:myusica/subs/autocomplete_query.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_masked_text/flutter_masked_text.dart';

import 'package:geolocator/geolocator.dart';
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
  double _charge;
  File _picture;
  File _compressedPic;

  List<String> _listOfAttributes = ['type', 'name', 'city', 'state', 'country', 'coordinates', 'email', 
                  'phone', 'typical_hourly_charge', 'specializations', 'availability', 'picture'];

  Map<String, dynamic> _updateMap = new Map<String, dynamic>(); // this will be passed to _updateUser

  Map<String, List<String>> _availabilityMap = new Map<String, List<String>>();
  List<String> _specializationsList = new List<String>();
  List<int> _selectedAvailabilityPos = new List<int>();
  int _availabilityItemsSelected = 0;

  MoneyMaskedTextController _chargeController;

  FocusNode _countryFocusNode = new FocusNode();
  FocusNode _stateFocusNode = new FocusNode();
  TextEditingController _countryTextController = new TextEditingController();   
  TextEditingController _stateTextController = new TextEditingController();                            

  bool _isLoading;
  bool _isIos;
  bool _isPictureSelected;
  bool _isPictureCompressed;
  bool _isUploadDone;

  String _errorMessage;

  RegisterState() {
    _chargeController = new MoneyMaskedTextController(leftSymbol: "", 
                            decimalSeparator: '.');
    // initialize _updateMap
    _listOfAttributes.forEach((item) {
      if (item == 'availability') {
        _updateMap[item] = new Map<String, Map<String, bool>>();
      } else if (item == 'specializations') {
        _updateMap[item] = new List<String>();
      } else if (item == 'type') {
        _updateMap[item] = 'myuser'; // set this user to myuser
      } else if (item == 'typical_hourly_charge') {
        _updateMap[item] = 0.0;
      } else {
        _updateMap[item] = "";
      }
    });
  }

  String _getMask(String country) {
    String countryCode = 
      country_codes_map.keys.firstWhere(
        (k) => country_codes_map[k] == country, orElse: () => ''
      );
    return currency_codes_map[countryCode];
  }

  @override
  void initState() {
    super.initState();

    _isLoading = false;
    _isPictureSelected = false;
    _isPictureCompressed = false;
    _isUploadDone = false;

    _country = 'United States';

    _countryFocusNode.addListener(() {
      if (_countryFocusNode.hasFocus) {
        _countryFocusNode.unfocus();
        return;
      }
      getResult(_countryTextController, country_list, "Country");
    });

    _stateFocusNode.addListener(() {
      if (_stateFocusNode.hasFocus) {
        _stateFocusNode.unfocus();
        return;
      }
      getResult(_stateTextController, states_list, "State");
    });
  }

  @override
  void dispose() {
    _countryTextController.dispose();
    _stateTextController.dispose();
    super.dispose();
  }

  Future getResult(TextEditingController textController, List<String> listRender, String title) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AutocompleteQuery(listRender, title),
      ),
    ).then((result) {
      if (result != null) {
        textController.text = "$result";
        if (textController == _countryTextController) {
          // if state has been inputted, we check to see if country is US
          // if not, show alert dialog
          if (_state != null && _state.length != 0) {
            if (result != 'United States') {
              showAlertDialog(context, ["Okay"], "Error!", "$_state state not found in $result");
              _countryTextController.clear();
            }
          } else {
            setState(() {
              _country = result; 
              _chargeController = new MoneyMaskedTextController(leftSymbol: _getMask(result), decimalSeparator: ".");
            });
          }
        } else if (textController == _stateTextController) {
          setState(() {
            _state = result; 
          });
        }
      }
    }); // put result in text field
  }

  /// Convert an address to coordinates. Useful when we'll want to find distances
  Future<String> _addressToCoordinates(String address) async {
    List<Placemark> placemark = await Geolocator().placemarkFromAddress(address);
    String coordinates = "";
    placemark.forEach((p) {
      coordinates = p.position.latitude.toString() + ", " + p.position.longitude.toString();
    });
    return coordinates;
  }

  Widget _showBody() {
    return new Container(
      padding: EdgeInsets.all(15.0),
      child: new Form(
        key: _formKey,
        child: new ListView(
          // shrinkWrap: true,
          children: <Widget>[
            _showNameInput(),
            _showEmailInput(),
            _showPhoneInput(),
            _showCityInput(),
            _showCountryInput(),
            _country == 'United States' ? _showStateInput() : Container(height: 0.0, width: 0.0,),
            _showChargeInput(),
            Container(margin: EdgeInsets.only(bottom: 20.0),),
            _showSpecializationInput(),
            Container(margin: EdgeInsets.only(bottom: 10.0),),
            _showAvailabilityInput(),
            Container(margin: EdgeInsets.only(bottom: 10.0),),
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
        validator: (value) => value.isEmpty ? 'Name cannot be empty' : null,
        onSaved: (value) {
          _name = value;
          _updateMap['name'] = value;
        }
      ),
    );
  }

  Widget _showCityInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 10.0),
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
        onSaved: (value) {
          _city = value;
          _updateMap['city'] = value;
        }
      ),
    );
  }

  Widget _showStateInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 10.0),
      child: TextFormField(
        focusNode: _stateFocusNode,
        controller: _stateTextController,
        decoration: InputDecoration(
          hintText: "State (leave empty if outside US)",
          icon: Icon(
            Icons.flag,
            color: Colors.blue[200],
          ),
        ),
        // validator: (value) => value.isEmpty ? 'State cannot be empty' : null,
        onSaved: (value) {
          _state = value;
          _updateMap['state'] = value;
        }
      ),
    );
  }

  Widget _showCountryInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 10.0),
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
        onSaved: (value) {
          _country = value;
          _updateMap['country'] = value;
        }
      ),
    );
  }

  Widget _showEmailInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 10.0),
      child: TextFormField(
        maxLines: 1,
        keyboardType: TextInputType.emailAddress,
        autofocus: false,
        decoration: InputDecoration(
          hintText: "Email",
          icon: Icon(
            Icons.email,
            color: Colors.blue[200],
          ),
        ),
        validator: (value) => value.isEmpty ? 'Email cannot be empty' : null,
        onSaved: (value) {
          _email = value;
          _updateMap['email'] = value;
        }
      ),
    );
  }

  Widget _showPhoneInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 10.0),
      child: TextFormField(
        maxLines: 1,
        autofocus: false,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          hintText: "Phone",
          icon: Icon(
            Icons.phone,
            color: Colors.blue[200],
          ),
        ),
        validator: (value) => value.isEmpty ? 'Phone cannot be empty' : null,
        onSaved: (value) {
          _phone = value;
          _updateMap['phone'] = value;
        }
      ),
    );
  }

  Widget _showChargeInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 10.0),
      child: TextFormField(
        maxLines: 1,
        autofocus: false,
        keyboardType: TextInputType.number,
        controller: _chargeController,
        decoration: InputDecoration(
          // hintText: "Charge per hour",
          icon: Icon(
            Icons.monetization_on,
            color: Colors.blue[200],
          ),
        ),
        inputFormatters: [
          WhitelistingTextInputFormatter.digitsOnly,
        ],
        validator: (value) => value.isEmpty ? 'Charge cannot be empty' : null,
        onSaved: (value) {
          String _regExMatch = new RegExp(r"[a-zA-Z]+").stringMatch(value);
          _charge = double.parse(value.substring(value.indexOf(_regExMatch) + _regExMatch.length, value.length));
          _updateMap['typical_hourly_charge'] = _charge;
        }
      ),
    );
  }

  Widget _showAvailabilityInput() {
    return Column(
      children: <Widget>[
        Container(
          decoration: BoxDecoration( //                    <-- BoxDecoration
            border: Border(top: BorderSide(), bottom: BorderSide()),
            color: Colors.lightBlue
          ),
          child: ListTile(
            title: Text('Select availability'),
            subtitle: Text(_availabilityItemsSelected.toString() + " items selected"),
            onTap: () => Navigator.push(context, 
              MaterialPageRoute(settings: RouteSettings(),
              builder: (context) => AvailabilityQuery(_selectedAvailabilityPos, _availabilityMap))).then((result) {
                if (result != null) {
                  _availabilityMap = result[0];
                  // _updateMap['availability'] = result[0];
                  setState(() {
                    _availabilityItemsSelected = result[1].length;
                    _selectedAvailabilityPos = result[1];
                  });
                }
              }),
          ),
        ),
      ],
    );
  }
  
  Widget _showSpecializationInput() {
    return Column(
      children: <Widget>[
        Container(
          decoration: BoxDecoration( //                    <-- BoxDecoration
            border: Border(top: BorderSide(), bottom: BorderSide()),
            // borderRadius: BorderRadius.circular(0.01),
            color: Colors.lightBlue
          ),
          child: ListTile(
            title: Text('Select specialization(s)'),
            subtitle: Text(_specializationsList.length.toString() + " items selected"),
            onTap: () => Navigator.push(context, 
              MaterialPageRoute(settings: RouteSettings(),
              builder: (context) => SpecializationQuery(
                _specializationsList)
                )).then((result) {
                  if (result != null) {
                    // _updateMap['specializations'] = result[0];
                    _specializationsList = result[0];
                  }
              }),
          ),
        ),
      ],
    );
  }

  // Widget _showPictureInput() {
  //    return Padding(
  //     padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 10.0),
  //     child: Row(
  //       children: [
  //         ButtonTheme(
  //           buttonColor: Colors.lightBlue,
  //           child: new RaisedButton(
  //             child: Text('Add picture'),
  //             onPressed: _pictureOptionsDialogBox
  //           ),
  //         ),
  //         Padding(
  //           padding: EdgeInsets.only(left: 10.0),
  //         ),
  //         // if user hasn't clicked add picture yet, show empty container
  //         // if picture compressed has been completed, show an avatar with the compressed image,
  //         // otherwise show a circular progress indicator
  //         _isPictureSelected ? 
  //         (_isPictureCompressed ? CircleAvatar(
  //           backgroundImage: Image.file(_compressedPic).image,
  //         ) : CircularProgressIndicator()) 
  //         : Container(height: 0.0, width: 0.0,),
  //       ],
  //     ),
  //   );
  // }

  Widget _showPictureInput() {
    return Column(
      children: <Widget>[
        Container(
          decoration: BoxDecoration( //                    <-- BoxDecoration
            border: Border(top: BorderSide(), bottom: BorderSide()),
            // borderRadius: BorderRadius.circular(0.01),
            color: Colors.lightBlue
          ),
          child: ListTile(
            title: Text('Add profile picture'),
            trailing: _isPictureSelected ? 
              (_isPictureCompressed ? CircleAvatar(
                backgroundImage: Image.file(_compressedPic).image,
              ) : CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.green[800]),)) 
              : Container(height: 0.0, width: 0.0,),
            onTap: _pictureOptionsDialogBox
          ),
        ),
      ],
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
      String newPath =_picture.path.substring(0, _picture.path.lastIndexOf("/")+1);
      // if compressed file already exists don't bother
      if (!File(newPath + widget.userId + "-profile-" + _picture.path.substring(_picture.path.lastIndexOf("/")+1, _picture.path.lastIndexOf(".")) + ".png").existsSync()) {
        setState(() {
          _isPictureCompressed = false;
        });
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
      } else {
        setState(() {
          _isPictureCompressed = true;
          // since _compressedPic is in the Widget.build context, set its state here
          _compressedPic = File(newPath + widget.userId + "-profile-" + _picture.path.substring(_picture.path.lastIndexOf("/")+1, _picture.path.lastIndexOf(".")) + ".png");
        });
      }  
      _updateMap['picture'] = widget.userId + "-profile.png";
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
        onPressed: () => _validateAndSubmit(),
      ),
    );
  }

  bool _validateAndSave() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();     
      return true;
    }
    showAlertDialog(context, ["Okay"], "Error!", "One or more inputs is missing");
    return false;
  }

  _validateAndSubmit() async {
    setState(() {
      _errorMessage = "";
      _isLoading = true;    
    });

    if (_validateAndSave()) {
      bool emailValid = RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(_updateMap['email']);
      if (!emailValid) {
        showAlertDialog(context, ["Okay"], "Error!", "Email is invalid");
        setState(() {
          _isLoading = false;        
        });
        return false;
      }
      try {
        // Implement transaction to Firebase
        // First upload *COMPRESSED* picture to firebase
        if (_compressedPic != null) {
          _uploadNewPicture();   
        } else {
          setState(() {
           _isUploadDone = true; 
          });
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
    setState(() {
     _isLoading = true; 
    });
    print("Begin upload picture...");
    StorageReference storageReference = 
      FirebaseStorage.instance.ref()
      .child("myuser-profile-pictures")
      .child(widget.userId + "-profile.png");

    StorageUploadTask uploadTask = storageReference.putFile(_compressedPic);
    uploadTask.onComplete.whenComplete(() {
      setState(() {
       _isUploadDone = true;
       _isLoading = false; 
      });
      print("End upload picture.");
      _updateUser();
    });
  }

  _updateUser() async {
    setState(() {
     _isLoading = true; 
    });
    Map<String, Map<String, bool>> updateAvail = _updateMap['availability'];
    _availabilityMap.forEach((k, v) {
      updateAvail[k] = new Map<String, bool>();
      v.forEach((item) {
        // print(item);
        updateAvail[k].addAll({item.toLowerCase(): true});
      });
    });

    _updateMap['availability'] = updateAvail;   
    _updateMap['specializations'] = _specializationsList; 

    // convert city and country to coordinates
    String address = '';
    if (_state != null && _state.length != 0) {
      address = _city + ", " + _state + ", " + _country;
    } else {
      address = _city + ", " + _country;
    }

    _updateMap['coordinates'] = await _addressToCoordinates(address);
    
    print(_updateMap);
    // Get a reference to the document in question
    DocumentReference docRef = Firestore.instance
            .collection("users")
            .document(widget.userId);
    
    
    // // Run transaction to update user to be a myuser
    // // This assumes validation has passed before
    Firestore.instance.runTransaction((transaction) async {
      await transaction.update(docRef, _updateMap);
      print("Update complete");
      setState(() {
       _isLoading = false; 
      });
      // showAlertDialog(context, ["Okay"], "Success!", "Congratulations! You have been registered as a Myuser");
      Navigator.pop(context);
    });
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
      print(picture.path);
      img.Image image = img.decodeImage(picture.readAsBytesSync());
      // Resize image to 120x? thumbnail
      img.Image thumbnail = img.copyResize(image, 120);

      // this is an asynchronous operation since we want to return the compressed file
      return File(newPath + userId + "-profile-" + picture.path.substring(picture.path.lastIndexOf("/")+1, picture.path.lastIndexOf(".")) + ".png")
        .writeAsBytes(img.encodePng(thumbnail));
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
    return _isLoading ? Center(child: CircularProgressIndicator()) 
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