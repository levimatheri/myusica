import 'package:cloud_firestore/cloud_firestore.dart';

class Access {
  static final Access _access = new Access._internal();
  Query query;
  factory Access() {
    return _access;
  }

  Access._internal();
}