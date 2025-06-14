import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/user_profile_notifier.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class ChangePhoneNumberPage extends StatefulWidget {
  const ChangePhoneNumberPage({Key? key}) : super(key: key);

  @override
  State<ChangePhoneNumberPage> createState() => _ChangePhoneNumberPageState();
}

class _ChangePhoneNumberPageState extends State<ChangePhoneNumberPage> {
  // Steps: intro, enterNew, verifyNew, notifyContacts, migrating, complete
  String _step = 'intro';
  String _currentPhone = '';
  String _newPhone = '';
  String _otp = '';
  String _verificationId = '';
  bool _notifyContacts = true;
  bool _loading = false;
  String _countryCode = '+60';
  String _errorText = '';

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _currentPhone = user?.phoneNumber ?? '';
      _newPhone = '';
    });
  }

  void _showSnack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white)),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _sendOtp() async {
    setState(() { _errorText = ''; });
    // Validate phone number (example: not same as current)
    if (_newPhone == _currentPhone || _newPhone.isEmpty) {
      setState(() { _errorText = 'Invalid Mobile Number'; }); // E264
      return;
    }
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _newPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-retrieval or instant verification
        },
        verificationFailed: (FirebaseAuthException e) {
          _showSnack('Verification failed: \\${e.message}', error: true);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _step = 'verifyNew';
          });
          _showSnack('OTP sent to new phone number.');
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      _showSnack('Failed to send OTP: \\${e.toString()}', error: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtpAndUpdate() async {
    if (_otp.length < 6) {
      _showSnack('Please enter the 6-digit OTP.', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otp,
      );
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user logged in');
      await user.updatePhoneNumber(credential);
      // TODO: Call your backend API to update phone and notify contacts
      setState(() => _step = 'notifyContacts');
      _showSnack('Phone number updated.');
    } catch (e) {
      _showSnack('Failed to verify OTP: \\${e.toString()}', error: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _migratePhoneNumber() async {
    setState(() => _loading = true);
    try {
      // TODO: Call your backend API to migrate phone and notify contacts
      await Future.delayed(const Duration(seconds: 2));
      setState(() => _step = 'complete');
      _showSnack('Phone number migration complete.');
    } catch (e) {
      _showSnack('Migration failed: \\${e.toString()}', error: true);
      setState(() => _step = 'notifyContacts');
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Change Phone Number', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 24),
        Text('Current phone number:', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        Text(_currentPhone, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Text('Enter new phone number:', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        IntlPhoneField(
          initialCountryCode: 'MY',
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter your phone number',
            isDense: true,
            errorText: _errorText.isEmpty ? null : _errorText,
          ),
          style: Theme.of(context).textTheme.bodyLarge,
          onChanged: (phone) {
            setState(() {
              _countryCode = '+${phone.countryCode}';
              String localNumber = phone.number.replaceAll(RegExp(r'\D'), '');
              if (localNumber.startsWith('0')) {
                localNumber = localNumber.substring(1);
              }
              String countryCode = phone.countryCode.replaceAll('+', '');
              _newPhone = '+$countryCode$localNumber';
              // Clear error text when a valid number is entered
              if (phone.number.isNotEmpty && phone.number != _currentPhone) {
                _errorText = '';
              }
            });
          },
          onCountryChanged: (country) {
            // Clear error text when country changes
            setState(() {
              _errorText = '';
            });
          },
        ),
        const SizedBox(height: 16),
        // Visual step indicator: phone -> arrow -> phone
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone_android, color: Colors.grey, size: 32),
            SizedBox(width: 12),
            Icon(Icons.arrow_forward, color: Colors.black, size: 28),
            SizedBox(width: 12),
            Icon(Icons.phone_android, color: Colors.green, size: 32),
          ],
        ),
        const SizedBox(height: 16),
        // Process explanation text
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: "This process will move your account to a new phone number. You'll need to verify both numbers.\n\n", style: Theme.of(context).textTheme.bodyMedium),
              TextSpan(text: "Your contacts will be notified of your number change.\n\n", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
              TextSpan(text: "Your chat history, profile information, and account settings will be transferred to the new number.", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: (_newPhone.isNotEmpty && _newPhone != _currentPhone && !_loading)
                ? Colors.green[600]
                : Colors.grey[400],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: (_loading || _newPhone.isEmpty || _newPhone == _currentPhone) ? null : _sendOtp,
          child: _loading
              ? const CircularProgressIndicator()
              : Text('Start Process', style: Theme.of(context).textTheme.labelLarge),
        ),
      ],
    );
  }

  Widget _buildVerifyNew() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Verify New Phone', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 24),
        Text('Enter the 6-digit OTP sent to $_newPhone:', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        TextField(
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: '------',
            isDense: true,
          ),
          style: Theme.of(context).textTheme.bodyLarge,
          onChanged: (v) => setState(() => _otp = v),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _loading ? null : _verifyOtpAndUpdate,
          child: _loading ? const CircularProgressIndicator() : Text('Verify OTP', style: Theme.of(context).textTheme.labelLarge),
        ),
      ],
    );
  }

  Widget _buildNotifyContacts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Notify Contacts', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 24),
        Row(
          children: [
            Checkbox(
              value: _notifyContacts,
              onChanged: (v) => setState(() => _notifyContacts = v ?? true),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text('Notify my contacts about my new phone number', style: Theme.of(context).textTheme.bodyMedium)),
          ],
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _loading ? null : _migratePhoneNumber,
          child: _loading ? const CircularProgressIndicator() : Text('Proceed', style: Theme.of(context).textTheme.labelLarge),
        ),
      ],
    );
  }

  Widget _buildMigrating() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 48),
        Center(child: CircularProgressIndicator()),
        const SizedBox(height: 24),
        Text('Migrating phone number...', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }

  Widget _buildComplete() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 48),
        Icon(Icons.check_circle, color: Colors.green, size: 64),
        const SizedBox(height: 24),
        Text('Phone number changed successfully!', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    switch (_step) {
      case 'intro':
        content = _buildIntro();
        break;
      case 'verifyNew':
        content = _buildVerifyNew();
        break;
      case 'notifyContacts':
        content = _buildNotifyContacts();
        break;
      case 'migrating':
        content = _buildMigrating();
        break;
      case 'complete':
        content = _buildComplete();
        break;
      default:
        content = _buildIntro();
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.green),
          onPressed: () {
            if (_step == 'intro') {
              Navigator.of(context).pop();
            } else {
              setState(() {
                _step = 'intro';
              });
            }
          },
        ),
        title: null,
        backgroundColor: null,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: content,
        ),
      ),
    );
  }
} 