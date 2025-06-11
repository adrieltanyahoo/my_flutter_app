import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'services/user_profile_notifier.dart';
import 'pages/splash_page.dart';
import 'pages/phone_auth_page.dart';
import 'pages/otp_page.dart';
import 'pages/permissions_page.dart';
import 'pages/profile_setup_page.dart';
import 'pages/messages_page.dart';
import 'pages/settings_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserProfileNotifier(),
      child: MaterialApp(
        title: 'WorkApp',
      theme: ThemeData(
          primarySwatch: Colors.green,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.green),
          ),
          textTheme: GoogleFonts.montserratTextTheme(),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashPage(),
          '/auth': (context) => const PhoneAuthPage(),
          '/permissions': (context) => const PermissionsPage(),
          '/profile-setup': (context) => const ProfileSetupPage(),
          '/messages': (context) => const MessagesPage(),
          // Settings routes
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
      ),
    );
  }
}
