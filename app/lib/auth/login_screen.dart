import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quizmonke/auth/policy_dialog.dart';
import 'package:quizmonke/auth/signup_screen.dart';
import 'package:quizmonke/auth/authentication.dart';

// TODO: https://github.com/RobertBrunhage/Youtube-Tutorials/blob/master/terms_and_policy/assets/privacy_policy.md

class LoginScreen extends StatefulWidget {
  static String routeName = '/login';
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void loginUser() {
    context.read<FirebaseAuthMethods>().loginWithEmail(
          email: emailController.text,
          password: passwordController.text,
          context: context,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Center(
        child: Container(
          constraints: BoxConstraints.loose(const Size(400, 600)),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Image(
                image: AssetImage("assets/logo.png"),
                height: 80,
              ),
              Text(
                "QuizMonke",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.08),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(64),
                    borderSide: const BorderSide(
                      width: 0,
                      style: BorderStyle.none,
                    ),
                  ),
                  filled: true,
                  hintText: 'Email',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(64),
                    borderSide: const BorderSide(
                      width: 0,
                      style: BorderStyle.none,
                    ),
                  ),
                  filled: true,
                  hintText: 'Password',
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: loginUser,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(250, 40),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: const Text(
                  "Login",
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  context.read<FirebaseAuthMethods>().signInWithGoogle(context);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(250, 40),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image(
                      image: AssetImage('assets/google_logo.png'),
                      height: 25.0,
                    ),
                    Text(
                      "Google Sign In",
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, EmailPasswordSignup.routeName);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(250, 40),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: const Text(
                  "Sign up",
                  style: TextStyle(fontSize: 16),
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: "By logging in you agree to the "),
                    TextSpan(
                      text: "Terms and Conditions",
                      style:
                          const TextStyle(decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          showDialog(
                              context: context,
                              builder: (dialogContext) {
                                return const PolicyDialog(
                                  mdFileName: "assets/terms_and_conditions.md",
                                );
                              });
                        },
                    ),
                    const TextSpan(text: " and "),
                    const TextSpan(
                      text: "Privacy Policy",
                      style: TextStyle(decoration: TextDecoration.underline),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      )),
    );
  }
}
