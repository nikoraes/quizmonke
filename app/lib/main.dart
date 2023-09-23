import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quizmonke/auth/authentication.dart';
import 'package:quizmonke/auth/signup_screen.dart';
import 'package:quizmonke/firebase_options.dart';
import 'package:quizmonke/home_screen.dart';
import 'package:quizmonke/auth/login_screen.dart';
import 'package:quizmonke/photo_screen.dart';
import 'package:quizmonke/quiz_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user == null) {
      print('User is currently signed out!');
    } else {
      print('User ${user.uid} ${user.displayName} is signed in!');
    }
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FirebaseAuthMethods>(
          create: (_) => FirebaseAuthMethods(FirebaseAuth.instance),
        ),
        StreamProvider(
          create: (context) => context.read<FirebaseAuthMethods>().authState,
          initialData: null,
        ),
      ],
      child: MaterialApp(
          title: 'QuizMonke',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.limeAccent),
            useMaterial3: true,
          ),
          home: const AuthWrapper(),
          routes: {
            LoginScreen.routeName: (context) => const LoginScreen(),
            EmailPasswordSignup.routeName: (context) =>
                const EmailPasswordSignup(),
            QuizScreen.routeName: (context) => const QuizScreen(),
            PhotoScreen.routeName: (context) => const PhotoScreen(),
          }),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User?>();

    if (firebaseUser != null) {
      return const MyHomePage();
    }
    return const LoginScreen();
  }
}
