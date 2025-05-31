import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class PermissionsPage extends StatefulWidget {
  const PermissionsPage({super.key});

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> {
  bool _mediaPermission = true;
  bool _contactsPermission = true;
  bool _notificationPermission = true;
  bool _isLoading = false;
  Map<String, dynamic>? _userDetails;

  @override
  void initState() {
    super.initState();
    _checkCurrentPermissions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      setState(() {
        _userDetails = args;
      });
      if (kDebugMode) {
        print('📱 User details received in permissions page:');
        print('   • Details: $_userDetails');
      }
    }
  }

  Future<void> _checkCurrentPermissions() async {
    if (kDebugMode) {
      print('🔍 Checking current permissions...');
    }

    final contacts = await Permission.contacts.status;
    final photos = await Permission.photos.status;
    final notification = await Permission.notification.status;

    setState(() {
      _contactsPermission = contacts.isGranted;
      _mediaPermission = photos.isGranted;
      _notificationPermission = notification.isGranted;
    });

    if (kDebugMode) {
      print('📱 Current permission status:');
      print('   • Contacts: ${contacts.name}');
      print('   • Media: ${photos.name}');
      print('   • Notifications: ${notification.name}');
    }
  }

  Future<void> _requestPermissions() async {
    setState(() => _isLoading = true);

    try {
      if (kDebugMode) {
        print('🔐 Requesting permissions...');
      }

      // Request contacts permission if enabled
      if (_contactsPermission) {
        final contactStatus = await Permission.contacts.request();
        if (kDebugMode) {
          print('👥 Contacts permission: ${contactStatus.name}');
        }
      }

      // Request media permission if enabled
      if (_mediaPermission) {
        final mediaStatus = await Permission.photos.request();
        if (kDebugMode) {
          print('🖼️ Media permission: ${mediaStatus.name}');
        }
      }

      // Request notification permission if enabled
      if (_notificationPermission) {
        final notificationStatus = await Permission.notification.request();
        if (kDebugMode) {
          print('🔔 Notification permission: ${notificationStatus.name}');
        }
      }

      // Navigate to profile setup page after permissions are handled
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/profile-setup',
          arguments: _userDetails,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error requesting permissions:');
        print('   • Error: $e');
      }
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to request permissions. Please try again.',
              style: GoogleFonts.montserrat(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                Text(
                  'App Permissions',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please enable the following permissions to use all features of the app',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 48),
                // Media Permission
                _buildPermissionTile(
                  title: 'Media',
                  subtitle: 'Access your photos and videos',
                  icon: Icons.photo_library,
                  value: _mediaPermission,
                  onChanged: (value) => setState(() => _mediaPermission = value),
                ),
                const Divider(),
                // Contacts Permission
                _buildPermissionTile(
                  title: 'Contacts',
                  subtitle: 'Access your contacts',
                  icon: Icons.contacts,
                  value: _contactsPermission,
                  onChanged: (value) => setState(() => _contactsPermission = value),
                ),
                const Divider(),
                // Notification Permission
                _buildPermissionTile(
                  title: 'Notifications',
                  subtitle: 'Send you notifications',
                  icon: Icons.notifications,
                  value: _notificationPermission,
                  onChanged: (value) => setState(() => _notificationPermission = value),
                ),
                const SizedBox(height: 32),
                // Continue Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _requestPermissions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Continue',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.green[600], size: 28),
      title: Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.montserrat(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.green[600],
      ),
    );
  }
} 