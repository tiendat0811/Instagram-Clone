import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:instagram_clone/screens/home_screen.dart';
import 'package:instagram_clone/screens/signup_screen.dart';
import 'package:instagram_clone/utils/colors.dart';
import 'package:instagram_clone/widgets/text_field_input.dart';

import '../resources/auth_methods.dart';
import '../utils/utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void loginUser() async {
    setState(() {
      _isLoading = true;
    });
    String res = await AuthMethods().loginUser(
        email: _emailController.text, password: _passwordController.text);
    if (res == 'login success') {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()));
      setState(() {
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      showSnackBar(res, context);
    }
  }

  void navigateToSignup() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const SignupScreen()));
  }

  // FACEBOOK SIGN IN
  Future<void> signInWithFacebook(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });
    final FirebaseAuth _auth = FirebaseAuth.instance;
    try {
      final LoginResult loginResult = await FacebookAuth.instance.login();

      final OAuthCredential facebookAuthCredential =
          FacebookAuthProvider.credential(loginResult.accessToken!.token);

      await _auth.signInWithCredential(facebookAuthCredential);

      var userData = await FacebookAuth.instance.getUserData();
      Map<String, dynamic> facebookData;
      facebookData = userData;
      final curUid = FirebaseAuth.instance.currentUser!.uid;
      DatabaseReference ref = FirebaseDatabase.instance.ref("users/$curUid");

      final snapshot = await ref.get();
      if (snapshot.exists) {
      } else {
        ref.update({
          'username': facebookData['name'],
          'photoUrl': facebookData['picture']['data']['url'],
          'bio': "No bio yet"
        });
      }
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()));
      setState(() {
        _isLoading = false;
      });
    } on FirebaseAuthException catch (e) {
      showSnackBar(e.message!, context); // Displaying the error message
    }
  }

  @override
  void dispose() {
    super.dispose();
    _emailController.dispose();
    _passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(20.0),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // SizedBox(height: 84,),
                    SvgPicture.asset(
                      'assets/ic_instagram.svg',
                      color: primaryColor,
                      height: 64,
                    ),
                    const SizedBox(
                      height: 64,
                    ),
                    //email
                    TextFieldInput(
                        textEditingController: _emailController,
                        hintText: "Enter your Email",
                        textInputType: TextInputType.emailAddress),
                    //password
                    const SizedBox(
                      height: 24,
                    ),
                    TextFieldInput(
                        textEditingController: _passwordController,
                        hintText: "Enter your Password",
                        textInputType: TextInputType.text,
                        isPass: true),
                    const SizedBox(
                      height: 24,
                    ),
                    InkWell(
                      onTap: loginUser,
                      child: Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: const ShapeDecoration(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                          ),
                          color: blueColor,
                        ),
                        child: !_isLoading
                            ? const Text("Log in",
                                style: TextStyle(fontWeight: FontWeight.bold))
                            : const CircularProgressIndicator(
                                color: primaryColor,
                              ),
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    InkWell(
                      onTap: () {
                        signInWithFacebook(context);
                      },
                      child: Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: const ShapeDecoration(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                          ),
                          color: blueColor,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: primaryColor,
                              )
                            : const Text("Log in with Facebook",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: const Text("Don't have an account?"),
                        ),
                        GestureDetector(
                          onTap: navigateToSignup,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: const Text(
                              " Sign up",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ]),
        ),
      ),
    );
  }
}
