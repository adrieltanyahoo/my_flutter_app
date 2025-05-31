import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'phone_auth_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _loading = false;
  String _selectedLanguage = 'English';

  Future<String> fetchCountryCode() async {
    if (kDebugMode) {
      print('\n🔍 Starting country code detection in splash page...');
    }

    final prefs = await SharedPreferences.getInstance();
    final cachedCountry = prefs.getString('cached_country_code');
    final lastFetch = prefs.getInt('cached_country_timestamp') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Use cache if less than 24h old
    if (cachedCountry != null && (now - lastFetch) < 86400000) {
      if (kDebugMode) {
        print('📱 Using cached country code: $cachedCountry');
        print('   • Last fetched: ${DateTime.fromMillisecondsSinceEpoch(lastFetch)}');
      }
      return cachedCountry;
    }

    try {
      if (kDebugMode) {
        print('📡 Attempting to call ipapi.co...');
      }

      // Using ipapi.co service
      final apiUrl = 'https://ipapi.co/country';
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'User-Agent': 'WorkApp/1.0',
          'Accept': 'text/plain',
        },
      ).timeout(const Duration(seconds: 5));

      if (kDebugMode) {
        print('\n📥 Response from ipapi.co:');
        print('   • Status Code: ${response.statusCode}');
        print('   • Response Body: "${response.body}"');
        print('   • Headers: ${response.headers}');
      }

      if (response.statusCode == 200) {
        final countryCode = response.body.trim();
        if (countryCode.length == 2) {  // Valid 2-letter country code
          if (kDebugMode) {
            print('✅ Successfully detected country: $countryCode');
          }
          await prefs.setString('cached_country_code', countryCode);
          await prefs.setInt('cached_country_timestamp', now);
          return countryCode;
        } else {
          if (kDebugMode) {
            print('⚠️ Invalid country code format received: "$countryCode"');
          }
        }
      } else {
        if (kDebugMode) {
          print('❌ Unexpected status code: ${response.statusCode}');
          print('   • Response body: ${response.body}');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('\n❌ Error in country detection:');
        print('   • Error type: ${e.runtimeType}');
        print('   • Error message: $e');
        print('   • Stack trace: $stackTrace');
      }
    }

    // Device Locale Fallback
    final localeCountryCode = ui.window.locale.countryCode;
    if (localeCountryCode != null) {
      if (kDebugMode) {
        print('📱 Falling back to device locale: $localeCountryCode');
      }
      return localeCountryCode;
    }

    // Final Fallback
    if (kDebugMode) {
      print('⚠️ All detection methods failed, using US as fallback');
    }
    return 'US';
  }

  void _continue() async {
    setState(() => _loading = true);
    final countryCode = await fetchCountryCode();
    setState(() => _loading = false);
    if (!mounted) return;
    
    if (kDebugMode) {
      print('Final country code: $countryCode');
    }
    
    Navigator.pushReplacementNamed(context, '/auth', arguments: countryCode);
  }

  @override
  Widget build(BuildContext context) {
    final textSpan = TextSpan(
      style: GoogleFonts.montserrat(
        fontSize: 14,
        color: Colors.grey[800],
        height: 1.5,
      ),
      children: [
        const TextSpan(text: 'Read our '),
        TextSpan(
          text: 'Privacy Policy',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: Colors.blue,
            height: 1.5,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => Navigator.pushNamed(context, '/privacy-policy'),
        ),
        const TextSpan(text: '. Tap "Agree and continue" to accept the '),
        TextSpan(
          text: 'Terms of Service',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: Colors.blue,
            height: 1.5,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => Navigator.pushNamed(context, '/terms-of-service'),
        ),
        const TextSpan(text: '.'),
      ],
    );

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
                RichText(
                  text: textSpan,
                ),
                const SizedBox(height: 24),
                // Action Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _continue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _loading 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Agree and continue',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                  ),
                ),
                const SizedBox(height: 24),
                // Language Selector
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedLanguage,
                      isExpanded: true,
                      icon: const Icon(Icons.language),
                      items: ['English']
                          .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                ),
                              ),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedLanguage = newValue;
                          });
                        }
                      },
                    ),
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