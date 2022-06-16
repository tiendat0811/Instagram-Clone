import 'dart:collection';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone/screens/comment_screen.dart';
//import 'package:instagram_clone/screens/profile_screen.dart';
import 'package:instagram_clone/utils/colors.dart';
import 'package:instagram_clone/utils/utils.dart';
import 'package:jiffy/jiffy.dart';


class DetailPostScreen extends StatefulWidget {
  final postId, userPost;

  const DetailPostScreen({Key? key,required this.postId, required this.userPost}) : super(key: key);

  @override
  State<DetailPostScreen> createState() => _DetailPostScreenState();
}

class _DetailPostScreenState extends State<DetailPostScreen> {
  final TextEditingController commentEditingController = TextEditingController();
  final Map userInfo = <String, dynamic>{
    'uid': 'uid',
    'name': '',
    'email': '',
    'photoUrl': "https://images.squarespace-cdn.com/content/v1/54b7b93ce4b0a3e130d5d232/1519987020970-8IQ7F6Z61LLBCX85A65S/icon.png?format=1000w",
    'bio': '',
  };
  void getUser() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseDatabase.instance.ref();
    final snapshot = await ref.child('users/$uid').get();
    if (snapshot.exists) {
      final data =
      Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
      setState(() {
        userInfo.update('uid', (value) => uid);
        userInfo.update('name', (value) => data['username']);
        userInfo.update('email', (value) => data['email']);
        userInfo.update('photoUrl', (value) => data['photoUrl']);
        userInfo.update('bio', (value) => data['bio']);
      });
    } else {
      print('No data available.');
    }
  }
  @override
  void initState() {
    super.initState();
    getUser();
  }

  @override
  void dispose() {
    super.dispose();
  }

  final _uid = FirebaseAuth.instance.currentUser!.uid;

  void likePost(String key, String uid, Map list, String userPost) async {
    final ref = await FirebaseDatabase.instance.ref('likes/');
    if (list.containsKey(uid)) {
      ref.child(key).update({uid: null});
    } else {
      ref.child(key).update({uid: true});
      final snapshot = await FirebaseDatabase.instance.ref()
          .child('users')
          .child(uid)
          .get();
      final data =
      Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
      final notifications = FirebaseDatabase.instance.ref("notifications")
          .child('${userPost}');
      notifications.push().set({
        'username': data['name'],
        'userImg': data['photoUrl'],
        'text': "liked on your post",
        'datePublished': DateTime
            .now()
            .millisecondsSinceEpoch
      });
    }
  }
  void deletePost(String postId) async {
    String res = "ERROR";
    try {
      await FirebaseDatabase.instance.ref("posts/${postId}").remove();
      res = 'success';
      if (res != 'success') {
        showSnackBar(res, context);
      }
      setState(() {});
    } catch (err) {
      showSnackBar(res, context);
    }
  }


  void postComment() async {
    String res = "ERROR";
    try {

      DatabaseReference ref = await FirebaseDatabase.instance.ref("comments/${widget.postId}/").push();
      Map<String, dynamic> cmtInfo = {
        'text': commentEditingController.text,
        'username': userInfo["name"],
        'userImage': userInfo["photoUrl"],
        'datePublished': DateTime.now().millisecondsSinceEpoch,
        'uid' : userInfo['uid']
      };
      ref.set(cmtInfo);
      res = 'success';

      final snapshot = await FirebaseDatabase.instance.ref("posts/${widget.postId}/").get();
      if (snapshot.exists) {
        final data =
        Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
        int count = data['countCmt'];
        count++;
        await FirebaseDatabase.instance.ref("posts/${widget.postId}/").update({'countCmt': count});
      }

      //notification
      final notifications = await FirebaseDatabase.instance.ref("notifications").child('${widget.userPost}');
      notifications.push().set({
        'username' : userInfo['name'],
        'userImg': userInfo['photoUrl'],
        'text' : "commented on your post",
        'datePublished' : DateTime.now().millisecondsSinceEpoch
      });

      if (res != 'success') {
        showSnackBar(res, context);
      }
      setState(() {
        commentEditingController.text = "";
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
     return Scaffold(
       appBar: AppBar(
         backgroundColor: mobileBackgroundColor,
         title: const Text('Detail Post'),
         centerTitle: false,
       ),
       body: StreamBuilder(
           stream: FirebaseDatabase.instance
               .ref('likes/')
               .onValue,
           builder: (context, snapshotlike){
             return StreamBuilder(stream: FirebaseDatabase.instance
                 .ref('posts/')
                 .onValue,
               builder: (context, snapshot) {
                 final tileList = <ListTile>[];
                 if (snapshot.hasData) {
                   DatabaseEvent dataValues = snapshot.data! as DatabaseEvent;
                   DatabaseEvent likeValues = snapshotlike.data! as DatabaseEvent;

                   if (dataValues.snapshot.exists) {
                     final myPosts = Map<String, dynamic>.from(
                         dataValues.snapshot.value as Map<dynamic, dynamic>);

                     final likeOfPosts = Map<String, dynamic>.from(
                         likeValues.snapshot.value as Map<dynamic, dynamic>);

                     //sort by time
                     var sortByValue = SplayTreeMap<String, dynamic>.from(
                         myPosts,
                             (key2, key1) =>
                             myPosts[key1]['datePublished']
                                 .compareTo(myPosts[key2]['datePublished']));

                     sortByValue.forEach((key, value) {
                       int countLike = 0;
                       if (likeValues.snapshot.exists) {
                         countLike =
                             Map<String, dynamic>.from(likeOfPosts[key]).length -
                                 1;
                       }

                       final nextPost = Map<String, dynamic>.from(value);
                       ListTile(
                         title: Container(
                           color: mobileBackgroundColor,
                           padding: const EdgeInsets.symmetric(
                             vertical: 10,
                           ),
                           child: Column(
                             children: [
                               //HEADER POST
                               //BODY POST - IMAGE

                               InkWell(
                                 onTap:() => Navigator.of(context).push(
                                   MaterialPageRoute(
                                     builder: (context) =>
                                         DetailPostScreen(
                                             postId: key,
                                             userPost: nextPost['uid']
                                         ),
                                   ),
                                 ),
                                 child: SizedBox(
                                   height: MediaQuery
                                       .of(context)
                                       .size
                                       .height * 0.35,
                                   width: double.infinity,
                                   child: Image.network(
                                     nextPost['postImage'],
                                     fit: BoxFit.cover,
                                   ),
                                 ),
                               ),
                               //LIKE COMMENT
                               Row(
                                 children: [
                                   IconButton(
                                     onPressed: () =>
                                         likePost(key, _uid, likeOfPosts[key],
                                             nextPost['uid']),
                                     icon: likeOfPosts[key].containsKey(_uid)
                                         ? const Icon(
                                       Icons.favorite,
                                       color: Colors.red,
                                     )
                                         : const Icon(
                                       Icons.favorite_border,
                                     ),
                                   ),
                                   IconButton(
                                       onPressed: () =>
                                           Navigator.of(context).push(
                                             MaterialPageRoute(
                                               builder: (context) =>
                                                   CommentScreen(
                                                       postId: key,
                                                       userPost: nextPost['uid']
                                                   ),
                                             ),
                                           ),
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
                                             icon: const Icon(
                                                 Icons.bookmark_border),
                                             onPressed: () {}),
                                       ))
                                 ],
                               ),

                               //DESCRIPTION
                               Container(
                                 padding:
                                 const EdgeInsets.symmetric(horizontal: 16),
                                 child: Column(
                                   mainAxisSize: MainAxisSize.min,
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: <Widget>[
                                     DefaultTextStyle(
                                         style: Theme
                                             .of(context)
                                             .textTheme
                                             .subtitle2!
                                             .copyWith(
                                             fontWeight: FontWeight.w800),
                                         child: Text(
                                           '${countLike} likes',
                                           style: Theme
                                               .of(context)
                                               .textTheme
                                               .bodyText2,
                                         )),
                                     Container(
                                       width: double.infinity,
                                       padding: const EdgeInsets.only(
                                         top: 8,
                                       ),
                                       child: RichText(
                                         text: TextSpan(
                                           style: const TextStyle(
                                               color: primaryColor),
                                           children: [
                                             TextSpan(
                                               text: nextPost["username"],
                                               style: const TextStyle(
                                                 fontWeight: FontWeight.bold,
                                               ),
                                             ),
                                             TextSpan(
                                               text: " " + nextPost["description"],
                                             ),
                                           ],
                                         ),
                                       ),
                                     ),
                                     Container(
                                       child: Text(
                                         Jiffy(DateTime
                                             .fromMillisecondsSinceEpoch(
                                             nextPost['datePublished'])).fromNow(),
                                         style: const TextStyle(
                                           color: secondaryColor,
                                         ),
                                       ),
                                       padding:
                                       const EdgeInsets.symmetric(vertical: 4),
                                     ),
                                   ],
                                 ),
                               ),
                             ],
                           ),
                         ),
                       );
                     });
                   }
                 }
                 return ListView(
                   children: tileList,
                 );
               },
             );
           },
       ),
       bottomNavigationBar: SafeArea(
         child: Container(
           height: kToolbarHeight,
           margin:
           EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
           padding: const EdgeInsets.only(left: 16, right: 8),
           child: Row(
             children: [
               CircleAvatar(
                 backgroundImage: NetworkImage(userInfo['photoUrl']),
                 radius: 18,
               ),
               Expanded(
                 child: Padding(
                   padding: const EdgeInsets.only(left: 16, right: 8),
                   child: TextField(
                     controller: commentEditingController,
                     decoration: InputDecoration(
                       hintText: 'Comment as ${userInfo['name']}',
                       border: InputBorder.none,
                     ),
                   ),
                 ),
               ),
               InkWell(
                 onTap: () => postComment(),
                 child: Container(
                   padding:
                   const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                   child: const Text(
                     'Post',
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
