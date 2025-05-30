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
    
    // Check for existing auth state
    _checkAuthState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    initializePhoneNumber();
  }

  Future<void> initializePhoneNumber() async {
    String countryCode;
    try {
      final args = ModalRoute.of(context)?.settings.arguments as String?;
      countryCode = args ?? 'US';  // Default to US if no country code is passed
      if (kDebugMode) {
        print('📱 Phone Auth Page - Initializing with country code: $countryCode');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Phone Auth Page - Error getting country code: $e');
        print('   Falling back to US');
      }
      countryCode = 'US';  // Default to US if all else fails
    }
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

  Future<void> _checkAuthState() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Check if there's a current user
      _currentUser = _auth.currentUser;

      if (_currentUser != null) {
        if (kDebugMode) {
          print('👤 User already signed in:');
          print('   • UID: ${_currentUser?.uid}');
          print('   • Phone: ${_currentUser?.phoneNumber}');
        }
        
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/permissions',
            arguments: {
              'uid': _currentUser?.uid,
              'phoneNumber': _currentUser?.phoneNumber,
            },
          );
        }
      } else {
        if (kDebugMode) {
          print('👤 No user currently signed in');
        }
      }
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
    if (_e164PhoneNumber.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your phone number.';
        _isLoading = false;
      });
      return;
    }
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
          _showSnackBar('Verification failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _isLoading = false;
            _errorMessage = '';
          });
          _showSnackBar('OTP sent to $_e164PhoneNumber');
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
      _showSnackBar('Error sending OTP: $e');
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
                  onChanged: (phone) {
                    setState(() {
                      _e164PhoneNumber = phone.completeNumber;
                      _errorMessage = '';
                    });
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendOTP,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Send Code'),
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
} 