import 'dart:collection';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone/screens/profile_screen.dart';

import 'package:instagram_clone/utils/colors.dart';
import 'package:instagram_clone/utils/utils.dart';
import 'package:jiffy/jiffy.dart';

class DetailPostScreen extends StatefulWidget {
  final postId, userPost;

  const DetailPostScreen(
      {Key? key, required this.postId, required this.userPost})
      : super(key: key);

  @override
  State<DetailPostScreen> createState() => _DetailPostScreenState();
}

class _DetailPostScreenState extends State<DetailPostScreen> {
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController commentEditingController =
      TextEditingController();
  var post = {};
  var userInfo = {};
  bool isLoading = false;
  late FocusNode myFocusNode;
  bool liked = false;
  int countLike = 0;

  void getUser() async {
    setState(() {
      isLoading = true;
    });
    String uid = await FirebaseAuth.instance.currentUser!.uid;
    final snapshot =
        await FirebaseDatabase.instance.ref().child('users/$uid').get();
    if (snapshot.exists) {
      final data =
          Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
      userInfo = data;
      setState(() {});
    } else {
      print('No data available.');
    }
    setState(() {
      isLoading = false;
    });
  }

  void getPost() async {
    setState(() {
      isLoading = true;
    });
    final ref = FirebaseDatabase.instance.ref();
    final postSnapshot = await ref.child('posts/${widget.postId}').get();
    if (postSnapshot.exists) {
      final data =
          Map<String, dynamic>.from(postSnapshot.value as Map<dynamic, dynamic>);
      post = data;
      setState(() {});
    } else {
      print('No data available.');
    }

    //get like info
    final likeSnapshot = await ref.child('likes/${widget.postId}').get();
    if (likeSnapshot.exists) {
      final data =
      Map<String, dynamic>.from(likeSnapshot.value as Map<dynamic, dynamic>);
      if(data.containsKey(_uid)){
        liked = true;
      }
      countLike = data.length - 1;
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
    getPost();
    getUser();
    myFocusNode = FocusNode();
  }

  @override
  void dispose() {
    myFocusNode.dispose();
    super.dispose();
  }

  void likePost(String key, String uid, String userPost) async {
    final ref = await FirebaseDatabase.instance.ref('likes/');

    final likeSnapshot = await ref.child(widget.postId).get();
    final list = Map<String, dynamic>.from(likeSnapshot.value as Map<dynamic, dynamic>);
    if (list.containsKey(uid)) {
      ref.child(key).update({uid: null});
      liked = false;
      countLike --;
    } else {
      ref.child(key).update({uid: true});
      liked = true;
      countLike ++;
      final snapshot =
          await FirebaseDatabase.instance.ref().child('users').child(uid).get();
      final data =
          Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
      final notifications =
          FirebaseDatabase.instance.ref("notifications").child('${userPost}');
      notifications.push().set({
        'username': data['name'],
        'userImg': data['photoUrl'],
        'text': "liked on your post",
        'datePublished': DateTime.now().millisecondsSinceEpoch
      });
    }
    setState(() {

    });
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
          .ref("comments/${widget.postId}/")
          .push();
      Map<String, dynamic> cmtInfo = {
        'text': commentEditingController.text,
        'username': userInfo["username"],
        'userImage': userInfo["photoUrl"],
        'datePublished': DateTime.now().millisecondsSinceEpoch,
        'uid': _uid
      };
      ref.set(cmtInfo);
      res = 'success';

      final snapshot =
          await FirebaseDatabase.instance.ref("posts/${widget.postId}/").get();
      if (snapshot.exists) {
        final data =
            Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
        int count = data['countCmt'];
        count++;
        await FirebaseDatabase.instance
            .ref("posts/${widget.postId}/")
            .update({'countCmt': count});
      }

      //notification
      final notifications = await FirebaseDatabase.instance
          .ref("notifications")
          .child('${widget.userPost}');
      notifications.push().set({
        'username': userInfo['name'],
        'userImg': userInfo['photoUrl'],
        'text': "commented on your post",
        'datePublished': DateTime.now().millisecondsSinceEpoch
      });

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
        title: const Text('Post'),
        centerTitle: false,
      ),
      body: Container(
        color: mobileBackgroundColor,
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
                              radius: 16,
                              backgroundImage: NetworkImage(post['userImage']),
                            ),
                            Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        post['username'],
                                        style: const TextStyle(
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
                                          padding: const EdgeInsets.symmetric(
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
                                                      horizontal: 16),
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
                                          padding: const EdgeInsets.symmetric(
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
                                                      horizontal: 16),
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
                      )
                  ),

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
                        onPressed: () => likePost(widget.postId, _uid, post['uid']),
                        icon: liked
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
                              ?'${countLike} likes'
                              :'${countLike} like',
                              style: Theme.of(context).textTheme.bodyText2,
                            )
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(
                            top: 8,
                          ),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(color: primaryColor),
                              children: [
                                TextSpan(
                                  text: post["username"],
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
                            style: const TextStyle(
                              color: secondaryColor,
                            ),
                          ),
                        ),
                        StreamBuilder(
                          stream: FirebaseDatabase.instance
                              .ref('comments/${widget.postId}')
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
                                    SplayTreeMap<String, dynamic>.from(commentsData,
                                        (key2, key1) => commentsData[key1]
                                                ['datePublished']
                                            .compareTo(commentsData[key2]
                                                ['datePublished']));
                                sortByValue.forEach((key, value) {
                                  final nextComment =
                                      Map<String, dynamic>.from(value);
                                  final commentTile = ListTile(
                                    title: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
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
                                                nextComment['userImage'],
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
                                                      children: [
                                                        TextSpan(
                                                            text: nextComment[
                                                                'username'],
                                                            style:
                                                                const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            )),
                                                        TextSpan(
                                                          text: " " +
                                                              nextComment[
                                                                  'text'],
                                                        ),
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
          child: Row(
            children: [
              userInfo['photoUrl'] == null
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : CircleAvatar(
                      backgroundImage: NetworkImage(userInfo['photoUrl']),
                      radius: 18,
                    ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: TextField(
                    focusNode: myFocusNode,
                    controller: commentEditingController,
                    decoration: InputDecoration(
                      hintText: 'Comment as ${userInfo['username']}',
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
