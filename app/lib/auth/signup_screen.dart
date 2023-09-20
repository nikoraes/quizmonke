import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quizmonke/auth/authentication.dart';

class EmailPasswordSignup extends StatefulWidget {
  static String routeName = '/signup';
  const EmailPasswordSignup({Key? key}) : super(key: key);

  @override
  EmailPasswordSignupState createState() => EmailPasswordSignupState();
}

class EmailPasswordSignupState extends State<EmailPasswordSignup> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void signUpUser() async {
    context.read<FirebaseAuthMethods>().signUpWithEmail(
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
                onPressed: signUpUser,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: const Text(
                  "Sign up",
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  "Cancel",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }
}
