import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instagram_clone/resources/auth_methods.dart';
import 'package:instagram_clone/screens/home_screen.dart';
import 'package:instagram_clone/utils/colors.dart';
import 'package:instagram_clone/utils/utils.dart';
import 'package:instagram_clone/widgets/text_field_input.dart';

import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  Uint8List? _image;
  bool _isLoading = false;

  void signUpUser() async {
    setState(() {
      _isLoading = true;
    });
    if(_image != null){
      String res = await AuthMethods().signUpUser(
          email: _emailController.text,
          password: _passwordController.text,
          username: _usernameController.text,
          bio: _bioController.text,
          file: _image!);
      setState(() {
        _isLoading = false;
      });

      if (res != 'sign up success') {
        showSnackBar(res, context);
      } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => HomeScreen()));
      }
    }else{
      showSnackBar("You must upload your avatar!", context);
      setState(() {
        _isLoading = false;
      });
    }

  }

  void selectImage() async {
    Uint8List imagePicked = await pickImage(ImageSource.gallery);
    setState(() {
      _image = imagePicked;
    });
  }

  void navigateToLogin() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const LoginScreen()));
  }

  @override
  void dispose() {
    super.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _bioController.dispose();
    _usernameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.all(30),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/ic_instagram.svg',
                    color: primaryColor,
                    height: 64,
                  ),
                  SizedBox(
                    height: 22,
                  ),
                  Stack(
                    children: [
                      _image != null
                          ? CircleAvatar(
                              radius: 54,
                              backgroundImage: MemoryImage(_image!),
                            )
                          : CircleAvatar(
                              radius: 54,
                              backgroundImage: NetworkImage(
                                  "https://images.squarespace-cdn.com/content/v1/54b7b93ce4b0a3e130d5d232/1519987020970-8IQ7F6Z61LLBCX85A65S/icon.png?format=1000w"),
                            ),
                      Positioned(
                        bottom: -10,
                        left: 70,
                        child: IconButton(
                            icon: Icon(Icons.add_a_photo),
                            onPressed: selectImage),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 24,
                  ),
                  //username
                  TextFieldInput(
                      textEditingController: _usernameController,
                      hintText: "Enter your Username",
                      textInputType: TextInputType.text),
                  //password
                  SizedBox(
                    height: 12,
                  ),
                  //email
                  TextFieldInput(
                      textEditingController: _emailController,
                      hintText: "Enter your Email",
                      textInputType: TextInputType.emailAddress),
                  //password
                  SizedBox(
                    height: 12,
                  ),
                  TextFieldInput(
                      textEditingController: _passwordController,
                      hintText: "Enter your Password",
                      textInputType: TextInputType.text,
                      isPass: true),
                  SizedBox(
                    height: 12,
                  ),
                  //bio
                  TextFieldInput(
                      textEditingController: _bioController,
                      hintText: "Enter your bio",
                      textInputType: TextInputType.text),
                  //password
                  SizedBox(
                    height: 24,
                  ),
                  InkWell(
                    onTap: signUpUser,
                    child: Container(
                      child: _isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                color: primaryColor,
                              ),
                            )
                          : Text("Sign up",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                      width: double.infinity,
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                        color: blueColor,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 12,
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        child: Text("Do you already have an account?"),
                        padding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      GestureDetector(
                        onTap: navigateToLogin,
                        child: Container(
                          child: Text(
                            " Log in",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
