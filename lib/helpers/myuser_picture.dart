import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:myusica/helpers/myuser.dart';
import 'package:myusica/helpers/user.dart';

// get myuser profile picture url from firebase
Future<dynamic> getProfilePicture(Myuser myuser) async {
  try {
    FirebaseStorage storage = new FirebaseStorage(
      storageBucket: 'gs://myusica-4818e.appspot.com'
    );
    StorageReference imageLink = 
      storage.ref().child('myuser-profile-pictures').child(myuser.picture);
    final imageUrl = await imageLink.getDownloadURL();
    return imageUrl;
  } catch (e) {
    print("No picture found");
    return null;
  } 
}

//TODO: NEED TO ABSTRACT USER CLASS TO AVOID CREATING IDENTICAL FUNCTIONS
Future<dynamic> getUserProfilePicture(User user) async {
  try {
    FirebaseStorage storage = new FirebaseStorage(
      storageBucket: 'gs://myusica-4818e.appspot.com'
    );
    StorageReference imageLink = 
      storage.ref().child('myuser-profile-pictures').child(user.picture);
    final imageUrl = await imageLink.getDownloadURL();
    return imageUrl;
  } catch (e) {
    print("No picture found");
    return null;
  } 
}
