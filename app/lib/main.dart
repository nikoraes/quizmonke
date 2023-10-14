import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quizmonke/auth/decorations.dart';
import 'package:quizmonke/auth/policy_screen.dart';
import 'package:quizmonke/firebase_options.dart';
import 'package:quizmonke/home/home_screen.dart';
import 'package:quizmonke/quiz/quiz_screen.dart';

import 'config.dart';

Future<void> main() async {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Pass all uncaught errors from the framework to Crashlytics.
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    await FirebaseAppCheck.instance.activate(
      webProvider: ReCaptchaV3Provider(kWebRecaptchaSiteKey),
      // Default provider for Android is the Play Integrity provider. You can use the "AndroidProvider" enum to choose
      // your preferred provider. Choose from:
      // 1. Debug provider
      // 2. Safety Net provider
      // 3. Play Integrity provider
      androidProvider: AndroidProvider.playIntegrity,
      // Default provider for iOS/macOS is the Device Check provider. You can use the "AppleProvider" enum to choose
      // your preferred provider. Choose from:
      // 1. Debug provider
      // 2. Device Check provider
      // 3. App Attest provider
      // 4. App Attest provider with fallback to Device Check provider (App Attest provider is only available on iOS 14.0+, macOS 14.0+)
      appleProvider: AppleProvider.appAttest,
    );
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        print('User is currently signed out!');
      } else {
        print('User ${user.uid} ${user.displayName} is signed in!');
      }
    });
    FirebaseUIAuth.configureProviders(
        [EmailAuthProvider(), GoogleProvider(clientId: GOOGLE_CLIENT_ID)]);
    runApp(const App());
  }, (error, stack) => FirebaseCrashlytics.instance.recordError(error, stack));
}

class App extends StatelessWidget {
  const App({super.key});

  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance);

  String get initialRoute {
    final user = FirebaseAuth.instance.currentUser;

    return switch (user) {
      null => '/sign-in',
      User(emailVerified: false, email: final String _) => '/verify-email',
      _ => HomeScreen.routeName,
    };
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final buttonStyle = ButtonStyle(
      padding: MaterialStateProperty.all(const EdgeInsets.all(12)),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    return MaterialApp(
      title: 'QuizMonke',
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('nl'),
        Locale('fr'),
        Locale('de'),
        Locale('es'),
        Locale('it'),
        Locale('pt'),
      ],
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromRGBO(9, 9, 9, 1),
        ),
        textTheme: GoogleFonts.latoTextTheme(),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(style: buttonStyle),
        textButtonTheme: TextButtonThemeData(style: buttonStyle),
        outlinedButtonTheme: OutlinedButtonThemeData(style: buttonStyle),
      ),
      navigatorObservers: <NavigatorObserver>[observer],
      initialRoute: initialRoute,
      routes: {
        HomeScreen.routeName: (context) => const HomeScreen(),
        '/sign-in': buildSignInScreen(context),
        '/verify-email': buildEmailVerificationScreen(context),
        '/forgot-password': buildForgotPasswordScreen(context),
        '/profile': buildProfileScreen(context),
      },
    );
  }
}

WidgetBuilder buildSignInScreen(BuildContext context) {
  return (context) {
    return SignInScreen(
      actions: [
        ForgotPasswordAction((context, email) {
          Navigator.pushNamed(
            context,
            '/forgot-password',
            arguments: {'email': email},
          );
        }),
        AuthStateChangeAction((context, state) {
          final user = switch (state) {
            SignedIn(user: final user) => user,
            CredentialLinked(user: final user) => user,
            UserCreated(credential: final cred) => cred.user,
            _ => null,
          };

          switch (user) {
            case User(emailVerified: true):
              FirebaseAnalytics.instance.logLogin();
              Navigator.pushNamedAndRemoveUntil(
                  context, HomeScreen.routeName, (route) => false);
            case User(emailVerified: false, email: final String _):
              Navigator.pushNamed(context, '/verify-email');
          }
        }),
      ],
      styles: const {
        EmailFormStyle(signInButtonVariant: ButtonVariant.filled),
      },
      headerBuilder: headerImage('assets/logo.png'),
      sideBuilder: sideImage('assets/logo.png'),
      subtitleBuilder: (context, action) {
        final actionText = switch (action) {
          AuthAction.signIn => 'Please sign in to continue.',
          AuthAction.signUp => 'Please create an account to continue',
          _ => throw Exception('Invalid action: $action'),
        };

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('Welcome to QuizMonke! $actionText.'),
        );
      },
      footerBuilder: (context, action) {
        final actionText = switch (action) {
          AuthAction.signIn => 'signing in',
          AuthAction.signUp => 'registering',
          _ => throw Exception('Invalid action: $action'),
        };

        return Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: "By $actionText, you agree to the "),
                  TextSpan(
                    text: "Terms and Conditions",
                    style:
                        const TextStyle(decoration: TextDecoration.underline),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PolicyScreen(
                              title: 'Terms and Conditions',
                              mdFileName: 'assets/terms_and_conditions.md',
                            ),
                          ),
                        );
                      },
                  ),
                  const TextSpan(text: " and "),
                  TextSpan(
                    text: "Privacy Policy",
                    style:
                        const TextStyle(decoration: TextDecoration.underline),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PolicyScreen(
                              title: 'Privacy Policy',
                              mdFileName: 'assets/privacy_policy.md',
                            ),
                          ),
                        );
                      },
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),

            /* Text(
                    'By $actionText, you agree to our terms and conditions and our privacy policy.',
                    style: const TextStyle(color: Colors.grey),
                  ), */
          ),
        );
      },
    );
  };
}

WidgetBuilder buildEmailVerificationScreen(BuildContext context) {
  return (context) {
    return EmailVerificationScreen(
      headerBuilder: headerIcon(Icons.verified),
      sideBuilder: sideIcon(Icons.verified),
      // actionCodeSettings: actionCodeSettings,
      actions: [
        EmailVerifiedAction(() {
          Navigator.pushNamedAndRemoveUntil(
              context, HomeScreen.routeName, (route) => false);
        }),
        AuthCancelledAction((context) {
          FirebaseUIAuth.signOut(context: context);
          Navigator.pushReplacementNamed(context, '/sign-in');
        }),
      ],
    );
  };
}

WidgetBuilder buildForgotPasswordScreen(BuildContext context) {
  return (context) {
    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    return ForgotPasswordScreen(
      email: arguments?['email'],
      headerMaxExtent: 200,
      headerBuilder: headerIcon(Icons.lock),
      sideBuilder: sideIcon(Icons.lock),
    );
  };
}

WidgetBuilder buildProfileScreen(BuildContext context) {
  return (context) {
    return ProfileScreen(
      actions: [
        SignedOutAction((context) {
          Navigator.pushReplacementNamed(context, '/sign-in');
        }),
      ],
      // actionCodeSettings: actionCodeSettings,
    );
  };
}
