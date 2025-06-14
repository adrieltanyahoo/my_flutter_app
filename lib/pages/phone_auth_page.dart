import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:flutter/foundation.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'otp_page.dart';

// Enum must be at the top level, not inside any class
enum LoadingState { idle, sendingCode, verifyingCode }

class PhoneAuthPage extends StatefulWidget {
  const PhoneAuthPage({super.key});

  @override
  State<PhoneAuthPage> createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends State<PhoneAuthPage> {
  // Controllers
  final TextEditingController _phoneController = TextEditingController();
  
  // Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _verificationId = '';
  String _completePhoneNumber = '';
  bool _isLoading = false;
  String _errorMessage = '';
  
  // UI States
  
  // Loading States
  LoadingState _loadingState = LoadingState.idle;
  bool get isLoading => _loadingState != LoadingState.idle;
  
  // Timer for resend OTP
  Timer? _timer;
  int _remainingTime = 0;
  bool _canResendOTP = false;
  
  // Rate limiting
  DateTime? _lastVerificationAttempt;
  static const _minimumVerificationInterval = Duration(minutes: 1);
  
  // Consistent styling
  late final TextStyle montserratStyle;
  
  // Add these state variables at the top with other state declarations
  bool _isInitialized = false;
  User? _currentUser;
  String _detectedCountryCode = 'US';
  String _e164PhoneNumber = '';
  String _timeZone = 'UTC';
  String _lastCountryDialCode = '1'; // Default to US dial code

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('🚀 PhoneAuthPage initialized');
    }
    // Initialize states
    _remainingTime = 0;
    _canResendOTP = false;
    montserratStyle = GoogleFonts.montserrat();
    // Set initial dial code for detected country
    _lastCountryDialCode = _getDialCodeForCountry(_detectedCountryCode);
    // Check for existing auth state
    _checkAuthState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      initializePhoneNumber(args['country'] ?? 'US');
      _timeZone = args['timeZone'] ?? 'UTC';
      // No need to set dial code here; will be set by IntlPhoneField
    } else {
      initializePhoneNumber('US');
      _timeZone = 'UTC';
      _lastCountryDialCode = '1';
    }
  }

  Future<void> initializePhoneNumber(String countryCode) async {
    if (mounted) {
      setState(() {
        _detectedCountryCode = countryCode;
        _completePhoneNumber = '';
        _errorMessage = '';
      });
    }
  }

  void startResendOTPTimer() {
    setState(() {
      _remainingTime = 60;
      _canResendOTP = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime == 0) {
        timer.cancel();
        setState(() {
          _canResendOTP = true;
        });
      } else {
        setState(() {
          _remainingTime--;
        });
      }
    });
  }

  void _checkAuthState() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      _currentUser = _auth.currentUser;

        if (kDebugMode) {
        print('👤 Checking auth state, but always forcing user to go through flow');
        }
        
      // Do NOT auto-skip; always let the user continue through phone auth, permissions, and profile setup

    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking auth state: $e');
      }
      setState(() {
        _errorMessage = 'Error checking authentication state';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialized = true;
        });
      }
    }
  }

  // Function to send OTP
  Future<void> _sendOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    // Always reconstruct the E.164 phone number from the latest input
    print('[PhoneAuth] Raw input from controller: "${_phoneController.text}"');
    String rawNumber = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (rawNumber.startsWith('0')) {
      rawNumber = rawNumber.substring(1);
    }
    String dialCode = _lastCountryDialCode.replaceAll('+', '');
    String e164 = '+$dialCode$rawNumber';
    // E.164 validation: starts with +, followed by 10-15 digits
    final e164Regex = RegExp(r'^\+[1-9]\d{9,14}$');
    final isValid = e164Regex.hasMatch(e164);
    print('[PhoneAuth] dialCode: $dialCode, rawNumber: $rawNumber, e164: $e164, isValid: $isValid');
    if (e164.isEmpty || !isValid) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Please enter a valid phone number.');
      return;
    }
    _e164PhoneNumber = e164;
    try {
      if (kDebugMode) {
        await FirebaseAuth.instance.setSettings(appVerificationDisabledForTesting: true);
      }
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _e164PhoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Optionally handle auto-verification
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _isLoading = false;
            _errorMessage = e.message ?? 'Verification failed. Please try again.';
          });
          _showSnackBar('Verification failed: \\${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _isLoading = false;
            _errorMessage = '';
          });
          _showSnackBar('OTP sent to \\$_e164PhoneNumber');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpPage(
                verificationId: verificationId,
                phoneNumber: _e164PhoneNumber,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      _showSnackBar('Error sending OTP: \\$e');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _navigateToHomeScreen() {
    Navigator.pushReplacementNamed(context, '/messages');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                Text(
                  'WorkApp',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 36,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 3.3,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Work Lives Here',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    letterSpacing: 1.5,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 48),
                IntlPhoneField(
                  controller: _phoneController,
                  initialCountryCode: _detectedCountryCode,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter phone number',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: const TextStyle(fontSize: 16),
                  dropdownTextStyle: const TextStyle(fontSize: 16),
                  onChanged: (phone) {
                    // Always format to E.164: +<countryCode><number-without-leading-zero>
                    String localNumber = phone.number.replaceAll(RegExp(r'\D'), '');
                    if (localNumber.startsWith('0')) {
                      localNumber = localNumber.substring(1);
                    }
                    String dialCode = phone.countryCode.replaceAll('+', '');
                    setState(() {
                      _e164PhoneNumber = '+$dialCode$localNumber';
                      _lastCountryDialCode = dialCode;
                      // Clear error message when a valid number is entered
                      if (phone.number.isNotEmpty) {
                        _errorMessage = '';
                      }
                    });
                  },
                  onCountryChanged: (country) {
                    // Clear error message when country changes
                    setState(() {
                      _errorMessage = '';
                      _lastCountryDialCode = country.dialCode;
                    });
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendOTP,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Send Code', maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper to get dial code for a country code
  String _getDialCodeForCountry(String countryCode) {
    switch (countryCode.toUpperCase()) {
      case 'MY':
        return '60';
      case 'SG':
        return '65';
      case 'US':
        return '1';
      case 'GB':
        return '44';
      default:
        return '1';
    }
  }
} 