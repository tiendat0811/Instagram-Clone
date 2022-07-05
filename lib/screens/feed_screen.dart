import 'dart:collection';
import 'package:badges/badges.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_switch/flutter_switch.dart';
import '/screens/chats_screen.dart';
import '/screens/profile_screen.dart';
import '/utils/themes.dart';
import 'package:jiffy/jiffy.dart';
import 'package:provider/provider.dart';
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
  var userData = {};

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
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          automaticallyImplyLeading: false,
          title: SvgPicture.asset(
            'assets/ic_instagram.svg',
            color: Theme.of(context).primaryColor,
            height: 32,
          ),
          actions: [
            //dark mode
            FlutterSwitch(
                inactiveSwitchBorder: Border.all(width: 2, color:Theme.of(context).primaryColor,),
                activeSwitchBorder: Border.all(width: 2, color:Theme.of(context).primaryColor,),
                inactiveColor: Theme.of(context).scaffoldBackgroundColor,
                activeColor: Theme.of(context).scaffoldBackgroundColor,
                toggleColor: Theme.of(context).scaffoldBackgroundColor,
                activeToggleColor: Theme.of(context).scaffoldBackgroundColor,
                activeToggleBorder: Border.all(width: 1, color:Theme.of(context).primaryColor,),
                inactiveToggleBorder: Border.all(width: 1, color:Theme.of(context).primaryColor,),
                inactiveIcon: Icon(
                  CupertinoIcons.sun_max_fill,
                  color: Theme.of(context).primaryColor,
                ),
                activeIcon: Icon(
                  CupertinoIcons.moon_fill,
                  color: Theme.of(context).primaryColor,
                ),
                value: themeProvider.isDarkMode,
                onToggle: (value) {
                  final provider =
                      Provider.of<ThemeProvider>(context, listen: false);
                  provider.toggleTheme(value);
                }),

            StreamBuilder(
              stream:
                  FirebaseDatabase.instance.ref('users').child(_uid).onValue,
              builder: (context, snapshot) {
                int unseenMessageCount = 0;
                if (snapshot.hasData) {
                  DatabaseEvent dataValues = snapshot.data! as DatabaseEvent;
                  if (dataValues.snapshot.exists) {
                    final snapshotData = Map<String, dynamic>.from(
                        dataValues.snapshot.value as Map<dynamic, dynamic>);

                    if (snapshotData['unseenMessageCount'] != null) {
                      unseenMessageCount = snapshotData['unseenMessageCount'];
                    }
                    userData = snapshotData;
                  }
                }
                return IconButton(
                  padding: EdgeInsets.only(right: 20, left: 30),
                    icon: Badge(
                      showBadge: unseenMessageCount != 0 ? true : false,
                      badgeContent: Text("$unseenMessageCount"),
                      child: Icon(
                        Icons.question_answer_outlined,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    onPressed: () async {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ChatsScreen(),
                        ),
                      );
                    });
              },
            )
          ],
        ),
        body: StreamBuilder(
            stream: FirebaseDatabase.instance.ref('users').onValue,
            builder: (context, userSnapshot) {
              return StreamBuilder(
                stream: FirebaseDatabase.instance.ref('posts').onValue,
                builder: (context, snapshot) {
                  final tileList = <ListTile>[];
                  if (userSnapshot.hasData) {
                    if (snapshot.hasData) {
                      DatabaseEvent postValues =
                          snapshot.data! as DatabaseEvent;
                      DatabaseEvent userValues =
                          userSnapshot.data! as DatabaseEvent;
                      final userList = Map<String, dynamic>.from(
                          userValues.snapshot.value as Map<dynamic, dynamic>);
                      if (postValues.snapshot.exists) {
                        final myPosts = Map<String, dynamic>.from(
                            postValues.snapshot.value as Map<dynamic, dynamic>);

                        //sort by time
                        var sortByValue =
                            new SplayTreeMap<String, dynamic>.from(
                                myPosts,
                                (key2, key1) => myPosts[key1]['datePublished']
                                    .compareTo(myPosts[key2]['datePublished']));

                        sortByValue.forEach((key, value) {
                          final nextPost = Map<String, dynamic>.from(value);
                          var countLike = 0;
                          var countCmt = 0;
                          var isLiked = false;
                          if (nextPost['likes'] != null) {
                            var likesData =
                                Map<String, dynamic>.from(nextPost['likes']);

                            countLike = likesData.length;
                            if (likesData.containsKey(_uid)) {
                              isLiked = true;
                            }
                          }

                          if (nextPost['comments'] != null) {
                            var commentsData =
                                Map<String, dynamic>.from(nextPost['comments']);

                            countCmt = commentsData.length;
                          }

                          final postTile = ListTile(
                            title: Container(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                children: [
                                  //HEADER POST
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
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
                                            radius: MediaQuery.of(context).size.width*0.05,
                                            backgroundImage: NetworkImage(
                                                userList[nextPost["uid"]]
                                                    ['photoUrl']),
                                          ),
                                          Expanded(
                                              child: Padding(
                                            padding:
                                                const EdgeInsets.only(left: 8),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  userList[nextPost["uid"]]
                                                      ['username'],
                                                  style: TextStyle(
                                                    fontSize: MediaQuery.of(context).size.width*0.04,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          )),
                                          IconButton(
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => Dialog(
                                                    child: _uid !=
                                                            nextPost['uid']
                                                        ? ListView(
                                                            padding:
                                                                const EdgeInsets
                                                                        .symmetric(
                                                                    vertical:
                                                                        16),
                                                            shrinkWrap: true,
                                                            children: [
                                                              'Cancel',
                                                            ]
                                                                .map(
                                                                  (e) => InkWell(
                                                                      child: Container(
                                                                        padding: const EdgeInsets.symmetric(
                                                                            vertical:
                                                                                12,
                                                                            horizontal:
                                                                                16),
                                                                        child:
                                                                            Text(e),
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
                                                                const EdgeInsets
                                                                        .symmetric(
                                                                    vertical:
                                                                        16),
                                                            shrinkWrap: true,
                                                            children:
                                                                [
                                                              'Delete',
                                                              'Edit',
                                                              'Cancel'
                                                            ]
                                                                    .map(
                                                                      (e) => InkWell(
                                                                          child: Container(
                                                                            padding:
                                                                                const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                                                            child:
                                                                                Text(e),
                                                                          ),
                                                                          onTap: () {
                                                                            if (e.toString() ==
                                                                                "Delete") {
                                                                              deletePost(key);

                                                                              // remove the dialog box
                                                                              Navigator.of(context).pop();
                                                                            } else if (e.toString() ==
                                                                                "Edit") {
                                                                              final TextEditingController _descriptionController = TextEditingController();

                                                                              Navigator.of(context).pop();
                                                                              showDialog(
                                                                                  context: context,
                                                                                  builder: (ctx) => AlertDialog(
                                                                                        backgroundColor: Colors.blueGrey,
                                                                                        title: Text("Edit caption"),
                                                                                        content: SizedBox(
                                                                                          width: MediaQuery.of(context).size.width * 0.3,
                                                                                          child: TextField(
                                                                                            controller: _descriptionController,
                                                                                            decoration: InputDecoration(hintText: nextPost["description"], border: InputBorder.none),
                                                                                            maxLines: 8,
                                                                                          ),
                                                                                        ),
                                                                                        actions: <Widget>[
                                                                                          FlatButton(
                                                                                            onPressed: () {
                                                                                              Navigator.of(ctx).pop();
                                                                                            },
                                                                                            child: Text("Cancel"),
                                                                                          ),
                                                                                          FlatButton(
                                                                                            onPressed: () async {
                                                                                              await FirebaseDatabase.instance.ref("posts").child(key).update({
                                                                                                "description": _descriptionController.text.trim()
                                                                                              });
                                                                                              Navigator.of(ctx).pop();
                                                                                            },
                                                                                            child: Text("Ok"),
                                                                                          ),
                                                                                        ],
                                                                                      )); // remove the dialog box
                                                                            } else {
                                                                              // remove the dialog box
                                                                              Navigator.of(context).pop();
                                                                            }
                                                                          }),
                                                                    )
                                                                    .toList()),
                                                  ),
                                                );
                                              },
                                              icon: Icon(
                                                Icons.more_vert,
                                                color: Theme.of(context)
                                                    .primaryColor,
                                              )),
                                        ],
                                      ),
                                    ),
                                  ),

                                  //BODY POST - IMAGE
                                  InkWell(
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              DetailPostScreen(postId: key)),
                                    ),
                                    child: SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.35,
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
                                        onPressed: () async {
                                          if (isLiked) {
                                            await FirebaseDatabase.instance
                                                .ref("posts")
                                                .child(key)
                                                .child("likes")
                                                .update({_uid: null});
                                          } else {
                                            await FirebaseDatabase.instance
                                                .ref("posts")
                                                .child(key)
                                                .child("likes")
                                                .update({_uid: true});

                                            //send notification
                                            final notifications =
                                                FirebaseDatabase.instance
                                                    .ref("users")
                                                    .child(nextPost['uid'])
                                                    .child('notifications');
                                            notifications.push().set({
                                              'uid': _uid,
                                              'text': "liked on your post",
                                              'datePublished': DateTime.now()
                                                  .millisecondsSinceEpoch
                                            });

                                            int unseenNotificationCount = 0;
                                            if (userList[nextPost['uid']][
                                                    'unseenNotificationCount'] !=
                                                null) {
                                              unseenNotificationCount = userList[
                                                      nextPost['uid']]
                                                  ['unseenNotificationCount'];
                                            }
                                            await FirebaseDatabase.instance
                                                .ref("users")
                                                .child(nextPost['uid'])
                                                .update({
                                              "unseenNotificationCount":
                                                  unseenNotificationCount + 1
                                            });
                                          }
                                        },
                                        icon: isLiked
                                            ? Icon(
                                                Icons.favorite,
                                                color: Colors.red,
                                              )
                                            : Icon(
                                                Icons.favorite_border,
                                                color: Theme.of(context)
                                                    .iconTheme
                                                    .color,
                                              ),
                                      ),
                                      IconButton(
                                          onPressed: () =>
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      CommentScreen(
                                                          postId: key),
                                                ),
                                              ),
                                          icon: Icon(
                                            Icons.comment_outlined,
                                            color:
                                                Theme.of(context).primaryColor,
                                          )),
                                      IconButton(
                                          onPressed: () {},
                                          icon: Icon(
                                            Icons.send_outlined,
                                            color:
                                                Theme.of(context).primaryColor,
                                          )),
                                      Expanded(
                                          child: Align(
                                        alignment: Alignment.bottomRight,
                                        child: IconButton(
                                            icon: Icon(
                                              Icons.bookmark_border,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            ),
                                            onPressed: () {}),
                                      ))
                                    ],
                                  ),

                                  //DESCRIPTION AND COMMENT
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        DefaultTextStyle(
                                            style: Theme.of(context)
                                                .textTheme
                                                .subtitle2!
                                                .copyWith(
                                                    fontWeight:
                                                        FontWeight.w800),
                                            child: Text(
                                              countLike != 1 && countLike != 0
                                                  ? '${countLike} likes'
                                                  : '${countLike} like',
                                              style: TextStyle(fontWeight: FontWeight.normal, fontSize: MediaQuery.of(context).size.width*0.035,),
                                            )),
                                        Container(
                                          width: double.infinity,
                                          padding: EdgeInsets.only(
                                            top: MediaQuery.of(context).size.width*0.004,
                                          ),
                                          child: RichText(
                                            text: TextSpan(
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .primaryColor, fontSize: MediaQuery.of(context).size.width*0.04,),
                                              children: [
                                                TextSpan(
                                                  text:
                                                      userList[nextPost["uid"]]
                                                          ['username'],
                                                  style: TextStyle(

                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: " " +
                                                      nextPost["description"],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          child: Container(
                                            padding: EdgeInsets.only(
                                                top: MediaQuery.of(context).size.width*0.004,),
                                            child: Text(
                                              'View all $countCmt comments',
                                              style: TextStyle(
                                                  fontSize: MediaQuery.of(context).size.width*0.04,
                                                color: Color.fromRGBO(
                                                    132, 132, 132, 1.0),
                                              ),
                                            ),
                                          ),
                                          onTap: () =>
                                              Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CommentScreen(postId: key),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.only(
                                            top: MediaQuery.of(context).size.width*0.004,),
                                          child: Text(
                                            Jiffy(DateTime
                                                    .fromMillisecondsSinceEpoch(
                                                        nextPost[
                                                            'datePublished']))
                                                .fromNow(),
                                            style: TextStyle(
                                              fontSize: MediaQuery.of(context).size.width*0.035,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            ),
                                          ),
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
                  }
                  return ListView(
                    children: tileList,
                  );
                },
              );
            }));
  }
}
