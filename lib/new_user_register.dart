import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:wildlife_tracker/auth_services.dart';

class NewUserRegister extends StatefulWidget {
  NewUserRegister({Key? key}) : super(key: key);

  @override
  _NewUserRegisterState createState() => _NewUserRegisterState();
}

class _NewUserRegisterState extends State<NewUserRegister> {
  // a global key to for the form to track its state and validation
  final _formKey = GlobalKey<FormState>();

  // text editing controllers to get the input that the user enters in the text fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // a variable to check if the registration is in progress
  bool _isRegistering = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void register() async {
    if (!_formKey.currentState!.validate()) {
      return; // do nothing when the form is not valid
    }

    setState(() {
      _isRegistering = true;
    });

    try {
      await authServices.value.signUp(
        email: _emailController.text,
        password: _passwordController.text,
      );
      print("User registered successfully");
    } on FirebaseAuthException catch (e) {
      print(e.message);
    } finally {
      setState(() {
        _isRegistering = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Welcome to Wildlife Tracker",
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: "Poppins",
          ),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    "Create a new account using your email\n address and password",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontFamily: "Poppins"),
                  ),
                  SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextFormField(
                            controller: _emailController,
                            autocorrect: false,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "Email",
                              hintText: "Enter your email address",
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  !value.contains("@")) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            autocorrect: false,
                            obscureText: true,
                            obscuringCharacter: "●",
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "Password",
                              hintText: "Enter your password",
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  value.length < 6) {
                                return 'Password must be at least 6 characters long';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          _isRegistering
                              ? CircularProgressIndicator()
                              : ElevatedButton(
                                  onPressed: register,
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
                                  child: Text("Create Account"),
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
