import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '/screens/profile_screen.dart';
import 'detail_post_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController searchController = TextEditingController();
  bool isShowUsers = false;
  final defaultImg =
      "https://icon-library.com/images/instagram-round-icon-png/instagram-round-icon-png-5.jpg";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Form(
          child: TextFormField(
            controller: searchController,
            decoration:
                const InputDecoration(labelText: 'Search for a user...'),
            onChanged: (String _) {
              if (_ != null) {
                setState(() {
                  isShowUsers = true;
                });
              }
              if (_ == "") {
                isShowUsers = false;
              }
            },
          ),
        ),
      ),
      body: isShowUsers
          ? StreamBuilder(
              stream: FirebaseDatabase.instance
                  .ref()
                  .child('users')
                  .orderByChild("username")
                  .startAt(searchController.text)
                  .endAt(searchController.text + '\uf8ff')
                  .onValue,
              builder: (context, snapshot) {
                final tileList = <Widget>[];
                if (snapshot.hasData) {
                  DatabaseEvent dataValues = snapshot.data! as DatabaseEvent;
                  if (dataValues.snapshot.exists) {
                    final listUsers = Map<String, dynamic>.from(
                        dataValues.snapshot.value as Map<dynamic, dynamic>);
                    if (listUsers.isNotEmpty) {
                      listUsers.forEach((key, value) {
                        final nextUser = Map<String, dynamic>.from(value);
                        final post = Container(
                          padding: const EdgeInsets.all(2),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 6)
                                .copyWith(right: 0),
                            child: InkWell(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ProfileScreen(
                                    uid: '$key',
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  nextUser['photoUrl'] != null
                                      ? CircleAvatar(
                                          radius: 24,
                                          backgroundImage: NetworkImage(
                                              nextUser['photoUrl']),
                                        )
                                      : CircularProgressIndicator(),
                                  Expanded(
                                      child: Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        nextUser['username'] != null
                                    ?Text(
                                          nextUser['username'],
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 24),
                                        )
                                        : Center(child: CircularProgressIndicator(),)
                                      ],
                                    ),
                                  )),
                                ],
                              ),
                            ),
                          ),
                        );
                        tileList.add(post);
                      });
                    } else {
                      tileList.add(Text("No users found"));
                    }
                  }
                }
                return ListView(
                  children: tileList,
                );
              })
          : StreamBuilder(
              stream: FirebaseDatabase.instance.ref('posts/').onValue,
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
                              ? InkWell(
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (context) => DetailPostScreen(
                                            postId: key)),
                                  ),
                                  child: Image(
                                    image: NetworkImage(nextPost['postImage']),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : CircularProgressIndicator(),
                        );
                        tileList.add(post);
                      });
                    } else {
                      tileList.add(Text(""));
                    }

                    return GridView.count(
                      primary: false,
                      padding: const EdgeInsets.all(5),
                      crossAxisSpacing: 1,
                      mainAxisSpacing: 1,
                      crossAxisCount: 3,
                      children: tileList,
                    );
                  }
                }
                return Text("");
              }),
    );
  }
}
