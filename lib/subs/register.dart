import 'package:flutter/material.dart';
// import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_masked_text/flutter_masked_text.dart';
import 'package:myusica/subs/availability_query.dart';
import 'package:myusica/helpers/countries.dart';
import 'package:myusica/subs/autocomplete_query.dart';
/// Myuser registration
class Register extends StatefulWidget {
  RegisterState createState() => new RegisterState();
}

class RegisterState extends State<Register> {
  final _formKey = new GlobalKey<FormState>();

  String _name;
  String _city;
  String _state;
  String _country;
  String _email;
  String _phone;
  String _charge;

  Map<String, List<String>> _availabilityMap = new Map<String, List<String>>();
  List<int> _selectedItemsPositions = new List<int>();
  int _availabilityItemsSelected = 0;

  var _controller = new MoneyMaskedTextController(leftSymbol: 'US\$', 
                            decimalSeparator: '.');

  FocusNode _countryFocusNode = new FocusNode();
  TextEditingController _countryTextController = new TextEditingController();                            

  bool _isLoading;
  bool _isIos;
  String _errorMessage;

  @override
  void initState() {
    super.initState();
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