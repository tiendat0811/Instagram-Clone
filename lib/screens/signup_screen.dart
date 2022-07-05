import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import '/resources/auth_methods.dart';
import '/screens/home_screen.dart';
import '/utils/utils.dart';
import '/widgets/text_field_input.dart';

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
  final TextEditingController _fullnameController = TextEditingController();
  Uint8List? _image;
  bool _isLoading = false;

  void signUpUser() async {
    setState(() {
      _isLoading = true;
    });
    if (_image != null) {
      String res = await AuthMethods().signUpUser(
          email: _emailController.text,
          password: _passwordController.text,
          username: _usernameController.text,
          bio: _bioController.text,
          fullname: _fullnameController.text,
          file: _image!);
      setState(() {
        _isLoading = false;
      });

      if (res != 'sign up success') {
        showSnackBar(res, context);
      } else {

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()));
      }
    } else {
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
    if (!mounted) return;
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (context) => const LoginScreen()));
  }

  @override
  void dispose() {
    super.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _bioController.dispose();
    _usernameController.dispose();
    _fullnameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: _isLoading
          ? const Center(child: CircularProgressIndicator(),)
          : ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(30),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/ic_instagram.svg',
                    color: Theme.of(context).primaryColor,
                    height: 64,
                  ),
                  const SizedBox(
                    height: 22,
                  ),
                  Stack(
                    children: [
                      _image != null
                          ? CircleAvatar(
                              radius: 54,
                              backgroundImage: MemoryImage(_image!),
                            )
                          : const CircleAvatar(
                              radius: 54,
                              backgroundImage: NetworkImage(
                                  "https://images.squarespace-cdn.com/content/v1/54b7b93ce4b0a3e130d5d232/1519987020970-8IQ7F6Z61LLBCX85A65S/icon.png?format=1000w"),
                            ),
                      Positioned(
                        bottom: -10,
                        left: 70,
                        child: IconButton(
                            icon: const Icon(Icons.add_a_photo),
                            onPressed: selectImage),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  TextFieldInput(
                    textEditingController: _emailController,
                    hintText: "Enter your Email",
                    textInputType: TextInputType.emailAddress,
                    label: "Email",
                  ),
                  //password
                  const SizedBox(
                    height: 12,
                  ),
                  TextFieldInput(
                    textEditingController: _passwordController,
                    hintText: "Enter your Password",
                    textInputType: TextInputType.text,
                    isPass: true,
                    label: "Password",
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  //username
                  TextFieldInput(
                    textEditingController: _usernameController,
                    hintText: "Enter your Username",
                    textInputType: TextInputType.text,
                    label: "Username",
                  ),
                  //password
                  const SizedBox(
                    height: 12,
                  ),

                  TextFieldInput(
                    textEditingController: _fullnameController,
                    hintText: "Enter your fullname",
                    textInputType: TextInputType.text,
                    label: "Fullname",
                  ),
                  //password
                  const SizedBox(
                    height: 12,
                  ),
                  //bio
                  TextFieldInput(
                    textEditingController: _bioController,
                    hintText: "Enter your bio",
                    textInputType: TextInputType.text,
                    label: "Your bio",
                  ),
                  //password
                  const SizedBox(
                    height: 24,
                  ),
                  InkWell(
                    onTap: signUpUser,
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: const ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                        color: Colors.blue,
                      ),
                      child: const Text("Sign up",
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
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: const Text("Do you already have an account?"),
                      ),
                      GestureDetector(
                        onTap: navigateToLogin,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: const Text(
                            " Log in",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
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
