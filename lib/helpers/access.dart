import 'package:cloud_firestore/cloud_firestore.dart';

class Access {
  // static final Access _access = new Access._internal();
  Query query = Firestore.instance.collection("users").where("type", isEqualTo: "myuser");
  
  // factory Access() {
  //   return _access;
  // }

  // Access._internal();
  
}