import 'dart:collection';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../utils/colors.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController searchController = TextEditingController();
  bool isShowUsers = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        title: Form(
          child: TextFormField(
            controller: searchController,
            decoration:
                const InputDecoration(labelText: 'Search for a user...'),
            onFieldSubmitted: (String _) {
              setState(() {
                isShowUsers = true;
              });
              print(_);
            },
          ),
        ),
      ),
      body: isShowUsers
          ? Text("Dang tim user")
          : StreamBuilder(
              stream: FirebaseDatabase.instance.ref('posts/').onValue,
              builder: (context, snapshot) {
                final tileList = <Widget>[];
                if (snapshot.hasData) {
                  DatabaseEvent dataValues = snapshot.data! as DatabaseEvent;
                  if (dataValues.snapshot.exists) {
                    final myPosts = Map<String, dynamic>.from(
                        dataValues.snapshot.value as Map<dynamic, dynamic>);
                    var sortByValue = new SplayTreeMap<String, dynamic>.from(
                        myPosts,
                            (key2, key1) => myPosts[key1]['datePublished']
                            .compareTo(myPosts[key2]['datePublished']));

                    sortByValue.forEach((key, value) {
                      final nextPost = Map<String, dynamic>.from(value);
                      final post = Container(
                        padding: const EdgeInsets.all(2),
                        child: Image.network(nextPost['postImage']),
                      );
                      tileList.add(post);
                    });
                    return GridView.count(
                      primary: false,
                      padding: const EdgeInsets.all(20),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      crossAxisCount: 2,
                      children: tileList,
                    );
                  }
                }
                return Text("");
              }),
    );
  }
}
