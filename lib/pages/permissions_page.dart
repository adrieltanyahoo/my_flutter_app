import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import '../services/permission_service.dart';

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
    _loadSavedPreferences();
  }

  Future<void> _loadSavedPreferences() async {
    final preferences = await PermissionService.loadPermissionPreferences();
    setState(() {
      _mediaPermission = preferences['media'] ?? true;
      _contactsPermission = preferences['contacts'] ?? true;
      _notificationPermission = preferences['notification'] ?? true;
    });
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

  Future<void> _requestPermissions() async {
    setState(() => _isLoading = true);

    try {
      if (kDebugMode) {
        print('🔐 Requesting permissions...');
      }

      // Save preferences before requesting permissions
      await PermissionService.savePermissionPreferences(
        media: _mediaPermission,
        contacts: _contactsPermission,
        notification: _notificationPermission,
      );

      // Show a single dialog explaining all permissions that will be requested
      if (_contactsPermission || _mediaPermission || _notificationPermission) {
        final shouldProceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('App Permissions', style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Workaton needs the following permissions:',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  if (_contactsPermission)
                    Text('• Contacts - to help you connect with friends', style: GoogleFonts.montserrat(fontSize: 13)),
                  if (_mediaPermission)
                    Text('• Media - to set profile picture and share photos', style: GoogleFonts.montserrat(fontSize: 13)),
                  if (_notificationPermission)
                    Text('• Notifications - for messages and updates', style: GoogleFonts.montserrat(fontSize: 13)),
                  const SizedBox(height: 12),
                  Text(
                    'You will be asked to grant these permissions one by one.',
                    style: GoogleFonts.montserrat(fontSize: 13),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Skip All', style: GoogleFonts.montserrat(fontSize: 14)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Continue', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );

        if (shouldProceed == true) {
          final denied = <String>[];
          // Request permissions one after another
          if (_contactsPermission) {
            final contactStatus = await Permission.contacts.request();
            if (kDebugMode) {
              print('👥 Contacts permission: ${contactStatus.name}');
            }
            if (await Permission.contacts.isPermanentlyDenied) {
              await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Contacts Permission Blocked', style: GoogleFonts.montserrat()),
                  content: Text('You have permanently denied Contacts permission. Please enable it in system settings.', style: GoogleFonts.montserrat()),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('OK', style: GoogleFonts.montserrat()),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        openAppSettings();
                      },
                      child: Text('Open Settings', style: GoogleFonts.montserrat()),
                    ),
                  ],
                ),
              );
            }
            final finalStatus = await Permission.contacts.status;
            if (!finalStatus.isGranted) denied.add('Contacts');
          }

          if (_mediaPermission) {
            final mediaStatus = await Permission.photos.request();
            if (kDebugMode) {
              print('🖼️ Media permission: ${mediaStatus.name}');
            }
            if (await Permission.photos.isPermanentlyDenied) {
              await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Media Permission Blocked', style: GoogleFonts.montserrat()),
                  content: Text('You have permanently denied Media permission. Please enable it in system settings.', style: GoogleFonts.montserrat()),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('OK', style: GoogleFonts.montserrat()),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        openAppSettings();
                      },
                      child: Text('Open Settings', style: GoogleFonts.montserrat()),
                    ),
                  ],
                ),
              );
            }
            final finalStatus = await Permission.photos.status;
            if (!finalStatus.isGranted) denied.add('Media');
          }

          if (_notificationPermission) {
            final notificationStatus = await Permission.notification.request();
            if (kDebugMode) {
              print('🔔 Notification permission: ${notificationStatus.name}');
            }
            if (await Permission.notification.isPermanentlyDenied) {
              await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Notification Permission Blocked', style: GoogleFonts.montserrat()),
                  content: Text('You have permanently denied Notification permission. Please enable it in system settings.', style: GoogleFonts.montserrat()),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('OK', style: GoogleFonts.montserrat()),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        openAppSettings();
                      },
                      child: Text('Open Settings', style: GoogleFonts.montserrat()),
                    ),
                  ],
                ),
              );
            }
            final finalStatus = await Permission.notification.status;
            if (!finalStatus.isGranted) denied.add('Notifications');
          }

          // Show summary if any permissions were denied
          if (denied.isNotEmpty && mounted) {
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Permissions Denied', style: GoogleFonts.montserrat()),
                content: Text(
                  'The following permissions were not granted: ${denied.join(', ')}. Some features may not work as expected.',
                  style: GoogleFonts.montserrat(),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('OK', style: GoogleFonts.montserrat()),
                  ),
                ],
              ),
            );
          }
        }

        // Navigate to profile setup page after permissions are handled
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/profile-setup',
            arguments: {
              'phoneNumber': _userDetails?['phoneNumber'],
              'timeZone': _userDetails?['timeZone'],
            },
          );
        }
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.green),
          onPressed: () => Navigator.of(context).pop(),
          splashRadius: 24,
          padding: const EdgeInsets.only(left: 16),
        ),
      ),
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
                  'Enable permissions so that Workaton can provide you a better service and experience.',
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
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _requestPermissions,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Continue',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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