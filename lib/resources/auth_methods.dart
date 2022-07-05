import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '/resources/storage_methods.dart';

class AuthMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //sign up user
  signUpUser({
    required String email,
    required String password,
    required String username,
    required String fullname,
    required String bio,
    required Uint8List file,

  }) async {
    String res = "ERROR!";
    try {
      if (email.isNotEmpty ||
          password.isNotEmpty ||
          username.isNotEmpty ||
          fullname.isNotEmpty ||
          bio.isNotEmpty) {
        UserCredential credential = await _auth.createUserWithEmailAndPassword(
            email: email, password: password);
        String uid = credential.user!.uid.toString();
        String avatarUrl =
            await StorageMethods().uploadImageToStorage('avatars', file, false, "");

        DatabaseReference ref = FirebaseDatabase.instance.ref("users/$uid");
        ref.set({'username': username,
          'photoUrl': avatarUrl,
          'email': email,
          'fullname': fullname,
          'bio': bio,
          });

        res = "sign up success";
      }
    } on FirebaseException catch (err) {
      res = err.message.toString();
    }
    return res;
  }

  //login user
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    String res = "ERROR";
    try {
      if (email.isNotEmpty || password.isNotEmpty) {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        res = "login success";
      } else {
        res = "Please enter all the fields";
      }
    } on FirebaseException catch (err) {
      res = err.message.toString();
    }
    return res;
  }

  //logout
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
