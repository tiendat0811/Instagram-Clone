import 'dart:collection';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/colors.dart';
import '../utils/utils.dart';

class CommentScreen extends StatefulWidget {
  final postId;

  const CommentScreen({Key? key, required this.postId}) : super(key: key);

  @override
  _CommentScreenState createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController commentEditingController =
      TextEditingController();
  final Map userInfo = <String, dynamic>{
    'uid': 'uid',
    'name': '',
    'email': '',
    'photoUrl': "https://images.squarespace-cdn.com/content/v1/54b7b93ce4b0a3e130d5d232/1519987020970-8IQ7F6Z61LLBCX85A65S/icon.png?format=1000w",
    'bio': '',
    'followers': '',
    'following': ''
  };

  void getUser() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseDatabase.instance.ref();
    final snapshot = await ref.child('users/$uid').get();
    if (snapshot.exists) {
      final data =
          Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
      setState(() {
        userInfo.update('uid', (value) => uid);
        userInfo.update('name', (value) => data['username']);
        userInfo.update('email', (value) => data['email']);
        userInfo.update('photoUrl', (value) => data['photoUrl']);
        userInfo.update('bio', (value) => data['bio']);
        userInfo.update('followers', (value) => data['followers']);
        userInfo.update('following', (value) => data['following']);
      });
    } else {
      print('No data available.');
    }
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

  void postComment() async {
    String res = "ERROR";
    try {

      DatabaseReference ref = await FirebaseDatabase.instance.ref("comments/${widget.postId}/").push();
      Map<String, dynamic> cmtInfo = {
        'text': commentEditingController.text,
        'username': userInfo["name"],
        'userImage': userInfo["photoUrl"],
        'datePublished': DateTime.now().millisecondsSinceEpoch,
        'uid' : userInfo['uid']
      };
      ref.set(cmtInfo);
      res = 'success';

      final snapshot = await FirebaseDatabase.instance.ref("posts/${widget.postId}/").get();
      if (snapshot.exists) {
        final data =
        Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
        int count = data['countCmt'];
        count++;
        await FirebaseDatabase.instance.ref("posts/${widget.postId}/").update({'countCmt': count});
      }
      if (res != 'success') {
        showSnackBar(res, context);
      }
      setState(() {
        commentEditingController.text = "";
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      });
    } catch (err) {
      showSnackBar(res, context);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        title: const Text(
          'Comments',
        ),
        centerTitle: false,
      ),
      body: StreamBuilder(
        stream:
            FirebaseDatabase.instance.ref('comments/${widget.postId}').onValue,
        builder: (context, snapshot) {
          final commentList = <ListTile>[];
          if(snapshot.hasData){
            DatabaseEvent comments = snapshot.data! as DatabaseEvent;
            if(comments.snapshot.exists){
              final commentsData = Map<String, dynamic>.from(
                  comments.snapshot.value as Map<dynamic, dynamic>);
              var sortByValue = new SplayTreeMap<String, dynamic>.from(
                  commentsData, (key2, key1) => commentsData[key1]['datePublished'].compareTo(commentsData[key2]['datePublished']));
              sortByValue.forEach((key, value) {
                final nextComment = Map<String, dynamic>.from(value);
                final commentTile = ListTile(
                  title: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(
                            nextComment['userImage'],
                          ),
                          radius: 18,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                          text: nextComment['username'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          )),
                                      TextSpan(
                                        text: " "+ nextComment['text'],
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    DateFormat.Hm().format(
                                        DateTime.fromMillisecondsSinceEpoch(
                                            nextComment
                                            ['datePublished'])) +
                                        " " +
                                        DateFormat.yMMMMd().format(
                                            DateTime.fromMillisecondsSinceEpoch(
                                                nextComment
                                                ['datePublished'])),
                                    style: const TextStyle(
                                      color: secondaryColor,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                commentList.add(commentTile);
              });
            }else{
              final empty = ListTile(
                title: Center(child: Text("There are no comments yet"),),
              );
              commentList.add(empty);
            }
          }
          return ListView(
           children: commentList,
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: kToolbarHeight,
          margin:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(userInfo['photoUrl']),
                radius: 18,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: TextField(
                    controller: commentEditingController,
                    decoration: InputDecoration(
                      hintText: 'Comment as ${userInfo['name']}',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: () => postComment(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: const Text(
                    'Post',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
