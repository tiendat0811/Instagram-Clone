import 'dart:collection';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '/screens/profile_screen.dart';
import 'package:jiffy/jiffy.dart';

class CommentScreen extends StatefulWidget {
  final postId;

  const CommentScreen({Key? key, required this.postId}) : super(key: key);

  @override
  _CommentScreenState createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController commentEditingController =
      TextEditingController();
  var userList = {};
  var postData = {};
  bool isLoading = false;

  void getData() async {
    setState(() {
      isLoading = true;
    });
    final ref = FirebaseDatabase.instance.ref();
    final snapshot = await ref.child('users').get();
    if (snapshot.exists) {
      final data =
          Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
      setState(() {
        userList = data;
      });

      final snapshot2 = await ref.child('posts').child(widget.postId).get();
      if (snapshot2.exists) {
        final data =
            Map<String, dynamic>.from(snapshot2.value as Map<dynamic, dynamic>);
        setState(() {
          postData = data;
        });
      }
    } else {
      print('No data available.');
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    getData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void postComment() async {
    try {
      DatabaseReference ref = await FirebaseDatabase.instance
          .ref("posts")
          .child(widget.postId)
          .child("comments")
          .push();
      Map<String, dynamic> cmtInfo = {
        'text': commentEditingController.text,
        'datePublished': DateTime.now().millisecondsSinceEpoch,
        'uid': _uid
      };
      ref.set(cmtInfo);

      //notification
      //send notification
      final notifications = await FirebaseDatabase.instance
          .ref("users")
          .child('${postData["uid"]}')
          .child("notifications");

      notifications.push().set({
        'uid': _uid,
        'text': "commented on your post",
        'datePublished': DateTime.now().millisecondsSinceEpoch
      });
      int unseenNotificationCount = 0;
      if (userList[postData['uid']]['unseenNotificationCount'] != null) {
        unseenNotificationCount =
            userList[postData['uid']]['unseenNotificationCount'];
      }
      await FirebaseDatabase.instance
          .ref("users")
          .child(postData['uid'])
          .update({"unseenNotificationCount": unseenNotificationCount + 1});

      setState(() {
        commentEditingController.text = "";
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
        getData();
      });
    } catch (err) {
      print(err.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Theme.of(context).primaryColor,
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          'Comments',
          style: TextStyle(color: Theme.of(context).primaryColor,),
        ),
        centerTitle: false,
      ),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref('users').onValue,
        builder: (context, snapshotUser) {
          var usersData = {};
          if (snapshotUser.hasData) {
            DatabaseEvent users = snapshotUser.data! as DatabaseEvent;
            if (users.snapshot.exists) {
              usersData = Map<String, dynamic>.from(
                  users.snapshot.value as Map<dynamic, dynamic>);
            }
          }

          return StreamBuilder(
            stream: FirebaseDatabase.instance
                .ref('posts')
                .child(widget.postId)
                .child("comments")
                .onValue,
            builder: (context, snapshot) {
              final commentList = <ListTile>[];
              if (snapshot.hasData) {
                DatabaseEvent comments = snapshot.data! as DatabaseEvent;
                if (comments.snapshot.exists) {
                  final commentsData = Map<String, dynamic>.from(
                      comments.snapshot.value as Map<dynamic, dynamic>);
                  var sortByValue = new SplayTreeMap<String, dynamic>.from(
                      commentsData,
                      (key2, key1) => commentsData[key1]['datePublished']
                          .compareTo(commentsData[key2]['datePublished']));
                  sortByValue.forEach((key, value) {
                    final nextComment = Map<String, dynamic>.from(value);
                    final userInfo = usersData[nextComment['uid']];
                    final commentTile = ListTile(
                        title: InkWell(
                      onTap: () {
                        if (_uid == nextComment['uid']) {
                          showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                    backgroundColor: Colors.redAccent,
                                    title: Text("Delete comment"),
                                    content: Text(
                                        "Are you sure you want to delete this comment?"),
                                    actions: <Widget>[
                                      FlatButton(
                                        onPressed: () {
                                          Navigator.of(ctx).pop();
                                        },
                                        child: Text("Cancel"),
                                      ),
                                      FlatButton(
                                        onPressed: () async {
                                          await FirebaseDatabase.instance
                                              .ref("posts")
                                              .child(widget.postId)
                                              .child("comments")
                                              .child(key)
                                              .remove();

                                          Navigator.of(ctx).pop();
                                        },
                                        child: Text("Ok"),
                                      ),
                                    ],
                                  ));
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 16),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ProfileScreen(
                                    uid: nextComment['uid'],
                                  ),
                                ),
                              ),
                              child: CircleAvatar(
                                backgroundImage: NetworkImage(
                                  userInfo['photoUrl'],
                                ),
                                radius: MediaQuery.of(context).size.width*0.05,
                              ),
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
                                      style: TextStyle(
                                       fontSize: MediaQuery.of(context).size.width*0.04,
                                      ),
                                        children: [
                                          TextSpan(
                                              text: userInfo['username'],
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).primaryColor
                                              )),
                                          TextSpan(
                                            text: " " + nextComment['text'],
                                            style: TextStyle(color: Theme.of(context).primaryColor)
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        Jiffy(DateTime
                                                .fromMillisecondsSinceEpoch(
                                                    nextComment[
                                                        'datePublished']))
                                            .fromNow(),
                                        style:  TextStyle(
                                          fontSize: MediaQuery.of(context).size.width*0.035,
                                          color: Colors.grey,
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
                    ));
                    commentList.add(commentTile);
                  });
                } else {
                  final empty = ListTile(
                    title: Center(
                      child: Text("There are no comments yet"),
                    ),
                  );
                  commentList.add(empty);
                }
              }
              return ListView(
                children: commentList,
              );
            },
          );
        },
      ),
      bottomNavigationBar: isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : SafeArea(
              child: Container(
                height: kToolbarHeight,
                margin: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(userList[_uid]['photoUrl']),
                      radius: 18,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 8),
                        child: TextField(
                          controller: commentEditingController,
                          decoration: InputDecoration(
                            hintText:
                                'Comment as ${userList[_uid]['username']}',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => postComment(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 8),
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
