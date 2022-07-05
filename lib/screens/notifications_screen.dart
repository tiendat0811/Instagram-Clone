import 'dart:collection';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  bool isLoading = false;
  var userList = {};

  @override
  void initState() {
    super.initState();
    getData();
  }

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

      if (userList[_uid]['unseenNotificationCount'] != null) {
        await FirebaseDatabase.instance
            .ref("users")
            .child(_uid)
            .update({'unseenNotificationCount': null});
      }
    } else {
      print('No data available.');
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          'Notifications',
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
        centerTitle: false,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : StreamBuilder(
              stream: FirebaseDatabase.instance
                  .ref('users')
                  .child(_uid)
                  .child("notifications")
                  .onValue,
              builder: (context, snapshot) {
                final notificationsList = <ListTile>[];
                if (snapshot.hasData) {
                  DatabaseEvent notifications = snapshot.data! as DatabaseEvent;
                  if (notifications.snapshot.exists) {
                    final notificationsData = Map<String, dynamic>.from(
                        notifications.snapshot.value as Map<dynamic, dynamic>);
                    var sortByValue = new SplayTreeMap<String, dynamic>.from(
                        notificationsData,
                        (key2, key1) => notificationsData[key1]['datePublished']
                            .compareTo(
                                notificationsData[key2]['datePublished']));
                    sortByValue.forEach((key, value) {
                      final nextNoti = Map<String, dynamic>.from(value);
                      final notiTile = ListTile(
                        title: Container(
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: NetworkImage(
                                    userList[nextNoti['uid']]['photoUrl']),
                              ),
                              SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.8,
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: RichText(
                                      text: TextSpan(children: <TextSpan>[
                                        TextSpan(
                                            text: userList[nextNoti['uid']]
                                                ['username'],
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .primaryColor)),
                                        TextSpan(
                                            text: " " + nextNoti['text'],
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .primaryColor)),
                                        TextSpan(
                                            text: ". ${Jiffy(DateTime
                                                        .fromMillisecondsSinceEpoch(
                                                            nextNoti[
                                                                'datePublished']))
                                                    .fromNow()}",
                                            style: TextStyle(
                                                color: Colors.grey)),
                                      ]),
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      );
                      notificationsList.add(notiTile);
                    });
                  }
                }

                return ListView(
                  children: notificationsList,
                );
              }),
    );
  }
}
