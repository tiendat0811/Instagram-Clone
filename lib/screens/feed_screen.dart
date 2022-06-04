import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:instagram_clone/utils/colors.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        title: SvgPicture.asset(
          'assets/ic_instagram.svg',
          color: primaryColor,
          height: 32,
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.messenger,
              color: primaryColor,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref('posts/').onValue,
        builder: (context, snapshot) {
          final tileList = <ListTile>[];
          if (snapshot.hasData) {
            DatabaseEvent dataValues = snapshot.data! as DatabaseEvent;
            final myPosts = Map<String, dynamic>.from(
                dataValues.snapshot.value as Map<dynamic, dynamic>);
            myPosts.forEach((key, value) {
              final nextPost = Map<String, dynamic>.from(value);
              final postTile = ListTile(
                title: Container(
                  color: mobileBackgroundColor,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                  ),
                  child: Column(
                    children: [
                      //HEADER POST
                      Container(
                        padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 6)
                            .copyWith(right: 0),
                        child: Row(
                          children: <Widget>[
                            CircleAvatar(
                              radius: 16,
                              backgroundImage:
                                  NetworkImage(nextPost['postImage']),
                            ),
                            Expanded(
                                child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nextPost['username'],
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            )),
                            IconButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => Dialog(
                                      child: ListView(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          shrinkWrap: true,
                                          children: [
                                            'Delete',
                                          ]
                                              .map(
                                                (e) => InkWell(
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                              .symmetric(
                                                          vertical: 12,
                                                          horizontal: 16),
                                                      child: Text(e),
                                                    ),
                                                    onTap: () {
                                                      // deletePost(
                                                      //   widget.snap['postId']
                                                      //       .toString(),
                                                      // );
                                                      // remove the dialog box
                                                      Navigator.of(context)
                                                          .pop();
                                                    }),
                                              )
                                              .toList()),
                                    ),
                                  );
                                },
                                icon: Icon(Icons.more_vert)),
                          ],
                        ),
                      ),

                      //BODY POST - IMAGE
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.35,
                        width: double.infinity,
                        child: Image.network(
                          nextPost['postImage'],
                          fit: BoxFit.cover,
                        ),
                      ),

                      //LIKE COMMENT
                      Row(
                        children: [
                          IconButton(
                              onPressed: () {},
                              icon: Icon(
                                Icons.favorite,
                                color: Colors.red,
                              )),
                          IconButton(
                              onPressed: () {},
                              icon: Icon(
                                Icons.comment_outlined,

                              )),
                          IconButton(
                              onPressed: () {},
                              icon: Icon(
                                Icons.send_outlined,

                              )),
                          Expanded(
                              child: Align(
                                alignment: Alignment.bottomRight,
                                child: IconButton(
                                    icon: const Icon(Icons.bookmark_border), onPressed: () {}),
                              ))
                        ],
                      ),

                      //DESCRIPTION AND COMMENT
                      // Container(
                      //   padding: const EdgeInsets.symmetric(horizontal: 16),
                      //   child: Column(
                      //     mainAxisSize: MainAxisSize.min,
                      //     crossAxisAlignment: CrossAxisAlignment.start,
                      //     children: <Widget> [
                      //       DefaultTextStyle(
                      //           style: Theme.of(context)
                      //               .textTheme
                      //               .subtitle2!
                      //               .copyWith(fontWeight: FontWeight.w800),
                      //           child: Text(
                      //             ' 10 likes',
                      //             style: Theme.of(context).textTheme.bodyText2,
                      //           )),
                      //     ],
                      //   ),
                      // ),
                    ],
                  ),
                ),
              );
              tileList.add(postTile);
            });
          }

          return ListView(
            children: tileList,
          );
        },
      ),
    );
  }
}
