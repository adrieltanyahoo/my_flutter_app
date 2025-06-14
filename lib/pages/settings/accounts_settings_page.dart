import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/user_profile_notifier.dart';
import 'package:provider/provider.dart';
import 'user_avatar.dart';

class AccountsSettingsPage extends StatelessWidget {
  const AccountsSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProfileNotifier>(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: null,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.green),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // User Profile (centered, no container)
                Center(
                  child: Column(
                    children: [
                      UserAvatar(
                        networkUrl: user.avatarUrl,
                        initials: user.displayName.isNotEmpty
                            ? user.displayName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
                            : 'U',
                        radius: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.displayName.isNotEmpty ? user.displayName : 'User',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Account Options (no container, just ListTiles and dividers)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF128C7E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.phone, color: Color(0xFF128C7E)),
                  ),
                  title: Text('Change Phone Number', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: Colors.black)),
                  subtitle: Text('Update your registered phone number', style: Theme.of(context).textTheme.bodyMedium),
                  onTap: () => Navigator.pushNamed(context, '/settings/accounts/change-phone-number'),
                ),
                const Divider(height: 0),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.delete, color: Colors.red),
                  ),
                  title: Text('Delete Account', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: Colors.black)),
                  subtitle: Text('Permanently delete your account and all data', style: Theme.of(context).textTheme.bodyMedium),
                  onTap: () => Navigator.pushNamed(context, '/settings/accounts/delete-account'),
                ),
                const SizedBox(height: 32),
                // Info Text
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Changing your phone number', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                      TextSpan(text: ' will migrate all your account information, including your profile and messages, to the new number.\n\n', style: Theme.of(context).textTheme.bodyMedium),
                      TextSpan(text: 'Deleting your account', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                      TextSpan(text: ' will remove all your messages, profile information, and remove you from all groups.', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 