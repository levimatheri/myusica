import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myusica/helpers/dialogs.dart';

abstract class BaseAuth {
  Future<String> signIn(String email, String password);

  Future<String> signUp(String username, String email, String password);

  Future<void> addNewCustomUser(String username, String userId);

  Future<FirebaseUser> getCurrentUser();

  Future<String> getUsername(String userId);

  Future<List<dynamic>> getChats(String userId);

  Future<List<String>> getPushTokens(String userId);

  Future<void> signOut();

  Future<bool> isMyuser(String userId);

  Future<Map<String, dynamic>> getUser(String userId);

  Future<void> resetPassword(String email);
}

class Auth implements BaseAuth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final Firestore _firestoreRecord = Firestore.instance;

  @override
  Future<String> signUp(String username, String email, String password) async {
    FirebaseUser user = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email, password: password
    );

    try {
      await user.sendEmailVerification();
      
      return user.uid;
    } catch (e) {
      print("An error occured while trying to send email verification");
      user.delete(); // delete user from authentication database
      return "Email verification could not be sent";
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }


  @override
  Future<void> addNewCustomUser(String username, String userId) async {
    await _firestoreRecord
      .collection('users')
      .document(userId).setData({"username": username, "type": "guest"});
  }


  @override
  Future<String> signIn(String email, String password) async {
    FirebaseUser user = await _firebaseAuth.signInWithEmailAndPassword(
      email: email, password: password
    );
    if (user.isEmailVerified) return user.uid;
    else return "Email not verified";
  }

  @override
  Future<FirebaseUser> getCurrentUser() async {
    FirebaseUser user = await _firebaseAuth.currentUser();
    return user;
  }

  @override
  Future<String> getUsername(String userId) async {
    DocumentSnapshot snapshot = await _firestoreRecord.collection("users").document(userId).get();
    if (snapshot.data == null) return null;
    return snapshot.data['username'];
  }

  Future<List<dynamic>> getChats(String userId) async {
    DocumentSnapshot snapshot = await _firestoreRecord.collection("users").document(userId).get();
    if (snapshot.data == null) return null;
    return snapshot.data['chatIds'];
  }

  @override
  Future<List<String>> getPushTokens(String userId) async {
    DocumentSnapshot snapshot = await _firestoreRecord.collection("users").document(userId).get();
    if (snapshot.data == null) return null;
    return List<String>.from(snapshot.data['pushtokens']);
  }  

  @override
  Future<bool> isMyuser(String userId) async {
    DocumentSnapshot snapshot = await _firestoreRecord.collection("users").document(userId).get();
    if (snapshot.data == null) return null;
    return snapshot.data['type'] == 'myuser';
  }

  @override
  Future<Map<String, dynamic>> getUser(String userId) async {
    DocumentSnapshot snapshot = await _firestoreRecord.collection("users").document(userId).get();
    if (snapshot.data == null) return null;
    return Map<String, dynamic>.from(snapshot.data);
  }




  @override
  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }
}