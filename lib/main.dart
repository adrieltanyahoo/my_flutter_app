import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'pages/splash_page.dart';
import 'pages/phone_auth_page.dart';
import 'pages/permissions_page.dart';
import 'pages/profile_setup_page.dart';
import 'pages/messages_page.dart';
import 'pages/privacy_policy_page.dart';
import 'pages/terms_of_service_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();

  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      await user.getIdToken(true); // Force refresh
    } catch (e) {
      await FirebaseAuth.instance.signOut();
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WorkApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/',  // Always start from splash page
      routes: {
        '/': (context) => const SplashPage(),
        '/auth': (context) => const PhoneAuthPage(),
        '/permissions': (context) => const PermissionsPage(),
        '/profile-setup': (context) => const ProfileSetupPage(),
        '/messages': (context) => const MessagesPage(),
        '/privacy-policy': (context) => const PrivacyPolicyPage(),
        '/terms-of-service': (context) => const TermsOfServicePage(),
      },
    );
  }
}
