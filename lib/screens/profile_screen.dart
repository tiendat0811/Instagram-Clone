import 'dart:collection';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone/screens/inbox_screen.dart';

import '../utils/colors.dart';
import '../widgets/follow_button.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;

  const ProfileScreen({Key? key, required this.uid}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _uidCur= FirebaseAuth.instance.currentUser!.uid;
  var userData = {};
  int postLen = 0;
  int followers = 0;
  int following = 0;
  bool isFollowing = false;
  bool isLoading = false;

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
      final snapshot = await ref.child('users').child('${widget.uid}').get();
      final data =
      Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
      if (data.isNotEmpty) {
        userData = data;
      }
      //get followers
      final followerSnapshot =
      await ref.child('follow').child('followers').child(widget.uid).get();
      if (followerSnapshot.exists) {
        final followerData = Map<String, dynamic>.from(
            followerSnapshot.value as Map<dynamic, dynamic>);
        if (followerData.isNotEmpty) {
          //check following
          isFollowing = followerData.containsKey(_uidCur);
          followers = followerData.length;
        }
      }
      //get following
      final followingSnapshot = await ref.child('follow').child('followings').child(widget.uid).get();
      if (followingSnapshot.exists) {
        final followingData = Map<String, dynamic>.from(
            followingSnapshot.value as Map<dynamic, dynamic>);
        if (followingData.isNotEmpty) {
          //check following
          following = followingData.length;
        }
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
      setState(() {});
    } catch (e) {
      print("");
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(
      child: CircularProgressIndicator(),
    )
        : Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        title: Text(
          userData['username'],
        ),
        centerTitle: false,
      ),
      body: ListView(
        shrinkWrap: true,
        children: [
          Padding(padding: const EdgeInsets.all(16),
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
                                buildStatColumn(followers, "followers"),
                                buildStatColumn(following, "following"),
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
                                  backgroundColor:
                                  mobileBackgroundColor,
                                  textColor: primaryColor,
                                  borderColor: Colors.grey,
                                  function: () async {
                                    await FirebaseAuth.instance.signOut();
                                    Navigator.of(context)
                                        .pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                        const LoginScreen(),
                                      ),
                                    );
                                  },
                                )
                                    : isFollowing
                                    ? FollowButton(
                                  text: 'Unfollow',
                                  backgroundColor: Colors.white,
                                  textColor: Colors.black,
                                  borderColor: Colors.grey,
                                  function: () async {
                                    final refFollower = await FirebaseDatabase.instance.ref("follow").child("followers").child('${widget.uid}');
                                    final refFollowing = await FirebaseDatabase.instance.ref("follow").child("followings").child(_uidCur);

                                    refFollower.update({
                                      _uidCur: null
                                    });

                                    refFollowing.update({
                                      widget.uid: null
                                    });

                                    setState(() {
                                      isFollowing = false;
                                      followers--;
                                    });
                                  },
                                  functionChat: ()  {
                                    Navigator.of(context)
                                        .push(
                                      MaterialPageRoute(
                                        builder: (context) => InboxScreen(sender: _uidCur, receiver: widget.uid),
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
                                    final refFollower = await FirebaseDatabase.instance.ref("follow").child("followers").child(widget.uid);
                                    final refFollowing = await FirebaseDatabase.instance.ref("follow").child("followings").child(_uidCur);

                                    //create chat
                                    String keyChat = "";
                                    final isHasKey = await FirebaseDatabase.instance.ref("follow").child("followers").child(_uidCur).get();
                                    if(isHasKey.exists){
                                      final checkKey =
                                      Map<String, dynamic>.from(isHasKey.value as Map<dynamic, dynamic>);
                                      print(checkKey);
                                      keyChat = checkKey[widget.uid];
                                    }else{
                                     keyChat = await FirebaseDatabase.instance.ref().child('chats').push().key.toString();
                                    }

                                    refFollower.update({
                                      _uidCur: keyChat
                                    });

                                    refFollowing.update({
                                      widget.uid: keyChat
                                    });

                                    await FirebaseDatabase.instance.ref().child('users').child(_uidCur).child("chatHistory").update({keyChat : true});
                                    await FirebaseDatabase.instance.ref().child('users').child(widget.uid).child("chatHistory").update({keyChat : true});
                                    setState(() {
                                      isFollowing = true;
                                      followers++;
                                    });

                                    //notifications
                                    final snapshot = await FirebaseDatabase.instance.ref().child('users').child(_uidCur).get();
                                    final data =
                                    Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
                                    final notifications = await FirebaseDatabase.instance.ref("notifications").child('${widget.uid}');
                                    notifications.push().set({
                                        'username': data['username'],
                                        'userImg': data['photoUrl'],
                                        'text' : "started following you",
                                        'datePublished' : DateTime.now().millisecondsSinceEpoch
                                    });
                                  },
                                )
                              ],
                            )
                          ],
                        )
                    )
                  ],
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(
                    top: 15,
                  ),
                  child: Text(
                    userData['username'],
                    style: TextStyle(
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
                  ),
                ),
              ],
            ),
          ),
          StreamBuilder(
              stream:FirebaseDatabase.instance.ref().child("posts")
        .orderByChild("uid")
        .equalTo('${widget.uid}').onValue,
              builder: (context, snapshot) {
                final tileList = <Widget>[];
                if (snapshot.hasData) {
                  DatabaseEvent dataValues = snapshot.data! as DatabaseEvent;
                  if (dataValues.snapshot.exists) {
                    final myPosts = Map<String, dynamic>.from(
                        dataValues.snapshot.value as Map<dynamic, dynamic>);
                    if (myPosts.isNotEmpty) {
                      var sortByValue = new SplayTreeMap<String, dynamic>.from(
                          myPosts,
                              (key2, key1) => myPosts[key1]['datePublished']
                              .compareTo(myPosts[key2]['datePublished']));
                      sortByValue.forEach((key, value) {
                        final nextPost = Map<String, dynamic>.from(value);
                        final post = Container(
                          padding: const EdgeInsets.all(2),
                          child: nextPost['postImage'] != null
                              ? Image(image: NetworkImage(nextPost['postImage']),fit: BoxFit.cover,)
                              : CircularProgressIndicator(),
                        );
                        tileList.add(post);
                      });
                    }
                    return GridView.count(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(5),
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 2,
                      crossAxisCount: 3,
                      children: tileList,
                    );
                  }
                }
                return Text("");
              }
          ),
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
