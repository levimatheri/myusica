import 'dart:io';
import 'dart:isolate';
import 'dart:async';

import 'package:myusica/helpers/dialogs.dart';
import 'package:myusica/helpers/countries.dart';
import 'package:myusica/helpers/states.dart';
import 'package:myusica/helpers/country_codes.dart';
import 'package:myusica/helpers/currency_codes.dart';
import 'package:myusica/helpers/myuser.dart';
import 'package:myusica/helpers/pos_to_availability.dart';
import 'package:myusica/helpers/auth.dart';
import 'package:myusica/subs/availability_query.dart';
import 'package:myusica/subs/specialization_query.dart';
import 'package:myusica/subs/autocomplete_query.dart';
import 'package:myusica/home.dart';
import 'package:myusica/root.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_masked_text/flutter_masked_text.dart';

import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';

/// Myuser registration
class Register extends StatefulWidget {
  final String userId;
  final bool isFromProfile;
  final Myuser myuser;
  final String imageUrl;
  final BaseAuth auth;
  Register({@required this.userId, @required this.isFromProfile, this.myuser, this.imageUrl, this.auth});
  RegisterState createState() => new RegisterState(isFromProfile);
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

  Map<String, dynamic> _registerMap = new Map<String, dynamic>(); // this will be passed to _registerUser
  Map<String, dynamic> _updateMap = new Map<String, dynamic>(); // this will be passed to _updateMyuser

 
  List<String> _specializationsList = new List<String>();
  List<int> _selectedAvailabilityPos = new List<int>();

  Map<String, List<String>> _availabilityMap = new Map<String, List<String>>();
  int _availabilityItemsSelected = 0;
  List<int> availChecks = new List<int>();


  MoneyMaskedTextController _chargeController;

  FocusNode _countryFocusNode = new FocusNode();
  FocusNode _stateFocusNode = new FocusNode();
  TextEditingController _nameTextController = new TextEditingController();
  TextEditingController _cityTextController = new TextEditingController();
  TextEditingController _emailTextController = new TextEditingController();
  TextEditingController _phoneTextController = new TextEditingController();
  TextEditingController _countryTextController = new TextEditingController();   
  TextEditingController _stateTextController = new TextEditingController();                            

  bool _isLoading;
  bool _isIos;
  bool _isPictureSelected;
  bool _isPictureCompressed;
  bool _isUploadDone;
  bool _isFromProfile;

  String _errorMessage;

  RegisterState(bool isFromProfile) {
    this._isFromProfile = isFromProfile;
    _chargeController = new MoneyMaskedTextController(leftSymbol: "", 
                            decimalSeparator: '.');
    // initialize _registerMap
    _listOfAttributes.forEach((item) {
      if (item == 'availability') {
        _registerMap[item] = new Map<String, Map<String, bool>>();
      } else if (item == 'specializations') {
        _registerMap[item] = new List<String>();
      } else if (item == 'type') {
        _registerMap[item] = 'myuser'; // set this user to myuser
      } else if (item == 'typical_hourly_charge') {
        _registerMap[item] = 0.0;
      } else {
        _registerMap[item] = "";
      }
    });
  }

  // get the currency mask from a given country
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

