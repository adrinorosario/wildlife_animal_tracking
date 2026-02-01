import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wildlife_tracker/auth_services.dart';
import 'package:wildlife_tracker/main.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:wildlife_tracker/new_user_register.dart';
import 'package:sign_in_button/sign_in_button.dart';

class UserLogin extends StatefulWidget {
  const UserLogin({super.key});

  @override
  _UserLoginState createState() => _UserLoginState();
}

class _UserLoginState extends State<UserLogin> {
  // a global key to for the form to track its state and validation
  final _formKey = GlobalKey<FormState>();

  // text editing controllers to get the input that the user enters in the text fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // a variable to check if the registration is in progress
  bool _isLoggingIn = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void login() async {
    if (!_formKey.currentState!.validate()) {
      return; // do nothing when not validated
    }

    setState(() {
      _isLoggingIn = true;
    });

    try {
      await authServices.value.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      print("User logged in successfully");
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => MyHomePage(title: "Wildlife Tracker"),
        ),
      );
    } on FirebaseAuthException catch (e) {
      print(e.message);
    } finally {
      setState(() {
        _isLoggingIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: const Text(
        //   "Welcome back",
        //   style: TextStyle(
        //     color: Colors.black,
        //     fontSize: 24,
        //     fontWeight: FontWeight.bold,
        //     fontFamily: "Poppins",
        //   ),
        // ),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    "Welcome back",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Poppins",
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    "Log in to Wildlife Tracker using your email\n address and password",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontFamily: "Poppins"),
                  ),
                  SizedBox(height: 16),
                  Form(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextFormField(
                            autocorrect: false,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "Email",
                              hintText: "Enter your email address",
                            ),
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            autocorrect: false,
                            obscureText: true,
                            obscuringCharacter: "●",
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "Password",
                              hintText: "Enter your password",
                            ),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(200, 50),
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              textStyle: TextStyle(
                                fontSize: 16,
                                fontFamily: "Poppins",
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: Text("Login"),
                          ),
                          const SizedBox(height: 0),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account?",
                                style: TextStyle(fontSize: 16),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (context) => NewUserRegister(),
                                    ),
                                  );
                                },
                                child: Text(
                                  "Create one",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),

                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Or login with",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blueGrey,
                                ),
                              ),
                              const SizedBox(height: 10),

                              //google sign in button
                              SignInButton(
                                onPressed: () =>
                                    AuthServices().signInWithGoogle(),
                                Buttons.google,
                                text: "Login with Google",
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(0),
                                ),
                                // textStyle: TextStyle(
                                //   fontSize: 16,
                                //   fontFamily: "Poppins",
                                // ),
                                clipBehavior: Clip.hardEdge,
                              ),
                              const SizedBox(height: 0),

                              //apple sign in button
                              SignInButton(
                                onPressed: () {},
                                Buttons.apple,
                                text: "Login with Apple",
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
