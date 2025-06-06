import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static const String _mediaKey = 'permission_media';
  static const String _contactsKey = 'permission_contacts';
  static const String _notificationKey = 'permission_notification';

  // Save permission preferences
  static Future<void> savePermissionPreferences({
    required bool media,
    required bool contacts,
    required bool notification,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mediaKey, media);
    await prefs.setBool(_contactsKey, contacts);
    await prefs.setBool(_notificationKey, notification);
  }

  // Load permission preferences
  static Future<Map<String, bool>> loadPermissionPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'media': prefs.getBool(_mediaKey) ?? true,
      'contacts': prefs.getBool(_contactsKey) ?? true,
      'notification': prefs.getBool(_notificationKey) ?? true,
    };
  }

  // Check current system permission status
  static Future<Map<String, bool>> checkSystemPermissions() async {
    final media = await Permission.photos.status;
    final contacts = await Permission.contacts.status;
    final notification = await Permission.notification.status;

    return {
      'media': media.isGranted,
      'contacts': contacts.isGranted,
      'notification': notification.isGranted,
    };
  }
} 