    // if user came here from Profile page, pre-fill their details 
    // because they came here to update their profile
    if (widget.isFromProfile) {
      _nameTextController.text = widget.myuser.name;
      _cityTextController.text = widget.myuser.city;
      _phoneTextController.text = widget.myuser.phone;
      _emailTextController.text = widget.myuser.email;
      _stateTextController.text = widget.myuser.state;
      _countryTextController.text = widget.myuser.country;
      _chargeController = new MoneyMaskedTextController(
        leftSymbol: _getMask(widget.myuser.country), decimalSeparator: ".", initialValue: widget.myuser.charge);

      setState(() {
       _specializationsList = List.from(widget.myuser.specializations); 
      });

      availChecks = _getAvailabilityIndicesFromProfile();
      if (availChecks != null) {
        _selectedAvailabilityPos = List.from(availChecks); // CLONE availChecks using List.from()
        setState(() {
         _availabilityItemsSelected =_selectedAvailabilityPos.length; 
        });
      }
    }

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
          // if (_state != null && _state.length != 0) {
          //   if (result != 'United States') {
          //     showAlertDialog(context, ["Okay"], "Error!", "$_state state not found in $result");
          //     _countryTextController.clear();
          //   }
          // } else {
            setState(() {
              _country = result; 
              _chargeController = new MoneyMaskedTextController(leftSymbol: _getMask(result), decimalSeparator: ".");
            });
          // }
        } else if (textController == _stateTextController) {
          setState(() {
            _state = result; 
          });
        }
      }
    }); // put result in text field
  }

  // from the availability items obtained from the myuser's profile, 
  // get the indices that will be used to pre-check the checkboxes in Availability Screen
  List<int> _getAvailabilityIndicesFromProfile() {
    List<int> toReturn = List<int>();
    var keyList = widget.myuser.availability.keys.toList(); // Myuser's available DAYS
    if (keyList.length > 0) {
      // go through each DAY and for each time of day that the myuser is available, 
      // use pos_to_availability map to get the index
      keyList.forEach((key) {
        widget.myuser.availability[key].forEach((k, v) {
          int toAdd = pos_to_avail.keys.firstWhere((posKey) =>  pos_to_avail[posKey] == key + "," + k.toString(), orElse: () => null);
          if (toAdd != null) {
            // print("toadd: $toAdd");
            toReturn.add(toAdd);
          }
        });
      });
      return toReturn;
    }
    return null; 
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
        controller: _nameTextController,
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
          _registerMap['name'] = value;
        }
      ),
    );
  }

  Widget _showCityInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 10.0),
      child: TextFormField(
        controller: _cityTextController,
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
          _registerMap['city'] = value;
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
          _registerMap['state'] = value;
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
          _registerMap['country'] = value;
        }
      ),
    );
  }

  Widget _showEmailInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 10.0),
      child: TextFormField(
        controller: _emailTextController,
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
          _registerMap['email'] = value;
        }
      ),
    );
  }

  Widget _showPhoneInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 10.0),
      child: TextFormField(
        controller: _phoneTextController,
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
          _registerMap['phone'] = value;
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
          _registerMap['typical_hourly_charge'] = _charge;
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
            title: !_isFromProfile ? Text('Select availability') : Text('Modify availability'),
            subtitle: Text(_availabilityItemsSelected.toString() + " items selected"),
            onTap: () => Navigator.push(context, 
              MaterialPageRoute(settings: RouteSettings(),
              builder: (context) => AvailabilityQuery(_selectedAvailabilityPos, _availabilityMap))).then((result) {
                if (result != null) {
                  _availabilityMap = result[0];
                  // _registerMap['availability'] = result[0];
                  setState(() {
                    _availabilityItemsSelected = result[1].length;
                    _selectedAvailabilityPos = result[1];
                  });

                  if (_isFromProfile) {
                    // check if new and old availability options are same
                    // if not update the _updateMap
                    Function eq = const ListEquality().equals;
                    if (!eq(_selectedAvailabilityPos, availChecks)) {
                      _updateMap['availability_plem'] = _selectedAvailabilityPos;
                    }
                  }
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
            title: !_isFromProfile ? Text('Select specialization(s)') : Text('Modify specialization(s)'),
            subtitle: Text(_specializationsList.length.toString() + " items selected"),
            onTap: () => Navigator.push(context, 
              MaterialPageRoute(settings: RouteSettings(),
              builder: (context) => SpecializationQuery(
                _specializationsList)
                )).then((result) {
                  if (result != null) {
                    // _registerMap['specializations'] = result[0];
                    _specializationsList = result[0];

                    if (_isFromProfile) {
                      // compare the initial specialization list with the modified one
                      // if they are different, update the _updateMap
                      Function eq = const ListEquality().equals;
                      if (!eq(_specializationsList, widget.myuser.specializations)) {
                        _updateMap['specializations'] = _specializationsList;
                      }
                    }
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
            title: !_isFromProfile ? Text('Add profile picture') : Text('Change profile picture'),
            trailing: _isPictureSelected ? 
              (_isPictureCompressed ? CircleAvatar(
                backgroundImage: Image.file(_compressedPic).image
              ) : CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.green[800]),)) 
              : (_isFromProfile ? CircleAvatar(backgroundImage: CachedNetworkImageProvider(widget.imageUrl),) : Container(height: 0.0, width: 0.0,)),
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

  Future<bool> _imageTooBigDialogBox() {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text('The image you selected is too large. Compression is recommended'),
          title: Text('Processing error'),
          actions: <Widget>[
            FlatButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Compress'),
            ),
            FlatButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            )
          ],
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
      setState(() {
        _isLoading = false;
      });

      int picSize = await _picture.length();
      bool toCompress = false;
      // check file size first. If too big (equal to or more than 1 MB), prompt compression
      if (picSize >= 512 * 512) {
        bool userChoice = await _imageTooBigDialogBox();
        // if they chose not to compress, return. Otherwise continue with the compression
        if (!userChoice) {
          setState(() {
           _isPictureSelected = false; // stop the circular progress indicator from spinning!
          });
          return;
        } else toCompress = true;
      } 

      // get image extension
      String image_extension = _picture.path.substring(_picture.path.lastIndexOf(".")+1, _picture.path.length);

      String newPath =_picture.path.substring(0, _picture.path.lastIndexOf("/")+1);
      // print("FILLEEEEEE: " + newPath + widget.userId + "-profile-" + _picture.path.substring(_picture.path.lastIndexOf("/")+1, _picture.path.lastIndexOf(".")) + ".png");
      // return;

      if (toCompress) {
        // if compressed file already exists don't bother
        if (!File(newPath + widget.userId + "-profile-" + _picture.path.substring(_picture.path.lastIndexOf("/")+1, _picture.path.lastIndexOf(".")) + ".png").existsSync()) {
          setState(() {
            _isPictureCompressed = false;
          });
          // Compress image
          File compressedImage = await _initCompress(_picture);
          if (compressedImage != null)
          {
            image_extension = "png";
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
          image_extension = "png";
          setState(() {
            _isPictureCompressed = true;
            // since _compressedPic is in the Widget.build context, set its state here
            _compressedPic = File(newPath + widget.userId + "-profile-" + _picture.path.substring(_picture.path.lastIndexOf("/")+1, _picture.path.lastIndexOf(".")) + ".png");
          });
        }
      } else {
        setState(() {
         _isPictureCompressed = true;
         _compressedPic = File(_picture.path);
        });
        final snackBar = SnackBar(content: Text('Picture added'), duration: Duration(seconds: 2),);
        _scaffoldKey.currentState.showSnackBar(snackBar);
      }
      !_isFromProfile ? _registerMap['picture'] = widget.userId + "-profile." + image_extension
                     : _updateMap['picture'] = widget.userId + "-profile." + image_extension;
    } else {
      setState(() {
       _isPictureSelected = false; 
      });
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
        child: Text(!_isFromProfile ? 'Done' : 'Edit',
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
      bool emailValid = RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(_registerMap['email']);
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
          if (_isFromProfile) _updateMyuser();
          else _registerUser();
          setState(() {
           _isUploadDone = true; 
          });
        }
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
      .child(!_isFromProfile ? _registerMap['picture'] : _updateMap['picture']);

    StorageUploadTask uploadTask = storageReference.putFile(_compressedPic);
    uploadTask.onComplete.whenComplete(() {
      setState(() {
       _isUploadDone = true;
       _isLoading = false; 
      });
      print("End upload picture.");
      if (!_isFromProfile) _registerUser();
      else _updateMyuser();
    });
  }

  _registerUser() async {
    setState(() {
     _isLoading = true; 
    });
    Map<String, Map<String, bool>> updateAvail = _registerMap['availability'];
    _availabilityMap.forEach((k, v) {
      updateAvail[k] = new Map<String, bool>();
      v.forEach((item) {
        // print(item);
        updateAvail[k].addAll({item.toLowerCase(): true});
      });
    });

    _registerMap['availability'] = updateAvail;   
    _registerMap['specializations'] = _specializationsList; 

    // convert city and country to coordinates
    String address = '';
    if (_state != null && _state.length != 0) {
      address = _city + ", " + _state + ", " + _country;
    } else {
      address = _city + ", " + _country;
    }

    _registerMap['coordinates'] = await _addressToCoordinates(address);
    
    print(_registerMap);
    // Get a reference to the document in question
    DocumentReference docRef = Firestore.instance
            .collection("users")
            .document(widget.userId);
    
    
    // // Run transaction to update user to be a myuser
    // // This assumes validation has passed before
    Firestore.instance.runTransaction((transaction) async {
      await transaction.update(docRef, _registerMap);
      print("Update complete");
      setState(() {
       _isLoading = false; 
      });
      bool successAcknowledged = await _successDialogBox();
      if (successAcknowledged) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(
            builder: (context) => RootPage(auth: widget.auth)
          ),
        );
      }
    });
  }

  _updateMyuser() async {
    setState(() {
     _isLoading = true; 
    });
    // check if stuff has changed
    // 1. check name
    if (_name != widget.myuser.name) _updateMap['name'] = _name;
    else _updateMap.remove('name');
    // 2. check email
    if (_email != widget.myuser.email) _updateMap['email'] = _email;
    else _updateMap.remove('email');
    // 3. check phone
    if (_phone != widget.myuser.phone) _updateMap['phone'] = _phone;
    else _updateMap.remove('phone');
    // 4. check city
    if (_city != widget.myuser.city) _updateMap['city'] = _city;
    else _updateMap.remove('city');
    // 5. check country
    if (_country != widget.myuser.country) _updateMap['country'] = _country;
    else _updateMap.remove('country');
    // 6. check state
    if (_state != null && _state != widget.myuser.state) _updateMap['state'] = _state;
    else _updateMap.remove('state');

    // if location has changed, get the coordinates
    // convert city and country to coordinates
    String address = '';
    if (_updateMap['state'] != null) {
      if (_updateMap['city'] != null && _updateMap['country'] != null)
        address = _city + ", " + _state + ", " + _country;
    } else {
      if (_updateMap['city'] != null && _updateMap['country'] != null)
        address = _city + ", " + _country;
    }

    print('address: $address');
    if (address != null && address.length > 0)
      _updateMap['coordinates'] = await _addressToCoordinates(address);
    // 7. check charge
    if (_charge != widget.myuser.charge) _updateMap['typical_hourly_charge'] = _charge;
    else _updateMap.remove('charge');

    if (_updateMap['availability_plem'] != null) {
      _updateMap['availability'] = _convertAvailability(_updateMap['availability_plem']);
      _updateMap.remove('availability_plem');
    }

    /// [_updateMap] to update Myuser info
    print("UPDATE MAP:");
    print(_updateMap);

    
    
    // run transaction to update myuser
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
    });

    bool successAcknowledged = await _successDialogBox();
    if (successAcknowledged) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(
          builder: (context) => RootPage(auth: widget.auth)
        ),
      );
    }
  }

  Future<bool> _successDialogBox() {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: !_isFromProfile ? Text('Congratulations! You have been registered as a Myuser') : Text('Your profile has been update successfully'),
          title: Text('Success'),
          actions: <Widget>[
            FlatButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Okay'),
            ),
          ],
        );
      }
    );
  }

  // convert selected availability indices back to our firebase availability representation
  Map<String, Map<String, bool>> _convertAvailability(List<int> indices) {
    Map<String, Map<String, bool>> toReturn = new Map<String, Map<String, bool>>();
    // get the String availability from index
    indices.forEach((index) {
      // grab the string availability
      String avail = pos_to_avail[index];
      // get day
      String day = avail.split(",")[0];
      // get time of day
      String time = avail.split(",")[1];

      if (toReturn[day] == null) toReturn[day] = Map<String, bool>();

      toReturn[day].addAll({time: true});
    });

    return toReturn;
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
    return _isLoading ? Center(child: CircularProgressIndicator(),) 
               : Container(height: 0.0, width: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    _isIos = Theme.of(context).platform == TargetPlatform.iOS;
    return new Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: !_isFromProfile ? Text("Register") : Text("Edit profile"),
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