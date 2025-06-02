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
import 'pages/settings/profile_settings_page.dart';
import 'pages/settings/contact_requests_page.dart';
import 'pages/settings/invite_earn_page.dart';
import 'pages/settings/purchases_memberships_page.dart';
import 'pages/settings/privacy_settings_page.dart';
import 'pages/settings/language_region_page.dart';
import 'pages/settings/manage_storage_page.dart';
import 'pages/settings/accounts_settings_page.dart';
import 'pages/settings/edit_avatar_page.dart';
import 'pages/settings/help_center_page.dart';
import 'pages/settings/send_feedback_page.dart';
import 'pages/settings/terms_privacy_page.dart';

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
        '/profile-settings': (context) => const ProfileSettingsPage(),
        '/contact-requests': (context) => const ContactRequestsPage(),
        '/invite-earn': (context) => const InviteEarnPage(),
        '/purchases-memberships': (context) => const PurchasesMembershipsPage(),
        '/privacy-settings': (context) => const PrivacySettingsPage(),
        '/language-region': (context) => const LanguageRegionPage(),
        '/manage-storage': (context) => const ManageStoragePage(),
        '/accounts-settings': (context) => const AccountsSettingsPage(),
        '/edit-avatar': (context) => const EditAvatarPage(),
        '/help-center': (context) => const HelpCenterPage(),
        '/send-feedback': (context) => const SendFeedbackPage(),
        '/terms-privacy': (context) => const TermsPrivacyPage(),
      },
    );
  }
}
