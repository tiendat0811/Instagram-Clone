import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../utils/colors.dart';
import '../utils/utils.dart';
import '../widgets/follow_button.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;

  const ProfileScreen({Key? key, required this.uid}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
      //get post length
      final postSnapshot = await ref
          .child("posts")
          .orderByChild("uid")
          .equalTo('${widget.uid}')
          .get();
      if (postSnapshot.exists) {
        final listPost = Map<String, dynamic>.from(
            postSnapshot.value as Map<dynamic, dynamic>);
        if (listPost.isNotEmpty) {
          postLen = listPost.length;
        }
      }

      //get followers
      final followerSnapshot =
      await ref.child('follow/followers/${widget.uid}').get();
      if (followerSnapshot.exists) {
        final followerData = Map<String, dynamic>.from(
            followerSnapshot.value as Map<dynamic, dynamic>);
        if (followerData.isNotEmpty) {
          //check following
          isFollowing = followerData.containsKey('${widget.uid}');
          followers = followerData.length;
        }
      }
      //get following
      final followingSnapshot =
      await ref.child('follow/followings/${widget.uid}').get();
      if (followingSnapshot.exists) {
        final followingData = Map<String, dynamic>.from(
            followingSnapshot.value as Map<dynamic, dynamic>);
        if (followingData.isNotEmpty) {
          //check following
          following = followingData.length;
        }
      }
      setState(() {});
    } catch (e) {
      showSnackBar(e.toString(), context);
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
                                    // await AuthMethods().signOut();
                                    // Navigator.of(context)
                                    //     .pushReplacement(
                                    //   MaterialPageRoute(
                                    //     builder: (context) =>
                                    //     const LoginScreen(),
                                    //   ),
                                    // );
                                  },
                                )
                                    : isFollowing
                                    ? FollowButton(
                                  text: 'Unfollow',
                                  backgroundColor: Colors.white,
                                  textColor: Colors.black,
                                  borderColor: Colors.grey,
                                  function: () async {
                                    // await FireStoreMethods()
                                    //     .followUser(
                                    //   FirebaseAuth.instance
                                    //       .currentUser!.uid,
                                    //   userData['uid'],
                                    // );
                                    //
                                    // setState(() {
                                    //   isFollowing = false;
                                    //   followers--;
                                    // });
                                  },
                                )
                                    : FollowButton(
                                  text: 'Follow',
                                  backgroundColor: Colors.blue,
                                  textColor: Colors.white,
                                  borderColor: Colors.blue,
                                  function: () async {
                                    // await FireStoreMethods()
                                    //     .followUser(
                                    //   FirebaseAuth.instance
                                    //       .currentUser!.uid,
                                    //   userData['uid'],
                                    // );
                                    //
                                    // setState(() {
                                    //   isFollowing = true;
                                    //   followers++;
                                    // });
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
                      myPosts.forEach((key, value) {
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
                return CircularProgressIndicator();
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
