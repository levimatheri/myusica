import 'package:flutter/material.dart';
// import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_masked_text/flutter_masked_text.dart';
import 'package:myusica/subs/availability_query.dart';
import 'package:myusica/helpers/countries.dart';
/// Myuser registration
class Register extends StatefulWidget {
  RegisterState createState() => new RegisterState();
}

class RegisterState extends State<Register> {
  final _formKey = new GlobalKey<FormState>();

  String _name;

  String _country;
  var _controller = new MoneyMaskedTextController(leftSymbol: 'US\$', 
                            decimalSeparator: '.');

  Map<String, List<String>> _availabilityMap = new Map<String, List<String>>();
  List<int> _selectedItemsPositions = new List<int>();
  int _availabilityItemsSelected = 0;

  bool _isLoading;
  bool _isIos;
  String _errorMessage;

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
            // _showCountryInput(),
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
        onSaved: (value) => _name = value,
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
        onSaved: (value) => _name = value,
      ),
    );
  }

  List<String> getCountries() {

  }

  Widget _showCountryInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 20.0),
      // child: CountryCodePicker(
      //   onChanged: (countryCode) {
      //     _country = countryCode.name;
      //   },
      //   initialSelection: 'US',
      // ),
      child: DropdownButton(
        items: country_list.map((String val) {
          return DropdownMenuItem(
            value: val,
            child: Text(val),
          );
        }).toList(),
        onChanged: (selected) {
          _country = selected;
        },
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
        onSaved: (value) => _name = value,
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
        onSaved: (value) => _name = value,
      ),
    );
  }

  Widget _showChargeInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 20.0),
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
        validator: (value) => value.isEmpty ? 'Phone cannot be empty' : null,
        onSaved: (value) => _name = value,
      ),
    );
  }

  Widget _showAvailabilityInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 20.0),
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

  Widget _showDoneButton() {
    return new Padding(
      padding: EdgeInsets.fromLTRB(0.0, 45.0, 0.0, 0.0),
      child: new MaterialButton(
        elevation: 5.0,
        minWidth: 200.0,
        height: 42.0,
        color: Colors.orange,
        child: Text('Create account',
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
      String userId = "";
      try {
        // Implement transaction to Firebase

        setState(() {
          _isLoading = false;        
        });
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
  Widget build(BuildContext context) {
    _isIos = Theme.of(context).platform == TargetPlatform.iOS;
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Register"),
      ),
      body: Stack(
        children: <Widget>[
          _showBody(),
        ],
      ),
    );
  }
}