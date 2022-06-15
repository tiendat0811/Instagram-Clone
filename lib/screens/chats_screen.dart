import 'dart:collection';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';

import '../utils/colors.dart';
import 'inbox_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({Key? key}) : super(key: key);

  @override
  _ChatsScreenState createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final _uid = FirebaseAuth.instance.currentUser!.uid;

  void deleteChat(String receiver) async{
    try{
      final ref = await FirebaseDatabase.instance.ref("follow").child('followings').child(_uid).child(receiver);
      await ref.update({'chatHistory' : null});
    }catch(e){
      print(e.toString());
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: mobileBackgroundColor,
          title: const Text(
            'Chats',
          ),
          centerTitle: false,
        ),
        body: StreamBuilder(
          stream: FirebaseDatabase.instance
              .ref('follow')
              .child('followings')
              .child(_uid)
              .onValue,
          builder: (context, snapshot) {
            final chatList = <ListTile>[];
            if (snapshot.hasData) {
              DatabaseEvent chats = snapshot.data! as DatabaseEvent;
              if (chats.snapshot.exists) {
                final commentsData = Map<String, dynamic>.from(
                    chats.snapshot.value as Map<dynamic, dynamic>);
                var sortByValue = new SplayTreeMap<String, dynamic>.from(
                    commentsData,
                        (key1, key2) => commentsData[key1]['datePublished']
                        .compareTo(commentsData[key2]['datePublished']));
                sortByValue.forEach((key, value) {
                  final nextMess = Map<String, dynamic>.from(value);
                  if(nextMess['chatHistory'] != null){
                    final messTile = ListTile(
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 20 * 0.75, horizontal: 20),

                        title: InkWell(
                          onLongPress: (){
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
                                            deleteChat(key);
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
                          onTap: (){
                            Navigator.of(context)
                                .push(
                              MaterialPageRoute(
                                builder: (context) => InboxScreen(sender: _uid, receiver: key),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: NetworkImage(nextMess['photoUrl']),
                              ),
                              Expanded(
                                child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          nextMess['username'],
                                          style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500),
                                        ),
                                        SizedBox(
                                          height: 5,
                                        ),
                                        Opacity(
                                          opacity: 0.65,
                                          child: Text(
                                            nextMess['lastMess'],
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        )
                                      ],
                                    )),
                              ),
                              Text(
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
                            ],
                          ),
                        )
                    );
                    chatList.add(messTile);
                  }
                });
              }
            }
            return ListView(
              reverse: true,
              shrinkWrap: true,
              children: chatList,
            );
          },
        ));
  }
}
