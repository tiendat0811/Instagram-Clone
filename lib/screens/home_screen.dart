import 'package:badges/badges.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '/screens/add_post_screen.dart';
import '/screens/feed_screen.dart';
import '/screens/notifications_screen.dart';
import '/screens/profile_screen.dart';
import '/screens/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String username = "";
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  int _page = 0;
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
  }

  @override
  void dispose() {
    super.dispose();
    pageController.dispose();
  }

  void NavigationTapped(int page) {
    pageController.jumpToPage(page);
  }

  void onPageChanged(int page) {
    setState(() {
      _page = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          body: PageView(
            physics: const NeverScrollableScrollPhysics(),
            controller: pageController,
            onPageChanged: onPageChanged,
            children: <Widget>[
              const FeedScreen(),
              const SearchScreen(),
              const AddPostScreen(),
              const NotificationsScreen(),
              ProfileScreen(uid: _uid),
            ],
          ),
          bottomNavigationBar: Padding(
            padding: EdgeInsets.all(5),
            child: StreamBuilder(
                stream: FirebaseDatabase.instance.ref("users").child(_uid).onValue,
                builder: (context, snapshot) {
                  int unseenNotificationCount = 0;
                  if (snapshot.hasData) {
                    DatabaseEvent dataValues = snapshot.data! as DatabaseEvent;
                    if (dataValues.snapshot.exists) {
                      final snapshotData = Map<String, dynamic>.from(
                          dataValues.snapshot.value as Map<dynamic, dynamic>);

                      if (snapshotData['unseenNotificationCount'] != null) {
                        unseenNotificationCount = snapshotData['unseenNotificationCount'];
                      }
                    }
                  }
                  return CupertinoTabBar(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    items: [
                      BottomNavigationBarItem(
                        icon: _page == 0
                            ?  Icon(
                          Icons.home,
                          color: Theme.of(context).primaryColor,
                        )
                            :  Icon(Icons.home_outlined,
                            color: Theme.of(context).primaryColor),
                        label: '',
                      ),
                      BottomNavigationBarItem(
                        icon: _page == 1
                            ?  Icon(
                          CupertinoIcons.search,
                          color: Theme.of(context).primaryColor,
                        )
                            :  Icon(Icons.search, color: Theme.of(context).primaryColor),
                        label: '',
                        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      ),
                      BottomNavigationBarItem(
                        icon: _page == 2
                            ?  Icon(Icons.add_circle, color: Theme.of(context).primaryColor)
                            :  Icon(Icons.add_circle_outline,
                            color: Theme.of(context).primaryColor),
                        label: '',
                        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      ),
                      BottomNavigationBarItem(
                        icon: _page == 3
                            ?  Icon(Icons.favorite, color: Theme.of(context).primaryColor)
                            : Badge(
                            showBadge:
                            unseenNotificationCount != 0 ? true : false,
                            badgeContent: Text("$unseenNotificationCount"),
                            child: Icon(Icons.favorite_outline,
                                color: Theme.of(context).primaryColor)),
                        label: '',
                        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      ),
                      BottomNavigationBarItem(
                        icon: _page == 4
                            ?  Icon(Icons.person, color: Theme.of(context).primaryColor)
                            :  Icon(Icons.person_outline,
                            color: Theme.of(context).primaryColor),
                        label: '',
                        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      ),
                    ],
                    onTap: NavigationTapped,
                  );
                })
          )
      ),
    );
  }
}
