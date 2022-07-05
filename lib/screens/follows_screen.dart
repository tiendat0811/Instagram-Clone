import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '/screens/profile_screen.dart';
import '/widgets/follow_button.dart';

class FollowsScreen extends StatefulWidget {
  final String uid, target;

  const FollowsScreen({Key? key, required this.uid, required this.target})
      : super(key: key);

  @override
  _FollowsScreenState createState() => _FollowsScreenState();
}

class _FollowsScreenState extends State<FollowsScreen> {
  bool isLoading = false;
  var followers = {};
  var followings = {};
  var userData = {};
  final _uidCur = FirebaseAuth.instance.currentUser!.uid;
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
      if (data.isNotEmpty) {
        userData = data;
      }

      if (userData['followers'] != null) {
        followers = Map<String, dynamic>.from(
            userData['followers']
            as Map<dynamic, dynamic>);
      }

      if (userData['followings'] != null) {
        followings = Map<String, dynamic>.from(
            userData['followings']
            as Map<dynamic, dynamic>);
      }
      setState(() {});
    } catch (e) {
      print(e.toString());
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
              iconTheme: IconThemeData(
                color: Theme.of(context).primaryColor,
              ),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: Text(userData["username"], style: TextStyle(color: Theme.of(context).primaryColor),),
            ),
            body: StreamBuilder(
              stream: FirebaseDatabase.instance.ref("users").onValue,
              builder: (context, snapshot) {
                final userList = <ListTile>[];
                if (snapshot.hasData) {
                  DatabaseEvent users = snapshot.data! as DatabaseEvent;
                  if (users.snapshot.exists) {
                    final usersData = Map<String, dynamic>.from(
                        users.snapshot.value as Map<dynamic, dynamic>);

                    if (widget.target == 'followings') {
                      followings.forEach((key, value) {
                        var isFollow =
                            Map<String, dynamic>.from(value)['follow'];
                        final userTile = ListTile(
                            title: Container(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ProfileScreen(
                                      uid: key,
                                    ),
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 32,
                                  backgroundImage:
                                  NetworkImage(usersData[key]['photoUrl']),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    usersData[key]['username'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              _uidCur != widget.uid
                              ? Text("")
                              :
                              !isFollow
                                  ? FollowButton(
                                      backgroundColor: Colors.blue,
                                      borderColor: Colors.blue,
                                      text: "Follow",
                                      textColor: Colors.white,
                                      function: () async {
                                        await FirebaseDatabase.instance.ref("users")
                                            .child(_uidCur)
                                            .child("followings")
                                            .child(key)
                                            .set({"follow":true});

                                        await FirebaseDatabase.instance.ref("users")
                                            .child(key)
                                            .child("followers")
                                            .child(_uidCur)
                                            .set({"follow":true});

                                        //send notifications
                                        final notifications =
                                        await FirebaseDatabase
                                            .instance
                                            .ref("users")
                                            .child(key)
                                            .child("notifications");
                                        notifications.push().set({
                                          'uid': _uidCur,
                                          'text':
                                          "started following you",
                                          'datePublished': DateTime
                                              .now()
                                              .millisecondsSinceEpoch
                                        });

                                        //count++ unseen notifications
                                        int unseenNotificationCount = 0;
                                        if(usersData[key]['unseenNotificationCount']!=null){
                                          unseenNotificationCount = usersData[key]['unseenNotificationCount'];
                                        }
                                        await FirebaseDatabase.instance
                                            .ref("users")
                                            .child(key)
                                            .update({
                                          "unseenNotificationCount" : unseenNotificationCount+1
                                        });

                                        setState(() {
                                          followings[key]['follow'] = true;
                                        });
                                      },
                                    )
                                  : FollowButton(
                                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                                    borderColor: Colors.grey,
                                    text: " Following ",
                                    textColor: Theme.of(context).primaryColor,
                                    function: () async {

                                      await FirebaseDatabase.instance.ref("users")
                                          .child(_uidCur)
                                          .child("followings")
                                          .child(key)
                                          .remove();

                                      await FirebaseDatabase.instance.ref("users")
                                          .child(key)
                                          .child("followers")
                                          .child(_uidCur)
                                          .remove();

                                      setState(() {
                                        followings[key]['follow'] = false;
                                      });
                                    },
                                  )
                            ],
                          ),
                        ));
                        userList.add(userTile);
                      });
                    }
                    else{
                      {
                        followers.forEach((key, value) {
                          // var isFollow =
                          // Map<String, dynamic>.from(value)['follow'];
                          final userTile = ListTile(
                              title: Container(
                                padding: EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    InkWell(
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => ProfileScreen(
                                            uid: key,
                                          ),
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 32,
                                        backgroundImage:
                                        NetworkImage(usersData[key]['photoUrl']),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8),
                                        child: Text(
                                          usersData[key]['username'],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style:
                                          TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    _uidCur != widget.uid
                                    ? Text("")
                                    : FollowButton(
                                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                                      borderColor: Colors.grey,
                                      text: "Delete",
                                      textColor: Theme.of(context).primaryColor,
                                      function: () async {
                                        showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              backgroundColor: Colors.redAccent,
                                          title: Text("Delete this follower?"),
                                          content: Text("We won't let ${usersData[key]['username']} know that you removed them from your follower list"),
                                          actions: <Widget>[
                                            FlatButton(
                                              onPressed: () {
                                                Navigator.of(ctx).pop();
                                              },
                                              child: Text("Cancel"),
                                            ),
                                            FlatButton(
                                              onPressed: () async {
                                                await FirebaseDatabase.instance.ref("users")
                                                    .child(_uidCur)
                                                    .child("followers")
                                                    .child(key)
                                                    .remove();

                                                await FirebaseDatabase.instance.ref("users")
                                                    .child(key)
                                                    .child("followings")
                                                    .child(_uidCur)
                                                    .remove();
                                                followers.removeWhere((key, value) => key == key);
                                                setState(() {
                                                });
                                                Navigator.of(ctx).pop();
                                              },
                                              child: Text("Ok"),
                                            ),
                                          ],
                                        ));
                                      },
                                    )
                                  ],
                                ),
                              ));
                          userList.add(userTile);
                        });
                      }
                    }
                  }
                }

                return ListView(
                  padding: EdgeInsets.only(top: 10),
                  children: userList,
                );
              },
            ),
          );
  }
}
