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
import 'pages/settings/change_phone_number_page.dart';
import 'pages/settings/delete_account_page.dart';

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
          brightness: Brightness.light,
          scaffoldBackgroundColor: Colors.white,
          primaryColor: Colors.green[600],
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.green[600]),
            titleTextStyle: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          textTheme: GoogleFonts.montserratTextTheme().copyWith(
            titleLarge: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
            titleMedium: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[700]),
            titleSmall: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[600]),
            bodyLarge: GoogleFonts.montserrat(fontSize: 14, color: Colors.black),
            bodyMedium: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[600]),
            bodySmall: GoogleFonts.montserrat(fontSize: 8, color: Colors.grey[600]),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
            labelStyle: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600]),
            hintStyle: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[400]),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              textStyle: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
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
          '/settings/accounts/change-phone-number': (context) => const ChangePhoneNumberPage(),
          '/settings/accounts/delete-account': (context) => const DeleteAccountPage(),
        },
      ),
    );
  }
}
