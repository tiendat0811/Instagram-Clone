import 'dart:collection';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '/screens/follows_screen.dart';
import '/screens/inbox_screen.dart';

import '../widgets/follow_button.dart';
import 'detail_post_screen.dart';
import 'login_screen.dart';
import 'setting_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;

  const ProfileScreen({Key? key, required this.uid}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _uidCur = FirebaseAuth.instance.currentUser!.uid;
  var userData = {};
  var curUserData = {};
  int postLen = 0;
  int followers = 0;
  int followings = 0;
  bool isFollowing = false;
  bool isLoading = false;
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    getData();
  }

  getData() async {
    setState(() {
      isLoading = true;
    });
    try {
      //get user info
      final ref = FirebaseDatabase.instance.ref();
      final snapshot = await ref.child('users').child(widget.uid).get();
      final data =
          Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);

      userData = data;

      //get following
      if (userData['followings'] != null) {
        var followingData = Map<String, dynamic>.from(
            userData['followings'] as Map<dynamic, dynamic>);
        followings = followingData.length;
      } else {
        followings = 0;
      }

      //get followers
      if (userData['followers'] != null) {
        var followerData = Map<String, dynamic>.from(
            userData['followers'] as Map<dynamic, dynamic>);
        followers = followerData.length;
        if (followerData.containsKey(_uidCur)) {
          isFollowing = true;
        }
      } else {
        followers = 0;
      }

      final snapshotCur = await ref.child('users').child(_uidCur).get();
      final dataCur =
          Map<String, dynamic>.from(snapshotCur.value as Map<dynamic, dynamic>);
      if (data.isNotEmpty) {
        curUserData = dataCur;
      }

      final postSnapshot = await ref
          .child("posts")
          .orderByChild("uid")
          .equalTo(widget.uid)
          .get();
      if (postSnapshot.exists) {
        final listPost = Map<String, dynamic>.from(
            postSnapshot.value as Map<dynamic, dynamic>);
        if (listPost.isNotEmpty) {
          postLen = listPost.length;
        }
      }
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print(e.toString());
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : Scaffold(
            appBar: AppBar(
              iconTheme: IconThemeData(
                color: Theme.of(context).primaryColor,
              ),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: Text(
                userData['username'],
                style: TextStyle(
                  color: Theme.of(context).primaryColor
                ),
              ),
              actions: [
                widget.uid == _uidCur
                    ? IconButton(
                        icon: Icon(
                          Icons.settings,
                          color: Theme.of(context).primaryColor,
                        ),
                        // Ntluan - open
                        onPressed: () {
                          Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (context) => const SettingScreen(),
                                ),
                              )
                              .whenComplete(() => getData());
                        },
                        // Ntluan - close
                      )
                    : const Text("")
              ],
              centerTitle: false,
            ),
            body: ListView(
              shrinkWrap: true,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.grey,
                            backgroundImage: NetworkImage(
                              userData['photoUrl'],
                            ),
                            radius: 40,
                          ),
                          Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      buildStatColumn(postLen, "posts"),
                                      InkWell(
                                        onTap: () {
                                          Navigator.of(context)
                                              .push(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      FollowsScreen(
                                                          uid: widget.uid,
                                                          target: "followers"),
                                                ),
                                              )
                                              .whenComplete(() => getData());
                                        },
                                        child: buildStatColumn(
                                            followers, "followers"),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          Navigator.of(context)
                                              .push(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      FollowsScreen(
                                                          uid: widget.uid,
                                                          target: "followings"),
                                                ),
                                              )
                                              .whenComplete(() => getData());
                                        },
                                        child: buildStatColumn(
                                            followings, "following"),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      FirebaseAuth.instance.currentUser!.uid ==
                                              widget.uid
                                          ? FollowButton(
                                              text: 'Sign Out',
                                              backgroundColor: Theme.of(context)
                                                  .scaffoldBackgroundColor,
                                              textColor: Theme.of(context)
                                                  .primaryColor,
                                              borderColor: Colors.grey,
                                              function: () async {
                                                //logout google
                                                await GoogleSignIn().signOut();

                                                await FirebaseAuth.instance
                                                    .signOut();
                                                if (!mounted) return;
                                                Navigator.of(context).pushReplacement(
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        LoginScreen(),
                                                  ),
                                                );
                                              },
                                            )
                                          : isFollowing
                                              ? FollowButton(
                                                  text: 'Unfollow',
                                                  backgroundColor: Theme.of(
                                                          context)
                                                      .scaffoldBackgroundColor,
                                                  textColor: Theme.of(context)
                                                      .primaryColor,
                                                  borderColor: Colors.grey,
                                                  function: () async {
                                                    final targetUser =
                                                        await FirebaseDatabase
                                                            .instance
                                                            .ref("users")
                                                            .child(widget.uid)
                                                            .child("followers");
                                                    final currentUser =
                                                        await FirebaseDatabase
                                                            .instance
                                                            .ref("users")
                                                            .child(_uidCur)
                                                            .child(
                                                                "followings");

                                                    targetUser
                                                        .child(_uidCur)
                                                        .remove();

                                                    currentUser
                                                        .child(widget.uid)
                                                        .remove();

                                                    setState(() {
                                                      isFollowing = false;
                                                      followers--;
                                                    });
                                                  },
                                                  functionChat: () {
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            InboxScreen(
                                                                sender: _uidCur,
                                                                receiver:
                                                                    widget.uid),
                                                      ),
                                                    );
                                                  },
                                                )
                                              : FollowButton(
                                                  text: 'Follow',
                                                  backgroundColor: Colors.blue,
                                                  textColor: Colors.white,
                                                  borderColor: Colors.blue,
                                                  function: () async {
                                                    final targetUser =
                                                        await FirebaseDatabase
                                                            .instance
                                                            .ref("users")
                                                            .child(widget.uid)
                                                            .child("followers");

                                                    final currentUser =
                                                        await FirebaseDatabase
                                                            .instance
                                                            .ref("users")
                                                            .child(_uidCur)
                                                            .child(
                                                                "followings");

                                                    targetUser
                                                        .child(_uidCur)
                                                        .update({
                                                      'follow': true,
                                                    });

                                                    currentUser
                                                        .child(widget.uid)
                                                        .update({
                                                      'follow': true,
                                                    });

                                                    //first hello message
                                                    Map<String, dynamic>
                                                        chatInfo = {
                                                      'text':
                                                          "Hello i'm ${curUserData['username']}",
                                                      'sender': _uidCur,
                                                      'receiver': widget.uid,
                                                      'datePublished': DateTime
                                                              .now()
                                                          .millisecondsSinceEpoch,
                                                    };
                                                    DatabaseReference
                                                        refSender =
                                                        await FirebaseDatabase
                                                            .instance
                                                            .ref("users")
                                                            .child('${_uidCur}')
                                                            .child('chats')
                                                            .child(
                                                                '${widget.uid}');
                                                    await refSender.update({
                                                      "lastTime": DateTime.now()
                                                          .millisecondsSinceEpoch
                                                    });
                                                    final messId =
                                                        await refSender
                                                            .push()
                                                            .key;
                                                    refSender
                                                        .child(messId!)
                                                        .set(chatInfo);

                                                    DatabaseReference
                                                        refReceiver =
                                                        await FirebaseDatabase
                                                            .instance
                                                            .ref("users")
                                                            .child(
                                                                '${widget.uid}')
                                                            .child('chats')
                                                            .child(
                                                                '${_uidCur}');
                                                    await refReceiver.update({
                                                      "lastTime": DateTime.now()
                                                          .millisecondsSinceEpoch
                                                    });
                                                    refReceiver
                                                        .child(messId)
                                                        .set(chatInfo);

                                                    //send notifications
                                                    final notifications =
                                                        await FirebaseDatabase
                                                            .instance
                                                            .ref("users")
                                                            .child(widget.uid)
                                                            .child(
                                                                "notifications");
                                                    notifications.push().set({
                                                      'uid': _uidCur,
                                                      'text':
                                                          "started following you",
                                                      'datePublished': DateTime
                                                              .now()
                                                          .millisecondsSinceEpoch
                                                    });

                                                    //count++ unseen notifications
                                                    int unseenNotificationCount =
                                                        0;
                                                    if (userData[
                                                            'unseenNotificationCount'] !=
                                                        null) {
                                                      unseenNotificationCount =
                                                          userData[
                                                              'unseenNotificationCount'];
                                                    }
                                                    await FirebaseDatabase
                                                        .instance
                                                        .ref("users")
                                                        .child(widget.uid)
                                                        .update({
                                                      "unseenNotificationCount":
                                                          unseenNotificationCount +
                                                              1
                                                    });

                                                    setState(() {
                                                      isFollowing = true;
                                                      followers++;
                                                      getData();
                                                    });
                                                  },
                                                )
                                    ],
                                  )
                                ],
                              ))
                        ],
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(
                          top: 15,
                        ),
                        child: Text(
                          userData['fullname'],
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width*0.045,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(
                          top: 1,
                        ),
                        child: Text(
                          userData['bio'],
                          style: TextStyle(fontSize: MediaQuery.of(context).size.width*0.04,),
                        ),
                      ),
                    ],
                  ),
                ),
                StreamBuilder(
                    stream: FirebaseDatabase.instance
                        .ref()
                        .child("posts")
                        .orderByChild("uid")
                        .equalTo('${widget.uid}')
                        .onValue,
                    builder: (context, snapshot) {
                      final tileList = <Widget>[];
                      if (snapshot.hasData) {
                        DatabaseEvent dataValues =
                            snapshot.data! as DatabaseEvent;
                        if (dataValues.snapshot.exists) {
                          final myPosts = Map<String, dynamic>.from(dataValues
                              .snapshot.value as Map<dynamic, dynamic>);
                          if (myPosts.isNotEmpty) {
                            var sortByValue =
                                new SplayTreeMap<String, dynamic>.from(
                                    myPosts,
                                    (key2, key1) => myPosts[key1]
                                            ['datePublished']
                                        .compareTo(
                                            myPosts[key2]['datePublished']));
                            sortByValue.forEach((key, value) {
                              final nextPost = Map<String, dynamic>.from(value);
                              final post = Container(
                                padding: const EdgeInsets.all(2),
                                child: nextPost['postImage'] != null
                                    ? InkWell(
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  DetailPostScreen(
                                                      postId: key)),
                                        ),
                                        child: Image(
                                          image: NetworkImage(
                                              nextPost['postImage']),
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const CircularProgressIndicator(),
                              );
                              tileList.add(post);
                            });
                          }
                          return Container(
                            decoration: BoxDecoration(
                                border: Border(top: BorderSide(width: 2.0,color: Theme.of(context).primaryColor))
                            ),
                            child: GridView.count(
                              shrinkWrap: true,
                              physics: const ScrollPhysics(),
                              padding: const EdgeInsets.all(5),
                              mainAxisSpacing: 2,
                              crossAxisSpacing: 2,
                              crossAxisCount: 3,
                              children: tileList,
                            )
                          );
                        }
                      }
                      return const Text("");
                    }),
              ],
            ),
          );
  }

  Column buildStatColumn(int num, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          num.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}
