import 'dart:collection';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '/screens/profile_screen.dart';

import '/utils/utils.dart';
import 'package:jiffy/jiffy.dart';

class DetailPostScreen extends StatefulWidget {
  final postId;

  const DetailPostScreen({Key? key, required this.postId}) : super(key: key);

  @override
  State<DetailPostScreen> createState() => _DetailPostScreenState();
}

class _DetailPostScreenState extends State<DetailPostScreen> {
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController commentEditingController =
      TextEditingController();
  var post = {};
  var userList = {};
  bool isLoading = false;
  late FocusNode myFocusNode;
  bool isLiked = false;
  int countLike = 0;
  int countCmt = 0;

  void getData() async {
    setState(() {
      isLoading = true;
    });
    //get user
    final snapshot = await FirebaseDatabase.instance.ref().child('users').get();
    if (snapshot.exists) {
      final data =
          Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
      userList = data;
      setState(() {});
    } else {
      print('No data available.');
    }
    //get post
    final ref = FirebaseDatabase.instance.ref();
    final postSnapshot = await ref.child('posts/${widget.postId}').get();
    if (postSnapshot.exists) {
      final data = Map<String, dynamic>.from(
          postSnapshot.value as Map<dynamic, dynamic>);
      post = data;
      if (post['likes'] != null) {
        var likesData = Map<String, dynamic>.from(post['likes']);
        countLike = likesData.length;
        if (likesData.containsKey(_uid)) {
          isLiked = true;
        }
      }
      setState(() {});
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
    myFocusNode = FocusNode();
  }

  @override
  void dispose() {
    myFocusNode.dispose();
    super.dispose();
  }

  void deletePost(String postId) async {
    String res = "ERROR";
    try {
      await FirebaseDatabase.instance.ref("posts/${postId}").remove();
      res = 'success';
      if (res != 'success') {
        showSnackBar(res, context);
      }
      setState(() {});
    } catch (err) {
      showSnackBar(res, context);
    }
  }

  void postComment() async {
    String res = "ERROR";
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

      if (post['comments'] != null) {
        var commentsData = Map<String, dynamic>.from(post['comments']);

        countCmt = commentsData.length;
      }
      countCmt++;

      //send notification
      final notifications = await FirebaseDatabase.instance
          .ref("users")
          .child('${post["uid"]}')
          .child("notifications");

      notifications.push().set({
        'uid': _uid,
        'text': "commented on your post",
        'datePublished': DateTime.now().millisecondsSinceEpoch
      });
      int unseenNotificationCount = 0;
      if (userList[post['uid']]['unseenNotificationCount'] != null) {
        unseenNotificationCount =
            userList[post['uid']]['unseenNotificationCount'];
      }
      await FirebaseDatabase.instance
          .ref("users")
          .child(post['uid'])
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
          'Post',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
          ),
        ),
        centerTitle: false,
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: const EdgeInsets.symmetric(
          vertical: 10,
        ),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : ListView(
                children: [
                  //HEADER POST
                  Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: 4, horizontal: 6)
                              .copyWith(right: 0),
                      child: InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(
                              uid: post['uid'],
                            ),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            CircleAvatar(
                              radius: MediaQuery.of(context).size.width*0.05,
                              backgroundImage: NetworkImage(
                                  userList[post["uid"]]['photoUrl']),
                            ),
                            Expanded(
                                child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userList[post["uid"]]['username'],
                                    style:  TextStyle(
                                        fontSize: MediaQuery.of(context).size.width*0.05,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            )),
                            IconButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => Dialog(
                                      child: _uid != post['uid']
                                          ? ListView(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 16),
                                              shrinkWrap: true,
                                              children: [
                                                'Cancel',
                                              ]
                                                  .map(
                                                    (e) => InkWell(
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                      .symmetric(
                                                                  vertical: 12,
                                                                  horizontal:
                                                                      16),
                                                          child: Text(e),
                                                        ),
                                                        onTap: () {
                                                          // remove the dialog box
                                                          Navigator.of(context)
                                                              .pop();
                                                        }),
                                                  )
                                                  .toList())
                                          : ListView(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 16),
                                              shrinkWrap: true,
                                              children: [
                                                'Delete',
                                              ]
                                                  .map(
                                                    (e) => InkWell(
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                      .symmetric(
                                                                  vertical: 12,
                                                                  horizontal:
                                                                      16),
                                                          child: Text(e),
                                                        ),
                                                        onTap: () {
                                                          deletePost(
                                                              widget.postId);
                                                          // remove the dialog box
                                                          Navigator.of(context)
                                                              .pop();
                                                        }),
                                                  )
                                                  .toList()),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.more_vert)),
                          ],
                        ),
                      )),

                  //BODY POST - IMAGE
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.35,
                    width: double.infinity,
                    child: Image.network(
                      post['postImage'],
                      fit: BoxFit.cover,
                    ),
                  ),
                  //LIKE COMMENT
                  Row(
                    children: [
                      IconButton(
                        onPressed: () async {
                          if (isLiked) {
                            await FirebaseDatabase.instance
                                .ref("posts")
                                .child(widget.postId)
                                .child("likes")
                                .update({_uid: null});
                            setState(() {
                              isLiked = false;
                              countLike--;
                            });
                          } else {
                            await FirebaseDatabase.instance
                                .ref("posts")
                                .child(widget.postId)
                                .child("likes")
                                .update({_uid: true});

                            //send notification
                            final notifications = await FirebaseDatabase
                                .instance
                                .ref("users")
                                .child('${post["uid"]}')
                                .child("notifications");

                            notifications.push().set({
                              'uid': _uid,
                              'text': "like your post",
                              'datePublished':
                                  DateTime.now().millisecondsSinceEpoch
                            });
                            int unseenNotificationCount = 0;
                            if (userList[post['uid']]
                                    ['unseenNotificationCount'] !=
                                null) {
                              unseenNotificationCount = userList[post['uid']]
                                  ['unseenNotificationCount'];
                            }

                            await FirebaseDatabase.instance
                                .ref("users")
                                .child(post['uid'])
                                .update({
                              "unseenNotificationCount":
                                  unseenNotificationCount + 1
                            });
                            setState(() {
                              isLiked = true;
                              countLike++;
                              getData();
                            });
                          }
                        },
                        icon: isLiked
                            ? const Icon(
                                Icons.favorite,
                                color: Colors.red,
                              )
                            : const Icon(
                                Icons.favorite_border,
                              ),
                      ),
                      IconButton(
                          onPressed: () {
                            myFocusNode.requestFocus();
                          },
                          icon: const Icon(
                            Icons.comment_outlined,
                          )),
                      IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.send_outlined,
                          )),
                      Expanded(
                          child: Align(
                        alignment: Alignment.bottomRight,
                        child: IconButton(
                            icon: const Icon(Icons.bookmark_border),
                            onPressed: () {}),
                      ))
                    ],
                  ),

                  //DESCRIPTION AND COMMENT
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        DefaultTextStyle(
                            style: Theme.of(context)
                                .textTheme
                                .subtitle2!
                                .copyWith(fontWeight: FontWeight.w800),
                            child: Text(
                              countLike != 1 && countLike != 0
                                  ? '${countLike} likes'
                                  : '${countLike} like',
                              style: TextStyle(color: Theme.of(context).primaryColor, fontSize: MediaQuery.of(context).size.width*0.04),
                            )),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(
                            top: 8,
                          ),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: MediaQuery.of(context).size.width*0.04),
                              children: [
                                TextSpan(
                                  text: userList[post["uid"]]['username'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: " " + post["description"],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            Jiffy(DateTime.fromMillisecondsSinceEpoch(
                                    post['datePublished']))
                                .fromNow(),
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),

                        //Comment
                        StreamBuilder(
                          stream: FirebaseDatabase.instance
                              .ref('posts')
                              .child(widget.postId)
                              .child("comments")
                              .onValue,
                          builder: (context, snapshot) {
                            final commentList = <ListTile>[];
                            if (snapshot.hasData) {
                              DatabaseEvent comments =
                                  snapshot.data! as DatabaseEvent;
                              if (comments.snapshot.exists) {
                                final commentsData = Map<String, dynamic>.from(
                                    comments.snapshot.value
                                        as Map<dynamic, dynamic>);
                                var sortByValue =
                                    SplayTreeMap<String, dynamic>.from(
                                        commentsData,
                                        (key2, key1) => commentsData[key1]
                                                ['datePublished']
                                            .compareTo(commentsData[key2]
                                                ['datePublished']));
                                sortByValue.forEach((key, value) {
                                  final nextComment =
                                      Map<String, dynamic>.from(value);
                                  final commentTile = ListTile(
                                      title: InkWell(
                                    onTap: () {
                                      if (_uid == nextComment['uid']) {
                                        showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                                  backgroundColor:
                                                      Colors.redAccent,
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
                                                        await FirebaseDatabase
                                                            .instance
                                                            .ref("posts")
                                                            .child(
                                                                widget.postId)
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
                                          vertical: 16),
                                      child: Row(
                                        children: [
                                          InkWell(
                                            onTap: () =>
                                                Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ProfileScreen(
                                                  uid: nextComment['uid'],
                                                ),
                                              ),
                                            ),
                                            child: CircleAvatar(
                                              backgroundImage: NetworkImage(
                                                userList[nextComment["uid"]]
                                                    ['photoUrl'],
                                              ),
                                              radius: 18,
                                            ),
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 16),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  RichText(
                                                    text: TextSpan(
                                                      style: TextStyle(
                                                          color: Theme.of(context).primaryColor,
                                                          fontSize: MediaQuery.of(context).size.width*0.035),
                                                      children: [
                                                        TextSpan(
                                                            text: userList[
                                                                    nextComment[
                                                                        "uid"]]
                                                                ['username'],
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Theme.of(
                                                                        context)
                                                                    .primaryColor)),
                                                        TextSpan(
                                                            text: " " +
                                                                nextComment[
                                                                    'text'],
                                                            style: TextStyle(
                                                                color: Theme.of(
                                                                        context)
                                                                    .primaryColor)),
                                                      ],
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 4),
                                                    child: Text(
                                                      Jiffy(DateTime
                                                              .fromMillisecondsSinceEpoch(
                                                                  nextComment[
                                                                      'datePublished']))
                                                          .fromNow(),
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w500,
                                                        fontSize: MediaQuery.of(context).size.width*0.03,
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
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              children: commentList,
                            );
                          },
                        )
                      ],
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: kToolbarHeight,
          margin:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: isLoading
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : Row(
                  children: [
                    userList[_uid]['photoUrl'] == null
                        ? Center(
                            child: CircularProgressIndicator(),
                          )
                        : CircleAvatar(
                            backgroundImage:
                                NetworkImage(userList[_uid]['photoUrl']),
                            radius: 18,
                          ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 8),
                        child: TextField(
                          focusNode: myFocusNode,
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
