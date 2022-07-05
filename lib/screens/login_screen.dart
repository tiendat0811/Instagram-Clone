import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '/screens/home_screen.dart';
import '/screens/signup_screen.dart';

import '../resources/auth_methods.dart';
import '../utils/utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool showPassword = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    showPassword = false;
  }

  void loginUser() async {
    setState(() {
      _isLoading = true;
    });
    String res = await AuthMethods().loginUser(
        email: _emailController.text, password: _passwordController.text);
    if (res == 'login success') {
      Navigator.of(context).pop();
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => const HomeScreen()));
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
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SignupScreen()));
  }

  // FACEBOOK SIGN IN
  Future<void> signInWithFacebook(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });
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
      String username = "";

      final snapshot = await ref.get();
      if (snapshot.exists) {
      } else {
        if (facebookData['email'] != null) {
          username = facebookData['email']
              .substring(0, facebookData['email'].indexOf('@'));
        } else {
          username = curUid;
        }
        ref.update({
          'username': username,
          'fullname': facebookData['name'],
          'photoUrl': facebookData['picture']['data']['url'],
          'bio': "No bio yet"
        });
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()));
      setState(() {
        _isLoading = false;
      });
    } on FirebaseAuthException catch (e) {
      print(e.toString());
      setState(() {
        _isLoading = false;
      });
    }
  }

  // GOOGLE SIGN IN
  Future<void> signInWithGoogle(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      //store firebase
      if (userCredential.user != null) {
        if (userCredential.additionalUserInfo!.isNewUser) {
          final curUid = FirebaseAuth.instance.currentUser!.uid;
          DatabaseReference ref =
              FirebaseDatabase.instance.ref("users/$curUid");
          var username = googleUser!.email;
          ref.set({
            'username': username.substring(0, username.indexOf('@')),
            'fullname': userCredential.user?.displayName,
            'photoUrl': userCredential.user?.photoURL,
            'bio': "No bio yet"
          });
        }
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()));
      setState(() {
        _isLoading = false;
      });
    } on FirebaseAuthException catch (e) {
      print(e.toString());
      setState(() {
        _isLoading = false;
      });
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
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(20.0),
                  children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // SizedBox(height: 84,),
                          SvgPicture.asset(
                            'assets/ic_instagram.svg',
                            color: Theme.of(context).primaryColor,
                            height: 64,
                          ),
                          const SizedBox(
                            height: 64,
                          ),
                          //email
                          AutofillGroup(
                              child: Column(
                            children: [
                              TextField(
                                controller: _emailController,
                                autofillHints: [AutofillHints.email],
                                decoration: InputDecoration(
                                  labelText: "Email",
                                  border: OutlineInputBorder(
                                      borderSide:
                                          Divider.createBorderSide(context)),
                                  focusedBorder: OutlineInputBorder(
                                      borderSide:
                                          Divider.createBorderSide(context)),
                                  enabledBorder: OutlineInputBorder(
                                      borderSide:
                                          Divider.createBorderSide(context)),
                                  filled: true,
                                  contentPadding: EdgeInsets.all(8),
                                ),
                                keyboardType: TextInputType.emailAddress,
                              ),

                              //password
                              const SizedBox(
                                height: 24,
                              ),
                              TextField(
                                controller: _passwordController,
                                autofillHints: [AutofillHints.password],
                                onEditingComplete: () =>
                                    TextInput.finishAutofillContext(),
                                decoration: InputDecoration(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      // Based on passwordVisible state choose the icon
                                      !showPassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        showPassword = !showPassword;
                                      });
                                    },
                                  ),
                                  labelText: "Password",
                                  border: OutlineInputBorder(
                                      borderSide:
                                          Divider.createBorderSide(context)),
                                  focusedBorder: OutlineInputBorder(
                                      borderSide:
                                          Divider.createBorderSide(context)),
                                  enabledBorder: OutlineInputBorder(
                                      borderSide:
                                          Divider.createBorderSide(context)),
                                  filled: true,
                                  contentPadding: EdgeInsets.all(8),
                                ),
                                keyboardType: TextInputType.text,
                                obscureText: !showPassword,
                              ),
                              const SizedBox(
                                height: 24,
                              ),
                            ],
                          )),
                          InkWell(
                            onTap: loginUser,
                            child: Container(
                                width: double.infinity,
                                alignment: Alignment.center,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: const ShapeDecoration(
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(4)),
                                  ),
                                  color: Colors.blueAccent,
                                ),
                                child: const Text("Log in",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
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
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(4)),
                                ),
                                color: Colors.blueAccent,
                              ),
                              child: const Text("Log in with Facebook",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          InkWell(
                            onTap: () {
                              signInWithGoogle(context);
                            },
                            child: Container(
                              width: double.infinity,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: const ShapeDecoration(
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(4)),
                                ),
                                color: Colors.blueAccent,
                              ),
                              child: const Text("Log in with Google",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: const Text("Don't have an account?"),
                              ),
                              GestureDetector(
                                onTap: navigateToSignup,
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: const Text(
                                    " Sign up",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
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
