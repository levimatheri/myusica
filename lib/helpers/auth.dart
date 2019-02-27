import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class BaseAuth {
  Future<String> signIn(String email, String password);

  Future<String> signUp(String username, String email, String password);

  Future<FirebaseUser> getCurrentUser();

  Future<String> getUsername(String userId);

  Future<void> signOut();

  Future<bool> isMyuser(String userId);

  Future<Map<String, dynamic>> getUser(String userId);
}

class Auth implements BaseAuth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final Firestore _firestoreRecord = Firestore.instance;

  @override
  Future<String> signUp(String username, String email, String password) async {
    FirebaseUser user = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email, password: password
    );
    // Also add user to our custom database
    await _firestoreRecord
      .collection('users')
      .document(user.uid).setData({"username": username, "type": "guest"});
    return user.uid;
  }

  @override
  Future<String> signIn(String email, String password) async {
    FirebaseUser user = await _firebaseAuth.signInWithEmailAndPassword(
      email: email, password: password
    );
    return user.uid;
  }

  @override
  Future<FirebaseUser> getCurrentUser() async {
    FirebaseUser user = await _firebaseAuth.currentUser();
    return user;
  }

  @override
  Future<String> getUsername(String userId) async {
    DocumentSnapshot snapshot = await _firestoreRecord.collection("users").document(userId).get();
    return snapshot.data['username'];
  }

  @override
  Future<bool> isMyuser(String userId) async {
    DocumentSnapshot snapshot = await _firestoreRecord.collection("users").document(userId).get();
    return snapshot.data['type'] == 'myuser';
  }

  @override
  Future<Map<String, dynamic>> getUser(String userId) async {
    DocumentSnapshot snapshot = await _firestoreRecord.collection("users").document(userId).get();
    return snapshot.data;
  }


  @override
  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }
}