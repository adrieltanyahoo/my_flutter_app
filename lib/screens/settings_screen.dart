import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/permission_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/settings/user_avatar.dart';
import '../services/user_profile_service.dart';
import 'package:provider/provider.dart';
import '../services/user_profile_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationGranted = false;
  bool _contactsGranted = false;
  bool _mediaGranted = false;
  bool _isLoading = false;
  String? _avatarUrl;
  String _displayName = '';

  @override
  void initState() {
    super.initState();
    _refreshPermissions();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await UserProfileService.fetchProfile();
      if (profile != null) {
        setState(() {
          _avatarUrl = profile.avatarUrl;
          _displayName = profile.displayName;
        });
        // Load local avatar path from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final savedAvatarPath = prefs.getString('local_avatar_path');
        // Update global notifier with latest profile and avatar info
        Provider.of<UserProfileNotifier>(context, listen: false).loadProfile(
          avatarUrl: profile.avatarUrl,
          displayName: profile.displayName,
          localAvatarPath: (savedAvatarPath != null && File(savedAvatarPath).existsSync()) ? savedAvatarPath : null,
        );
      }
    } catch (e) {
      print('❌ Error loading profile: $e');
    }
  }

  Future<void> _refreshPermissions() async {
    setState(() => _isLoading = true);
    try {
      // Get both system permissions and saved preferences
      final systemPermissions = await PermissionService.checkSystemPermissions();
      final savedPreferences = await PermissionService.loadPermissionPreferences();

      setState(() {
        // Use saved preferences instead of system permissions
        _notificationGranted = savedPreferences['notification'] ?? true;
        _contactsGranted = savedPreferences['contacts'] ?? true;
        _mediaGranted = savedPreferences['media'] ?? true;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestPermission(Permission permission, String type) async {
    setState(() => _isLoading = true);
    try {
      final status = await permission.request();
      
      // Update saved preferences based on the new permission status
      final preferences = await PermissionService.loadPermissionPreferences();
      preferences[type] = status.isGranted;
      
      await PermissionService.savePermissionPreferences(
        media: preferences['media'] ?? true,
        contacts: preferences['contacts'] ?? true,
        notification: preferences['notification'] ?? true,
      );

      await _refreshPermissions();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        children: [
          // Avatar and User
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/edit-avatar'),
              child: Consumer<UserProfileNotifier>(
                builder: (context, notifier, _) {
                  return Column(
                    children: [
                      UserAvatar(
                        networkUrl: notifier.avatarUrl,
                        initials: notifier.displayName.isNotEmpty
                            ? notifier.displayName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
                            : 'U',
                        radius: 36,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notifier.displayName.isNotEmpty ? notifier.displayName : 'User',
                        style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ],
                  );
                },
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
          _permissionStatusTile(
            context,
            'Notifications',
            _notificationGranted,
            Icons.notifications,
          ),
          _permissionStatusTile(
            context,
            'Contacts',
            _contactsGranted,
            Icons.contacts,
          ),
          _permissionStatusTile(
            context,
            'Media',
            _mediaGranted,
            Icons.photo_library,
          ),
          const SizedBox(height: 16),
          // Support Section
          _sectionHeader('Support'),
          _settingsTile(context, Icons.help_outline, 'Help Center', 'Get help and find answers', '/help-center'),
          _settingsTile(context, Icons.feedback_outlined, 'Send Feedback', 'Help us improve the app', '/send-feedback'),
          _settingsTile(context, Icons.description, 'Terms & Privacy Policy', 'Review our terms & privacy policy', '/terms-privacy'),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Log out',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
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

  Widget _permissionStatusTile(BuildContext context, String title, bool granted, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: openAppSettings,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.green[600], size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: granted ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    granted ? 'Granted' : 'Not granted',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: granted ? Colors.green[800] : Colors.red[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 