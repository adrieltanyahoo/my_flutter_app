import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/user_profile_notifier.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/api_service.dart'; // You may need to implement this
import '../../services/user_profile_service.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({Key? key}) : super(key: key);

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;
  Map<String, bool> _deleteSteps = {
    'startDelete': false,
    'serverDeleted': false,
    'systemMessagesPosted': false,
    'firebaseDeleted': false,
    'complete': false,
  };

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  String? _userPhone;
  String? _userUid;
  String _enteredPhone = '';

  Future<void> _loadUserProfile() async {
    final profile = await UserProfileService.fetchProfile();
    if (profile != null) {
      setState(() {
        _userPhone = profile.phone;
        _userUid = profile.uid;
        _phoneController.text = profile.phone;
      });
    }
  }

  Future<void> _handleDelete() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
      _deleteSteps = {
        'startDelete': true,
        'serverDeleted': false,
        'systemMessagesPosted': false,
        'firebaseDeleted': false,
        'complete': false,
      };
    });
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final phoneNumber = _enteredPhone;
    print('[DeleteAccount] Starting deletion process');
    // Validate phone number
    if (phoneNumber.isEmpty || phoneNumber != _userPhone) {
      setState(() {
        _isSubmitting = false;
        _error = 'Please enter your current phone number to confirm.';
      });
      print('[DeleteAccount] Phone validation failed');
      return;
    }
    try {
      // Step 1: Call API to delete server data and post system messages
      print('[DeleteAccount] Calling API to delete server data...');
      final apiResponse = await ApiService.deleteAccount(
        firebaseUid: _userUid!,
        postSystemMessages: true,
      );
      if (!apiResponse.success) {
        print('[DeleteAccount] API error: \\${apiResponse.message}');
        throw Exception(apiResponse.message ?? 'Failed to delete account on server');
      }
      setState(() {
        _deleteSteps['serverDeleted'] = true;
        _deleteSteps['systemMessagesPosted'] = true;
      });
      print('[DeleteAccount] Server-side deletion successful');
      // Step 2: Delete Firebase Auth user
      print('[DeleteAccount] Deleting Firebase Auth user...');
      if (firebaseUser == null) {
        setState(() {
          _deleteSteps['firebaseDeleted'] = true;
        });
        print('[DeleteAccount] No Firebase user to delete.');
      } else {
        try {
          await firebaseUser.delete();
          setState(() {
            _deleteSteps['firebaseDeleted'] = true;
          });
          print('[DeleteAccount] Firebase user deleted successfully');
        } catch (e) {
          print('[DeleteAccount] Firebase deletion error: \\${e.toString()}');
          // If the error is user-not-found, mark as deleted
          final errorStr = e.toString();
          if (errorStr.contains('user-not-found') || errorStr.contains('[firebase_auth/user-not-found]')) {
            setState(() {
              _deleteSteps['firebaseDeleted'] = true;
            });
            print('[DeleteAccount] Firebase user already deleted.');
          } else {
            setState(() {
              _error = 'Partial Success: Account data removed, but sign out manually.';
            });
          }
        }
      }

      // Step 2.5: Delete Firestore user document and avatar, clear local avatar, reset notifier
      try {
        final profile = await UserProfileService.fetchProfile();
        if (profile != null) {
          // Delete avatar from storage if exists
          if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) {
            await UserProfileService.deleteAvatar(profile.avatarUrl!);
          }
          // Delete Firestore user document
          await FirebaseFirestore.instance.collection('users').doc(profile.uid).delete();
        }
      } catch (e) {
        print('[DeleteAccount] Error deleting Firestore user or avatar: $e');
      }
      // Clear local avatar path from SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('local_avatar_path');
      } catch (e) {
        print('[DeleteAccount] Error clearing local avatar path: $e');
      }
      // Reset UserProfileNotifier
      if (mounted) {
        Provider.of<UserProfileNotifier>(context, listen: false).loadProfile(avatarUrl: null, displayName: '', localAvatarPath: null);
      }
      // Step 3: Sign out
      print('[DeleteAccount] Signing out...');
      await FirebaseAuth.instance.signOut();
      setState(() {
        _deleteSteps['complete'] = true;
      });
      print('[DeleteAccount] Deletion complete, redirecting...');
      // Step 4: Redirect after short delay
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      print('[DeleteAccount] Error: \\${e.toString()}');
      setState(() {
        _error = e.toString();
        _isSubmitting = false;
        _deleteSteps['startDelete'] = false;
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: _isSubmitting || _deleteSteps['startDelete']! ? null : () => Navigator.of(context).pop(),
          splashRadius: 24,
          padding: const EdgeInsets.only(left: 16),
        ),
        title: null,
      ),
      body: SafeArea(
        child: _deleteSteps['startDelete']!
            ? _buildProgress(theme)
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.red, size: 24),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Deleting your account will:',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                            softWrap: false,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _deleteConsequence('Delete your account info and profile photo', theme),
                    _deleteConsequence('Delete you from all groups', theme),
                    _deleteConsequence('Delete your message history and cloud backup', theme),
                    _deleteConsequence('Revoke access tokens across all devices', theme),
                    _deleteConsequence('This action cannot be undone', theme),
                    const SizedBox(height: 32),
                    Text('Enter your phone number to confirm:', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 12),
                    // Phone number input (IntlPhoneField)
                    IntlPhoneField(
                      initialCountryCode: 'MY',
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter phone number',
                        hintStyle: TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        filled: true,
                        fillColor: Colors.grey[900],
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[800]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.green[600]!),
                        ),
                      ),
                      style: TextStyle(color: Colors.white, fontSize: 12),
                      dropdownTextStyle: TextStyle(color: Colors.white, fontSize: 12),
                      onChanged: (phone) {
                        setState(() {
                          String localNumber = phone.number.replaceAll(RegExp(r'\\D'), '');
                          if (localNumber.startsWith('0')) {
                            localNumber = localNumber.substring(1);
                          }
                          String countryCode = phone.countryCode.replaceAll('+', '');
                          _enteredPhone = '+$countryCode$localNumber';
                        });
                      },
                      initialValue: _phoneController.text,
                      disableLengthCheck: true,
                      showDropdownIcon: true,
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: Colors.red, fontSize: 10)),
                            const SizedBox(height: 8),
                            if (!_isSubmitting)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _handleDelete,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[700],
                                  ),
                                  child: Text('Retry', maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleDelete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text('Delete my account', maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _isSubmitting ? null : () => Navigator.pushNamed(context, '/settings/accounts/change-phone-number'),
                        child: Text(
                          'Change phone number instead',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.green, fontSize: 11),
                          softWrap: false,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _deleteConsequence(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 8),
      child: Row(
        children: [
          const Text('• ', style: TextStyle(color: Colors.white, fontSize: 10)),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildProgress(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Account Deletion in Progress', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
          const SizedBox(height: 16),
          _progressStep('Database records removal', _deleteSteps['serverDeleted']!, theme),
          _progressStep('Posting system messages to groups', _deleteSteps['systemMessagesPosted']!, theme),
          _progressStep('Authentication data removal', _deleteSteps['firebaseDeleted']!, theme),
          _progressStep('Finalizing account deletion', _deleteSteps['complete']!, theme),
          if (_isSubmitting && !_deleteSteps['complete']!)
            const Padding(
              padding: EdgeInsets.only(top: 24.0),
              child: Center(child: CircularProgressIndicator(color: Colors.green)),
            ),
          if (_deleteSteps['complete']!)
            Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: Center(
                child: Text('Your account has been deleted successfully. Redirecting...',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _progressStep(String label, bool done, ThemeData theme) {
    return Row(
      children: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: done ? Colors.green : Colors.grey[700],
            shape: BoxShape.circle,
          ),
          child: done ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
        ),
        Flexible(
          child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
} 