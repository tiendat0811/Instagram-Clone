
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone/screens/add_post_screen.dart';
import 'package:instagram_clone/screens/feed_screen.dart';
import 'package:instagram_clone/screens/profile_screen.dart';
import 'package:instagram_clone/screens/search_screen.dart';
import 'package:instagram_clone/utils/colors.dart';

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

  void NavigationTapped(int page){
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
          physics: NeverScrollableScrollPhysics(),
          children: <Widget>[
            FeedScreen(),
            SearchScreen(),
            AddPostScreen(),
            Text("noti"),
            ProfileScreen(uid:'$_uid'),
          ],
          controller: pageController,
          onPageChanged: onPageChanged,
        ),
        bottomNavigationBar: CupertinoTabBar(
          backgroundColor: mobileBackgroundColor,
          items: [
            BottomNavigationBarItem(
              icon: _page==0 ? Icon(Icons.home, color: primaryColor,): Icon(Icons.home_outlined, color: primaryColor),
              label: '',

            ),
            BottomNavigationBarItem(
              icon: _page==1 ? Icon(CupertinoIcons.search, color: primaryColor,):Icon(Icons.search, color: primaryColor),
              label: '',
              backgroundColor: primaryColor,
            ),
            BottomNavigationBarItem(
              icon: _page==2 ? Icon(Icons.add_circle, color: primaryColor) : Icon(Icons.add_circle_outline, color: primaryColor),
              label: '',
              backgroundColor: primaryColor,
            ),
            BottomNavigationBarItem(
              icon: _page==3 ? Icon(Icons.favorite, color: primaryColor) : Icon(Icons.favorite_outline, color: primaryColor),
              label: '',
              backgroundColor: primaryColor,
            ),
            BottomNavigationBarItem(
              icon: _page==4 ? Icon(Icons.person, color: primaryColor) : Icon(Icons.person_outline, color: primaryColor),
              label: '',
              backgroundColor: primaryColor,
            ),
          ],
          onTap: NavigationTapped,
        ),
      ),
    );
  }
}
