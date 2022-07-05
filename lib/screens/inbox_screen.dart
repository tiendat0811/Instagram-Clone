import 'dart:collection';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';

import '../utils/utils.dart';
import 'profile_screen.dart';

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
      DatabaseReference refSender = await FirebaseDatabase.instance
          .ref("users")
          .child('${widget.sender}')
          .child('chats')
          .child('${widget.receiver}');
      final messId = await refSender.push().key;
      refSender.child(messId!).set(chatInfo);

      refSender.update({"lastTime": DateTime.now().millisecondsSinceEpoch });

      DatabaseReference refReceiver = await FirebaseDatabase.instance
          .ref("users")
          .child('${widget.receiver}')
          .child('chats')
        .child('${widget.sender}');

      refReceiver.child(messId)
          .set(chatInfo);
      refReceiver.update({"lastTime": DateTime.now().millisecondsSinceEpoch });

      int unseenMessageCount = 0;
      if(receiverData['unseenMessageCount']!=null){
        unseenMessageCount = receiverData['unseenMessageCount'];
      }
      await FirebaseDatabase.instance
          .ref("users")
          .child(widget.receiver)
          .update({
        "unseenMessageCount" : unseenMessageCount+1
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

  void deleteMess(String messId) async {
    try {
      await FirebaseDatabase.instance
          .ref("users")
          .child('${widget.sender}')
          .child('chats')
          .child('${widget.receiver}')
          .child(messId)
          .remove();
    } catch (e) {
      print(e.toString());
    }
  }

  void recallMess(String messId) async {
    try {
      await FirebaseDatabase.instance
          .ref("users")
          .child('${widget.sender}')
          .child('chats')
          .child('${widget.receiver}')
          .child(messId)
          .remove();

      await FirebaseDatabase.instance
          .ref("users")
          .child('${widget.receiver}')
          .child('chats')
          .child('${widget.sender}')
          .child(messId)
          .remove();
    } catch (e) {
      print(e.toString());
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
              title: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(
                          uid: widget.receiver,
                        ),
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundImage: NetworkImage(receiverData['photoUrl']),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(left: 20),
                    child: Text(receiverData['username'],
                    style: TextStyle(color: Theme.of(context).primaryColor),),
                  )
                ],
              ),
              centerTitle: false,
            ),
            body: StreamBuilder(
              stream:
                  FirebaseDatabase.instance.ref("users").child(widget.sender).child("chats").child(widget.receiver).onValue,
              builder: (context, snapshot) {
                final chatList = <ListTile>[];
                if (snapshot.hasData) {
                  DatabaseEvent chats = snapshot.data! as DatabaseEvent;
                  if (chats.snapshot.exists) {
                    final commentsData = Map<String, dynamic>.from(
                        chats.snapshot.value as Map<dynamic, dynamic>);
                    commentsData.removeWhere((key, value) => key == "lastTime");
                    var sortByValue = SplayTreeMap<String, dynamic>.from(
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
                                          margin: const EdgeInsets.only(right: 10),
                                          child: CircleAvatar(
                                            backgroundImage: NetworkImage(
                                                receiverData['photoUrl']),
                                          ),
                                        ),
                                        Flexible(
                                            child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20.0 * 0.75,
                                              vertical: 20 / 2),
                                          decoration: BoxDecoration(
                                              color: Theme.of(context).primaryColor,
                                              borderRadius:
                                                  BorderRadius.circular(30)),
                                          child: Text(
                                            nextMess['text'],
                                            softWrap: true,
                                            style: TextStyle(
                                                color: Theme.of(context).scaffoldBackgroundColor
                                            ),
                                          ),
                                        )),
                                      ],
                                    ),
                                    Container(
                                      padding:
                                          const EdgeInsets.only(left: 50, top: 10),
                                      child: Text(
                                        Jiffy(DateTime
                                                .fromMillisecondsSinceEpoch(
                                                    nextMess['datePublished']))
                                            .fromNow(),
                                        style: const TextStyle(
                                          color: Colors.grey,
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
                                            child: InkWell(
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => Dialog(
                                                child: ListView(
                                                    padding: const EdgeInsets
                                                            .symmetric(
                                                        vertical: 16),
                                                    shrinkWrap: true,
                                                    children: [
                                                      'Delete',
                                                      'Recall',
                                                      'Cancel'
                                                    ]
                                                        .map(
                                                          (e) => InkWell(
                                                              child: Container(
                                                                padding: const EdgeInsets
                                                                        .symmetric(
                                                                    vertical:
                                                                        12,
                                                                    horizontal:
                                                                        16),
                                                                child: Text(e),
                                                              ),
                                                              onTap: () {
                                                                if(e.toString() == "Delete"){
                                                                  deleteMess(key);
                                                                  // remove the dialog box
                                                                  Navigator.of(
                                                                      context)
                                                                      .pop();
                                                                }else if(e.toString() == "Recall"){
                                                                  recallMess(key);
                                                                  // remove the dialog box
                                                                  Navigator.of(
                                                                      context)
                                                                      .pop();
                                                                }else{
                                                                  // remove the dialog box
                                                                  Navigator.of(
                                                                      context)
                                                                      .pop();
                                                                }
                                                              }),
                                                        )
                                                        .toList()),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 20.0 * 0.75,
                                                vertical: 20 / 2),
                                            decoration: BoxDecoration(
                                                color: Colors.blue,
                                                borderRadius:
                                                    BorderRadius.circular(30)),
                                            child: Text(
                                              nextMess['text'],
                                              softWrap: true,
                                            ),
                                          ),
                                        )),
                                      ],
                                    ),
                                    Container(
                                      padding:
                                          const EdgeInsets.only(right: 10, top: 10),
                                      child: Text(
                                        Jiffy(DateTime
                                                .fromMillisecondsSinceEpoch(
                                                    nextMess['datePublished']))
                                            .fromNow(),
                                        style: const TextStyle(
                                          color: Colors.grey,
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
                  padding: const EdgeInsets.only(top: 10),
                  reverse: true,
                  shrinkWrap: true,
                  children: chatList,
                );
              },
            ),
            bottomNavigationBar: Container(
              decoration: const BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.all(
                      Radius.circular(30.0)
                  )
              ),
              height: kToolbarHeight,
              margin: EdgeInsets.only(left: 10, right: 10,
                  bottom: MediaQuery.of(context).viewInsets.bottom+10),
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
                        decoration: const InputDecoration(
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
                        style: TextStyle(fontWeight: FontWeight.bold,color: Colors.blue),
                      ),
                    ),
                  )
                ],
              ),
            )
          );
  }
}
