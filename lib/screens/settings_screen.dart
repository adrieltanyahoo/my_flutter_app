import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // No AppBar for the main settings screen (tabbed)
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        children: [
          // Avatar and User
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/edit-avatar'),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    child: Text('U', style: GoogleFonts.montserrat(fontSize: 32, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  Text('User', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          // Account Section
          _sectionHeader('Account'),
          _settingsTile(context, Icons.person, 'Profile', 'View and edit your profile', '/profile-settings'),
          _settingsTile(context, Icons.person_add_alt_1, 'Contact Requests', 'Contacts need approval before messaging', '/contact-requests'),
          _settingsTile(context, Icons.card_giftcard, 'Invite & Earn', 'Invite friends to join', '/invite-earn'),
          _settingsTile(context, Icons.credit_card, 'Purchases & Memberships', 'Manage subscriptions & offers', '/purchases-memberships'),
          _settingsTile(context, Icons.lock, 'Privacy', 'Share live location & visibility settings', '/privacy-settings'),
          _settingsTile(context, Icons.language, 'Language & Region', 'Change app language and time zone', '/language-region'),
          _settingsTile(context, Icons.storage, 'Manage Storage', 'Manage app data and storage usage', '/manage-storage'),
          _settingsTile(context, Icons.phone_android, 'Accounts', 'Change phone number or delete account', '/accounts-settings'),
          const SizedBox(height: 16),
          // App Permissions Section
          _sectionHeader('App Permissions'),
          _permissionTile('Notifications', 'Allow app to send notifications'),
          _permissionTile('Contacts', 'Access to your contacts'),
          _permissionTile('Media', 'Access to photos and videos'),
          const SizedBox(height: 16),
          // Support Section
          _sectionHeader('Support'),
          _settingsTile(context, Icons.help_outline, 'Help Center', 'Get help and find answers', '/help-center'),
          _settingsTile(context, Icons.feedback_outlined, 'Send Feedback', 'Help us improve the app', '/send-feedback'),
          _settingsTile(context, Icons.description, 'Terms & Privacy Policy', 'Review our terms & privacy policy', '/terms-privacy'),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700]),
      ),
    );
  }

  Widget _settingsTile(BuildContext context, IconData icon, String title, String subtitle, String route) {
    return ListTile(
      leading: Icon(icon, color: Colors.green[600]),
      title: Text(title, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[600])),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: () => Navigator.pushNamed(context, route),
    );
  }

  Widget _permissionTile(String title, String subtitle) {
    return SwitchListTile(
      value: true,
      onChanged: (val) {},
      title: Text(title, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[600])),
      activeColor: Colors.green[600],
    );
  }
} 