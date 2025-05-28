import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';

class AuthPage extends StatefulWidget {
  final String? detectedCountry;

  const AuthPage({super.key, this.detectedCountry});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final TextEditingController _controller = TextEditingController();
  PhoneNumber? _number;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.detectedCountry != null) {
      _number = PhoneNumber(isoCode: widget.detectedCountry);
      if (kDebugMode) {
        print('Initializing with country code: ${widget.detectedCountry}');
      }
    }
  }

  Future<void> _sendOTP() async {
    if (_number?.phoneNumber == null) {
      setState(() {
        _errorMessage = 'Please enter a valid phone number';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // TODO: Implement Firebase Phone Auth
      await Future.delayed(const Duration(seconds: 2)); // Simulated delay
      if (kDebugMode) {
        print('Would send OTP to: ${_number?.phoneNumber}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send OTP. Please try again.';
      });
      if (kDebugMode) {
        print('Error sending OTP: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Phone Authentication',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter your phone number',
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We\'ll send you a verification code',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
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
                      _number = number;
                      if (kDebugMode) {
                        print('Phone number changed: ${number.phoneNumber}');
                      }
                    },
                    onInputValidated: (bool value) {
                      if (kDebugMode) {
                        print('Phone number valid: $value');
                      }
                    },
                    selectorConfig: const SelectorConfig(
                      selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                    ),
                    ignoreBlank: false,
                    autoValidateMode: AutovalidateMode.onUserInteraction,
                    selectorTextStyle: const TextStyle(color: Colors.black),
                    initialValue: _number,
                    textFieldController: _controller,
                    formatInput: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: true,
                      decimal: true,
                    ),
                    inputDecoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Phone Number',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: GoogleFonts.montserrat(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
                          'Send Code',
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
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
} 