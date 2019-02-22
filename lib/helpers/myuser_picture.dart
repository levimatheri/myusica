import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:myusica/helpers/myuser.dart';

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
