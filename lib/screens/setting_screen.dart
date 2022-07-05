import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../resources/storage_methods.dart';
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
  final TextEditingController _fullnameController = TextEditingController();
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
      String username = _usernameController.text;
      String bio = _bioController.text;
      String fullname = _fullnameController.text;
      if(username == '' ){
        username = userData['username'];
      }
      if(bio == ''){
        bio = userData['bio'];
      }
      if(fullname == ''){
        fullname = userData['fullname'];
      }
      DatabaseReference ref = FirebaseDatabase.instance.ref("users/$_uid");
      if (_image != null) {
        String avatarUrl = await StorageMethods()
            .uploadImageToStorage('avatars', _image!, false, "");
          ref.update({
            'username': username,
            'photoUrl': avatarUrl,
            'bio': bio,
            'fullname': fullname
          });
      } else {
          ref.update({
            'username': username,
            'bio': bio,
            'fullname': fullname
          });
      }
      showSnackBar("Edit information success!!!", context);
      _fullnameController.text = "";
      _bioController.text = "";
      _usernameController.text = "";
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
    _fullnameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(
            child: const CircularProgressIndicator(),
          )
        : Scaffold(
            appBar: AppBar(
              iconTheme: IconThemeData(
                color: Theme.of(context).primaryColor,
              ),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: Text(
                'Edit profile',
                style: TextStyle(
                    color: Theme.of(context).primaryColor
                ),
              ),
              centerTitle: false,
            ),
            body: Center(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(30),
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
                                icon: const Icon(Icons.add_a_photo),
                                onPressed: selectImage),
                          )
                        ],
                      ),
                      const SizedBox(
                        height: 44,
                      ),
                      //username
                      TextFieldInput(
                        textEditingController: _usernameController,
                        hintText: userData['username'],
                        textInputType: TextInputType.text,
                        label: "Username",
                      ),
                      //password
                      const SizedBox(
                        height: 24,
                      ),
                      //fullname
                      TextFieldInput(
                        textEditingController: _fullnameController,
                        hintText: userData['fullname'],
                        textInputType: TextInputType.text,
                        label: "Fullname",
                      ),
                      //password
                      const SizedBox(
                        height: 24,
                      ),
                      //bio
                      TextFieldInput(
                        textEditingController: _bioController,
                        hintText: userData['bio'],
                        textInputType: TextInputType.text,
                        label: "Your bio",
                      ),
                      //password
                      const SizedBox(
                        height: 34,
                      ),
                      InkWell(
                        onTap: updateUserInfo,
                        child: Container(
                          child: _isLoading
                              ? const Center(
                                  child: const CircularProgressIndicator(
                                    color: Colors.blue,
                                  ),
                                )
                              : const Text("Confirm",
                                  style:
                                      const TextStyle(fontWeight: FontWeight.bold)),
                          width: double.infinity,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: const ShapeDecoration(
                            shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(const Radius.circular(4)),
                            ),
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(
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
