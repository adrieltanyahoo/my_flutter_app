import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:io' show Platform;
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';

class PhoneAuthPage extends StatefulWidget {
  const PhoneAuthPage({super.key});

  @override
  State<PhoneAuthPage> createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends State<PhoneAuthPage> {
  final TextEditingController controller = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? verificationId;
  bool isLoading = false;
  bool showOTP = false;
  String? errorMessage;
  late PhoneNumber number;
  final NetworkInfo networkInfo = NetworkInfo();

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('🚀 PhoneAuthPage initialized');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    initializePhoneNumber();
  }

  Future<void> initializePhoneNumber() async {
    String countryCode;
    try {
      // Get the country code from route arguments, passed from SplashPage
      final args = ModalRoute.of(context)?.settings.arguments as String?;
      countryCode = args ?? 'US';
      if (kDebugMode) {
        print('📱 Phone Auth Page - Received country code: $countryCode');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Phone Auth Page - Error getting country code: $e');
        print('   Falling back to US');
      }
      countryCode = 'US';
    }
    
    if (kDebugMode) {
      print('🔄 Initializing phone number with country code: $countryCode');
    }
    
    setState(() {
      number = PhoneNumber(isoCode: countryCode);
    });

    if (kDebugMode) {
      print('✅ Phone number initialized with:');
      print('   ISO Code: ${number.isoCode}');
      print('   Dial Code: ${number.dialCode}');
    }
  }

  Future<void> verifyPhone() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      if (kDebugMode) {
        print('Attempting to verify phone number: ${number.phoneNumber}');
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: number.phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          if (kDebugMode) {
            print('Auto verification completed');
          }
          await _auth.signInWithCredential(credential);
          // Handle successful verification
        },
        verificationFailed: (FirebaseAuthException e) {
          if (kDebugMode) {
            print('Verification failed: ${e.message}');
          }
          setState(() {
            isLoading = false;
            errorMessage = e.message;
          });
        },
        codeSent: (String vId, int? resendToken) {
          if (kDebugMode) {
            print('Verification code sent');
          }
          setState(() {
            verificationId = vId;
            showOTP = true;
            isLoading = false;
          });
        },
        codeAutoRetrievalTimeout: (String vId) {
          if (kDebugMode) {
            print('Auto retrieval timeout');
          }
          setState(() {
            verificationId = vId;
          });
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error in phone verification: $e');
      }
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to verify phone number: $e';
      });
    }
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
                // Branding Section
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
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1.5,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 48),
                // Phone Input Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: InternationalPhoneNumberInput(
                      onInputChanged: (PhoneNumber number) {
                        if (kDebugMode) {
                          print('📞 Phone number changed:');
                          print('   ISO Code: ${number.isoCode}');
                          print('   Dial Code: ${number.dialCode}');
                          print('   Phone Number: ${number.phoneNumber}');
                        }
                        this.number = number;
                      },
                      selectorConfig: const SelectorConfig(
                        selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                      ),
                      ignoreBlank: false,
                      autoValidateMode: AutovalidateMode.onUserInteraction,
                      selectorTextStyle: const TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                      ),
                      textStyle: const TextStyle(fontSize: 13),
                      initialValue: number,
                      textFieldController: controller,
                      formatInput: true,
                      spaceBetweenSelectorAndTextField: 0,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                        decimal: true,
                      ),
                      inputDecoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter phone number here',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                        contentPadding: const EdgeInsets.only(left: 8, right: 8, bottom: 0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // OTP Field
                if (showOTP) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter verification code',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (code) {
                        // Handle OTP input
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                // Error Message
                if (errorMessage != null) ...[
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                ],
                // Action Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : verifyPhone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            showOTP ? 'Verify Code' : 'SEND OTP',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
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

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
} 