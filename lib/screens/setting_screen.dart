import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../resources/storage_methods.dart';
import '../utils/colors.dart';
import '../utils/utils.dart';
import '../widgets/text_field_input.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  var userData = {};
  final _uid = FirebaseAuth.instance.currentUser!.uid;

  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  Uint8List? _image;
  bool _isLoading = false;

  void selectImage() async {
    Uint8List imagePicked = await pickImage(ImageSource.gallery);
    setState(() {
      _image = imagePicked;
    });
  }

  @override
  void initState() {
    super.initState();
    getData();
  }

  getData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      //get user info
      final ref = FirebaseDatabase.instance.ref();
      final snapshot = await ref.child('users').child(_uid).get();
      final data =
          Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
      if (data.isNotEmpty) {
        userData = data;
      }
      setState(() {});
    } catch (e) {
      print(e.toString());
    }
    setState(() {
      _isLoading = false;
    });
  }

  void updateUserInfo() async {
    setState(() {
      _isLoading = true;
    });
    try {
      String res = "ERROR";
      String username = _usernameController.text;
      String bio = _bioController.text;
      DatabaseReference ref = FirebaseDatabase.instance.ref("users/$_uid");
      if (_image != null) {
        String avatarUrl = await StorageMethods()
            .uploadImageToStorage('avatars', _image!, false, "");
        if(username == ''){
          ref.update({
            'photoUrl': avatarUrl,
            'bio': bio,
          });
        }else if(bio == ''){
          ref.update({
            'username': username,
            'photoUrl': avatarUrl,
          });
        }else{
          ref.update({
            'username': username,
            'photoUrl': avatarUrl,
            'bio': bio,
          });
        }

      } else {
        if(username == ''){
          ref.update({
            'bio': bio,
          });
        }else if(bio == ''){
          ref.update({
            'username': username,
          });
        }else{
          ref.update({
            'username': username,
            'bio': bio,
          });
        }
        showSnackBar("Edit information success!!!", context);
      }
    } catch (e) {
      print(e.toString());
    }
    getData();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _bioController.dispose();
    _usernameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Center(
            child: CircularProgressIndicator(),
          )
        : Scaffold(
            appBar: AppBar(
              backgroundColor: mobileBackgroundColor,
              title: const Text(
                'Edit profile',
              ),
              centerTitle: false,
            ),
            body: Center(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.all(30),
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          _image != null
                              ? CircleAvatar(
                                  radius: 54,
                                  backgroundImage: MemoryImage(_image!),
                                )
                              : CircleAvatar(
                                  radius: 54,
                                  backgroundImage:
                                      NetworkImage(userData['photoUrl']),
                                ),
                          Positioned(
                            bottom: -10,
                            left: 70,
                            child: IconButton(
                                icon: Icon(Icons.add_a_photo),
                                onPressed: selectImage),
                          )
                        ],
                      ),
                      SizedBox(
                        height: 44,
                      ),
                      //username
                      TextFieldInput(
                          textEditingController: _usernameController,
                          hintText: userData['username'],
                          textInputType: TextInputType.text),
                      //password
                      SizedBox(
                        height: 24,
                      ),

                      //bio
                      TextFieldInput(
                          textEditingController: _bioController,
                          hintText: userData['bio'],
                          textInputType: TextInputType.text),
                      //password
                      SizedBox(
                        height: 34,
                      ),
                      InkWell(
                        onTap: updateUserInfo,
                        child: Container(
                          child: _isLoading
                              ? Center(
                                  child: CircularProgressIndicator(
                                    color: primaryColor,
                                  ),
                                )
                              : Text("Confirm",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                          width: double.infinity,
                          alignment: Alignment.center,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          decoration: ShapeDecoration(
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(4)),
                            ),
                            color: blueColor,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 12,
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
  }
}
