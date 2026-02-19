import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wildlife_tracker/auth_services.dart';
import 'package:wildlife_tracker/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wildlife_tracker/new_user_register.dart';
import 'package:sign_in_button/sign_in_button.dart';

import 'package:wildlife_tracker/theme_colors.dart';

class UserLogin extends StatefulWidget {
  const UserLogin({super.key});

  @override
  _UserLoginState createState() => _UserLoginState();
}

class _UserLoginState extends State<UserLogin> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoggingIn = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoggingIn = true);
    try {
      await authServices.value.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(
            builder: (context) => MyHomePage(title: "Wildlife Tracker"),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? "Login Failed"),
          backgroundColor: SavannahColors.orangeCaramel,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: SavannahColors.beigeLight,
      // Change this to true to allow scrolling when the keyboard is up
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // 1. Background Image
          Container(
            height: screenSize.height,
            width: screenSize.width,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1516422317950-ad91d73a54d4?auto=format&fit=crop&q=80&w=1000',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 2. Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  SavannahColors.beigeLight.withOpacity(0.4),
                  SavannahColors.beigeLight.withOpacity(0.9),
                  SavannahColors.beigeLight,
                ],
              ),
            ),
          ),
          // 3. Content
          SafeArea(
            child: Center(
              // Centers content on larger screens
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      const Icon(
                        Icons.terrain_rounded,
                        size: 80,
                        color: SavannahColors.greenDeep,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "ANIMAP",
                        style: TextStyle(
                          letterSpacing: 4.0,
                          fontWeight: FontWeight.w900,
                          color: SavannahColors.textBlack,
                          fontSize: 24,
                        ),
                      ),
                      const Text(
                        "PROTECT • MONITOR • CONSERVE",
                        style: TextStyle(
                          letterSpacing: 1.2,
                          color: SavannahColors.orangeCaramel,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Input Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: SavannahColors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: SavannahColors.beigeDark),
                        ),
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: _emailController,
                              label: "EMAIL",
                              icon: Icons.email_outlined,
                              hint: "ranger@savannah.com",
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              controller: _passwordController,
                              label: "PASSWORD",
                              icon: Icons.lock_outline_rounded,
                              hint: "••••••••",
                              isPassword: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),

                      if (_isLoggingIn)
                        const CircularProgressIndicator(
                          color: SavannahColors.greenDeep,
                        )
                      else
                        ElevatedButton(
                          onPressed: login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SavannahColors.greenDeep,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 60),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            "LOGIN",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),

                      const SizedBox(height: 15),

                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => const NewUserRegister(),
                            ),
                          );
                        },
                        child: const Text.rich(
                          TextSpan(
                            text: "New to the field? ",
                            style: TextStyle(color: SavannahColors.textGrey),
                            children: [
                              TextSpan(
                                text: "Create Account",
                                style: TextStyle(
                                  color: SavannahColors.orangeCaramel,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        "OR CONNECT WITH",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: SavannahColors.textGrey,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _socialButton(
                            Buttons.google,
                            () => authServices.value.signInWithGoogle(),
                          ),
                          const SizedBox(width: 25),
                          _socialButton(Buttons.apple, () {}),
                        ],
                      ),
                      const SizedBox(
                        height: 40,
                      ), // Increased bottom padding to avoid overflow
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: SavannahColors.orangeCaramel,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(color: SavannahColors.textBlack, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: SavannahColors.textGrey.withOpacity(0.5),
            ),
            prefixIcon: Icon(icon, color: SavannahColors.greenOlive, size: 20),
            filled: true,
            fillColor: SavannahColors.beigeLight.withOpacity(0.3),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: SavannahColors.beigeDark),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: SavannahColors.orangeSand,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _socialButton(Buttons button, VoidCallback onTap) {
    bool isGoogle = button == Buttons.google;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: SavannahColors.white,
          shape: BoxShape.circle,
          border: Border.all(color: SavannahColors.beigeDark),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: isGoogle
            ? Image.network(
                'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg', // More reliable Google icon URL
                height: 24,
                width: 24,
                // If the link fails, show a generic icon instead of crashing/disappearing
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.g_mobiledata, color: Colors.red, size: 24),
              )
            : SignInButton(button, mini: true, onPressed: onTap),
      ),
    );
  }
}
