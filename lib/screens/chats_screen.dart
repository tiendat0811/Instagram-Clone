import 'dart:collection';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';

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
  void getData() async{
    await FirebaseDatabase.instance
        .ref("users")
        .child(_uid)
        .update({"unseenMessageCount": 0});
  }
  @override
  void initState(){
    super.initState();

    getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(
            color: Theme.of(context).primaryColor,
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: Text(
            'Chats',
            style: TextStyle(
                color: Theme.of(context).primaryColor
            ),
          ),
          centerTitle: false,
        ),
        body: StreamBuilder(
          stream: FirebaseDatabase.instance
              .ref('users')
              .onValue,
          builder: (context, snapshot) {
            final chatList = <ListTile>[];
            if (snapshot.hasData) {
              DatabaseEvent users = snapshot.data! as DatabaseEvent;
              if (users.snapshot.exists) {
                final usersData = Map<String, dynamic>.from(
                    users.snapshot.value as Map<dynamic, dynamic>);
                var chatsData = usersData[_uid]['chats'];
                if(chatsData!= null){
                  var sortChats = SplayTreeMap<String, dynamic>.from(
                      chatsData,
                          (key1, key2) => chatsData[key1]['lastTime']
                          .compareTo(chatsData[key2]['lastTime']));

                  sortChats.forEach((key, value) {
                    final nextMess = Map<String, dynamic>.from(value);
                    //sort by time
                    nextMess.removeWhere((key, value) => key == "lastTime");
                    var sortMessage = SplayTreeMap<String, dynamic>.from(
                        nextMess,
                            (key2, key1) => nextMess[key1]['datePublished']
                            .compareTo(nextMess[key2]['datePublished']));

                    final idLastMess = sortMessage.keys.toList().first;
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
                                radius: MediaQuery.of(context).size.width*0.06,
                                backgroundImage: NetworkImage(usersData[key]['photoUrl']),
                              ),
                              Expanded(
                                child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          usersData[key]['username'],
                                          style: TextStyle(
                                              fontSize: MediaQuery.of(context).size.width*0.04,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(
                                          height: 5,
                                        ),
                                        Opacity(
                                          opacity: 0.65,
                                          child: Text(
                                            nextMess[idLastMess]['text'],
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: MediaQuery.of(context).size.width*0.04,
                                            ),
                                          ),
                                        )
                                      ],
                                    )),
                              ),
                              Text(
                                Jiffy(DateTime
                                    .fromMillisecondsSinceEpoch(
                                    nextMess[idLastMess]['datePublished']))
                                    .fromNow(),
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                  fontSize: MediaQuery.of(context).size.width*0.03,
                                ),
                              ),
                            ],
                          ),
                        )
                    );
                    chatList.add(messTile);
                  });
                }else{
                  chatList.add(ListTile(title: Text("You don't have any message yet"),));
                }

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
