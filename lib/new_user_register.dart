import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:wildlife_tracker/auth_services.dart';
import 'package:wildlife_tracker/theme_colors.dart';
import 'package:sign_in_button/sign_in_button.dart';

class NewUserRegister extends StatefulWidget {
  const NewUserRegister({super.key});

  @override
  _NewUserRegisterState createState() => _NewUserRegisterState();
}

class _NewUserRegisterState extends State<NewUserRegister> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegistering = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isRegistering = true);

    try {
      await authServices.value.signUp(
        email: _emailController.text,
        password: _passwordController.text,
      );
      // Pop all routes back to root — AuthLayout will show MyHomePage
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? "Registration Failed"),
            backgroundColor: SavannahColors.orangeCaramel,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Registration Failed: $e"),
            backgroundColor: SavannahColors.orangeCaramel,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: SavannahColors.beigeLight,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
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
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Icon(
                        Icons.person_add_rounded,
                        size: 80,
                        color: SavannahColors.greenDeep,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "JOIN THE HERD",
                        style: TextStyle(
                          letterSpacing: 4.0,
                          fontWeight: FontWeight.w900,
                          color: SavannahColors.textBlack,
                          fontSize: 24,
                        ),
                      ),
                      Text(
                        "START YOUR CONSERVATION JOURNEY",
                        style: TextStyle(
                          letterSpacing: 1.2,
                          color: SavannahColors.orangeCaramel,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 40),
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
                              hint: "new.ranger@savannah.com",
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
                      if (_isRegistering)
                        CircularProgressIndicator(
                          color: SavannahColors.greenDeep,
                        )
                      else
                        ElevatedButton(
                          onPressed: register,
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
                            "CREATE ACCOUNT",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      const SizedBox(height: 15),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text.rich(
                          TextSpan(
                            text: "Already a ranger? ",
                            style: TextStyle(color: SavannahColors.textGrey),
                            children: [
                              TextSpan(
                                text: "Login here",
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
                      Text(
                        "OR SIGN UP WITH",
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
                          _socialButton(Buttons.google, () async {
                            final result = await authServices.value
                                .signInWithGoogle();
                            if (result != null && mounted) {
                              Navigator.of(
                                context,
                              ).popUntil((route) => route.isFirst);
                            }
                          }),
                          const SizedBox(width: 25),
                          _socialButton(Buttons.apple, () {}),
                        ],
                      ),
                      const SizedBox(height: 40),
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
          style: TextStyle(
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
              borderSide: BorderSide(color: SavannahColors.beigeDark),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: SavannahColors.orangeSand,
                width: 2,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Field cannot be empty';
            if (!isPassword && !value.contains("@")) {
              return 'Enter a valid email';
            }
            if (isPassword && value.length < 6) return 'Password too short';
            return null;
          },
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
                'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                height: 24,
                width: 24,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.g_mobiledata, color: Colors.red, size: 24),
              )
            : SignInButton(button, mini: true, onPressed: onTap),
      ),
    );
  }
}
