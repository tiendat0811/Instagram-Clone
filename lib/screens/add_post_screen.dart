import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instagram_clone/utils/colors.dart';
import 'package:instagram_clone/utils/utils.dart';
import '../resources/storage_methods.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({Key? key}) : super(key: key);

  @override
  _AddPostScreenState createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  bool isLoading = false;
  Uint8List? _file;
  Map userInfo = <String, dynamic>{
    'uid': 'uid',
    'name': '',
    'email': '',
    'photoUrl': '',
    'bio': '',
  };

  void postImage(String uid, String username, String profImage) async {
    setState(() {
      isLoading = true;
    });
    // start the loading
    String res = "ERROR";
    try {
      DatabaseReference ref = FirebaseDatabase.instance.ref("posts/").push();
      String postId = ref.key.toString();
      String postUrl = await StorageMethods()
          .uploadImageToStorage('postImages', _file!, true, postId);
      Map<String, dynamic> postInfo = {
        'description': _descriptionController.text,
        'postImage': postUrl,
        'uid': userInfo["uid"],
        'username': userInfo["name"],
        'userImage': userInfo["photoUrl"],
        'datePublished': DateTime.now().millisecondsSinceEpoch,
        'countCmt' : 0
      };
      ref.set(postInfo);
      FirebaseDatabase.instance.ref("likes/").child(postId).set({
        "start" : false
      });
      res = 'addPost success';
      if (res == "addPost success") {
        setState(() {
          isLoading = false;
        });
        showSnackBar('Posted!', context);
        clearImage();
      } else {
        showSnackBar(res, context);
      }
    } catch (err) {
      setState(() {
        isLoading = false;
      });
      showSnackBar(err.toString(), context);
    }
  }

  void clearImage() {
    setState(() {
      _file = null;
    });
  }

  @override
  void initState() {
    super.initState();
    getUser();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void getUser() async{
    String uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseDatabase.instance.ref();
    final snapshot = await ref.child('users/$uid').get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
      setState(() {
        userInfo.update('uid', (value) => uid);
        userInfo.update('name', (value) => data['username']);
        userInfo.update('email', (value) => data['email']);
        userInfo.update('photoUrl', (value) => data['photoUrl']);
        userInfo.update('bio', (value) => data['bio']);
      });
    } else {
      print('No data available.');
    }
  }

  _selectImage(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: const Text("Create a new post"),
            children: [
              SimpleDialogOption(
                padding: const EdgeInsets.all(20),
                child: const Text("Take a photo"),
                onPressed: () async {
                  Navigator.of(context).pop();
                  Uint8List file = await pickImage(ImageSource.camera);
                  setState(() {
                    _file = file;
                  });
                },
              ),
              SimpleDialogOption(
                padding: const EdgeInsets.all(20),
                child: const Text("Choose a photo from Gallery"),
                onPressed: () async {
                  Navigator.of(context).pop();
                  Uint8List file = await pickImage(ImageSource.gallery);
                  setState(() {
                    _file = file;
                  });
                },
              ),
              SimpleDialogOption(
                padding: const EdgeInsets.all(20),
                child: const Text("Cancel"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return _file == null
        ? Center(
            child: IconButton(
              icon: const Icon(
                Icons.upload,
              ),
              onPressed: () => _selectImage(context),
            ),
          )
        : Scaffold(
            appBar: AppBar(
              backgroundColor: mobileBackgroundColor,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: clearImage,
              ),
              title: Text(
                "New post",
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => postImage(userInfo["uid"].toString(),
                      userInfo["username"].toString(), userInfo["photoUrl"].toString()),
                  child: const Text(
                    "Post",
                    style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0),
                  ),
                )
              ],
            ),
            body: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(userInfo["photoUrl"]),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.3,
                      child: TextField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                            hintText: "Write a caption...",
                            border: InputBorder.none),
                        maxLines: 8,
                      ),
                    ),
                    SizedBox(
                      height: 45.0,
                      width: 45.0,
                      child: AspectRatio(
                        aspectRatio: 487 / 451,
                        child: Container(
                          decoration: BoxDecoration(
                              image: DecorationImage(
                            fit: BoxFit.fill,
                            alignment: FractionalOffset.topCenter,
                            image: MemoryImage(_file!),
                          )),
                        ),
                      ),
                    ),
                    const Divider(),
                  ],
                )
              ],
            ),
          );
  }
}
