import 'dart:collection';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:instagram_clone/screens/chats_screen.dart';
import 'package:instagram_clone/screens/profile_screen.dart';
import 'package:instagram_clone/utils/colors.dart';
import 'package:jiffy/jiffy.dart';
import '../utils/utils.dart';
import 'comment_screen.dart';
import 'detail_post_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _uid = FirebaseAuth.instance.currentUser!.uid;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        title: SvgPicture.asset(
          'assets/ic_instagram.svg',
          color: primaryColor,
          height: 32,
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.messenger,
              color: primaryColor,
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ChatsScreen(),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref('likes/').onValue,
        builder: (context, snapshotlike) {
          return StreamBuilder(
            stream: FirebaseDatabase.instance.ref('posts/').onValue,
            builder: (context, snapshot) {
              final tileList = <ListTile>[];
              if (snapshot.hasData) {
                DatabaseEvent dataValues = snapshot.data! as DatabaseEvent;
                DatabaseEvent likeValues = snapshotlike.data! as DatabaseEvent;

                if (dataValues.snapshot.exists) {
                  final myPosts = Map<String, dynamic>.from(
                      dataValues.snapshot.value as Map<dynamic, dynamic>);

                  final likeOfPosts = Map<String, dynamic>.from(
                      likeValues.snapshot.value as Map<dynamic, dynamic>);

                  //sort by time
                  var sortByValue = new SplayTreeMap<String, dynamic>.from(
                      myPosts,
                      (key2, key1) => myPosts[key1]['datePublished']
                          .compareTo(myPosts[key2]['datePublished']));

                  sortByValue.forEach((key, value) {
                    int countLike = 0;
                    if (likeValues.snapshot.exists) {
                      countLike =
                          Map<String, dynamic>.from(likeOfPosts[key]).length -
                              1;
                    }

                    final nextPost = Map<String, dynamic>.from(value);
                    final postTile = ListTile(
                      title: Container(
                        color: mobileBackgroundColor,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8
                        ),
                        child: Column(
                          children: [
                            //HEADER POST
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8),
                              child: InkWell(
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ProfileScreen(
                                      uid: nextPost['uid'],
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: <Widget>[
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundImage:
                                          NetworkImage(nextPost['userImage']),
                                    ),
                                    Expanded(
                                        child: Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nextPost['username'],
                                            style: TextStyle(
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
                                              child: _uid != nextPost['uid']
                                                  ? ListView(
                                                      padding: const EdgeInsets
                                                              .symmetric(
                                                          vertical: 16),
                                                      shrinkWrap: true,
                                                      children: [
                                                        'Cancel',
                                                      ]
                                                          .map(
                                                            (e) => InkWell(
                                                                child:
                                                                    Container(
                                                                  padding: const EdgeInsets
                                                                          .symmetric(
                                                                      vertical:
                                                                          12,
                                                                      horizontal:
                                                                          16),
                                                                  child:
                                                                      Text(e),
                                                                ),
                                                                onTap: () {
                                                                  // remove the dialog box
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop();
                                                                }),
                                                          )
                                                          .toList())
                                                  : ListView(
                                                      padding: const EdgeInsets
                                                              .symmetric(
                                                          vertical: 16),
                                                      shrinkWrap: true,
                                                      children: [
                                                        'Delete',
                                                      ]
                                                          .map(
                                                            (e) => InkWell(
                                                                child:
                                                                    Container(
                                                                  padding: const EdgeInsets
                                                                          .symmetric(
                                                                      vertical:
                                                                          12,
                                                                      horizontal:
                                                                          16),
                                                                  child:
                                                                      Text(e),
                                                                ),
                                                                onTap: () {
                                                                  deletePost(
                                                                      key);
                                                                  // remove the dialog box
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop();
                                                                }),
                                                          )
                                                          .toList()),
                                            ),
                                          );
                                        },
                                        icon: Icon(Icons.more_vert)),
                                  ],
                                ),
                              ),
                            ),

                            //BODY POST - IMAGE
                            InkWell(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (context) => DetailPostScreen(
                                        postId: key,
                                        userPost: nextPost['uid'])),
                              ),
                              child: SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.35,
                                width: double.infinity,
                                child: Image.network(
                                  nextPost['postImage'],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            //LIKE COMMENT
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => likePost(key, _uid,
                                      likeOfPosts[key], nextPost['uid']),
                                  icon: likeOfPosts[key].containsKey(_uid)
                                      ? const Icon(
                                          Icons.favorite,
                                          color: Colors.red,
                                        )
                                      : const Icon(
                                          Icons.favorite_border,
                                        ),
                                ),
                                IconButton(
                                    onPressed: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => CommentScreen(
                                                postId: key,
                                                userPost: nextPost['uid']),
                                          ),
                                        ),
                                    icon: Icon(
                                      Icons.comment_outlined,
                                    )),
                                IconButton(
                                    onPressed: () {},
                                    icon: Icon(
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  DefaultTextStyle(
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle2!
                                          .copyWith(
                                              fontWeight: FontWeight.w800),
                                      child: Text(
                                        countLike != 1 && countLike != 0
                                            ?'${countLike} likes'
                                            :'${countLike} like',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyText2,
                                      )),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.only(
                                      top: 8,
                                    ),
                                    child: RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                            color: primaryColor),
                                        children: [
                                          TextSpan(
                                            text: nextPost["username"],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          TextSpan(
                                            text: " " + nextPost["description"],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    child: Container(
                                      child: Text(
                                        'View all ${nextPost['countCmt']} comments',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: secondaryColor,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4),
                                    ),
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => CommentScreen(
                                          postId: key,
                                          userPost: nextPost['uid'],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    child: Text(
                                      Jiffy(DateTime.fromMillisecondsSinceEpoch(
                                              nextPost['datePublished']))
                                          .fromNow(),
                                      style: const TextStyle(
                                        color: secondaryColor,
                                      ),
                                    ),
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                    tileList.add(postTile);
                  });
                } else {
                  final empty = ListTile(
                    title: Center(
                      child: Text("There are no posts yet"),
                    ),
                  );
                  tileList.add(empty);
                }
              }

              return ListView(
                children: tileList,
              );

            },
          );
        },
      ),
    );
  }

  void likePost(String postId, String uid, Map list, String userPost) async {
    final ref = await FirebaseDatabase.instance.ref('likes/');
    if (list.containsKey(uid)) {
      ref.child(postId).update({uid: null});
    } else {
      ref.child(postId).update({uid: true});
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
  }
}
