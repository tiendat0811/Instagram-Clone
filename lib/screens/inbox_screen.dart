import 'dart:collection';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';

import '../utils/colors.dart';
import '../utils/utils.dart';

class InboxScreen extends StatefulWidget {
  final sender, receiver;

  const InboxScreen({Key? key, required this.sender, required this.receiver})
      : super(key: key);

  @override
  _InboxScreenState createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  var senderData = {};
  var receiverData = {};
  bool isLoading = false;
  String chatId = "";
  final TextEditingController chatEditingController = TextEditingController();

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
      final snapshot = await ref.child('users').child('${widget.sender}').get();
      final data =
          Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
      if (data.isNotEmpty) {
        senderData = data;
      }

      final snapshot2 =
          await ref.child('users').child('${widget.receiver}').get();
      final data2 =
          Map<String, dynamic>.from(snapshot2.value as Map<dynamic, dynamic>);
      if (data2.isNotEmpty) {
        receiverData = data2;
      }

      final refFollower = await FirebaseDatabase.instance
          .ref("follow")
          .child("followers")
          .child('${widget.receiver}')
          .child('${widget.sender}')
          .once();
      final dataChat = Map<String, dynamic>.from(
          refFollower.snapshot.value as Map<dynamic, dynamic>);
      chatId = dataChat['chatHistory'];

      setState(() {});
    } catch (e) {
      print("");
    }
    setState(() {
      isLoading = false;
    });
  }

  void sendMessage() async {
    String res = "ERROR";
    try {
      Map<String, dynamic> chatInfo = {
        'text': chatEditingController.text,
        'sender': widget.sender,
        'receiver': widget.receiver,
        'datePublished': DateTime.now().millisecondsSinceEpoch,
      };
      await FirebaseDatabase.instance
          .ref("chats")
          .child(chatId)
          .push()
          .set(chatInfo);

      await FirebaseDatabase.instance
          .ref("follow")
          .child('followings')
          .child(widget.sender)
          .child(widget.receiver)
          .update({
        'lastMess': chatInfo['text'],
        'datePublished' : DateTime.now().millisecondsSinceEpoch
      });

      await FirebaseDatabase.instance
          .ref("follow")
          .child('followings')
          .child(widget.receiver)
          .child(widget.sender)
          .update({
        'lastMess': chatInfo['text'],
        'datePublished' : DateTime.now().millisecondsSinceEpoch
      });

      res = 'success';

      if (res != 'success') {
        showSnackBar(res, context);
      }
      setState(() {
        chatEditingController.text = "";
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
    return isLoading
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : Scaffold(
            appBar: AppBar(
              backgroundColor: mobileBackgroundColor,
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: NetworkImage(receiverData['photoUrl']),
                  ),
                  Container(
                    padding: EdgeInsets.only(left: 20),
                    child: Text(receiverData['username']),
                  )
                ],
              ),
              centerTitle: false,
            ),
            body: StreamBuilder(
              stream:
                  FirebaseDatabase.instance.ref("chats").child(chatId).onValue,
              builder: (context, snapshot) {
                final chatList = <ListTile>[];
                if (snapshot.hasData) {
                  DatabaseEvent chats = snapshot.data! as DatabaseEvent;
                  if (chats.snapshot.exists) {
                    final commentsData = Map<String, dynamic>.from(
                        chats.snapshot.value as Map<dynamic, dynamic>);
                    var sortByValue = new SplayTreeMap<String, dynamic>.from(
                        commentsData,
                        (key2, key1) => commentsData[key1]['datePublished']
                            .compareTo(commentsData[key2]['datePublished']));
                    sortByValue.forEach((key, value) {
                      final nextMess = Map<String, dynamic>.from(value);
                      final messTile = ListTile(
                          title: nextMess['sender'] == widget.receiver
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Container(
                                          margin: EdgeInsets.only(right: 10),
                                          child: CircleAvatar(
                                            backgroundImage: NetworkImage(
                                                receiverData['photoUrl']),
                                          ),
                                        ),
                                        Flexible(
                                            child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 20.0 * 0.75,
                                              vertical: 20 / 2),
                                          child: Text(
                                            nextMess['text'],
                                            softWrap: true,
                                          ),
                                          decoration: BoxDecoration(
                                              color: secondaryColor,
                                              borderRadius:
                                                  BorderRadius.circular(30)),
                                        )),
                                      ],
                                    ),
                                    Container(
                                      padding:
                                          EdgeInsets.only(left: 50, top: 10),
                                      child: Text(
                                        Jiffy(DateTime
                                                .fromMillisecondsSinceEpoch(
                                                    nextMess['datePublished']))
                                            .fromNow(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    )
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Flexible(
                                            child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 20.0 * 0.75,
                                              vertical: 20 / 2),
                                          child: Text(
                                            nextMess['text'],
                                            softWrap: true,
                                          ),
                                          decoration: BoxDecoration(
                                              color: blueColor,
                                              borderRadius:
                                                  BorderRadius.circular(30)),
                                        )),
                                      ],
                                    ),
                                    Container(
                                      padding:
                                          EdgeInsets.only(right: 10, top: 10),
                                      child: Text(
                                        Jiffy(DateTime
                                                .fromMillisecondsSinceEpoch(
                                                    nextMess['datePublished']))
                                            .fromNow(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    )
                                  ],
                                ));

                      chatList.add(messTile);
                    });
                  }
                }
                return ListView(
                  reverse: true,
                  shrinkWrap: true,
                  children: chatList,
                );
              },
            ),
            bottomNavigationBar: SafeArea(
              child: Container(
                height: kToolbarHeight,
                margin: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(senderData['photoUrl']),
                      radius: 18,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 8),
                        child: TextField(
                          controller: chatEditingController,
                          decoration: InputDecoration(
                            hintText: 'Type message...',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => sendMessage(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 8),
                        child: const Text(
                          'Send',
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
