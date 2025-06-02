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

  Future<Map<String, String>> fetchCountryAndTimeZone() async {
    if (kDebugMode) {
      print('\n🔍 Starting country code and time zone detection in splash page...');
    }

    final prefs = await SharedPreferences.getInstance();
    final cachedCountry = prefs.getString('cached_country_code');
    final cachedTimeZone = prefs.getString('cached_time_zone');
    final lastFetch = prefs.getInt('cached_country_timestamp') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Use cache if less than 24h old
    if (cachedCountry != null && cachedTimeZone != null && (now - lastFetch) < 86400000) {
      if (kDebugMode) {
        print('📱 Using cached country code: $cachedCountry');
        print('   • Last fetched: ${DateTime.fromMillisecondsSinceEpoch(lastFetch)}');
        print('📱 Using cached time zone: $cachedTimeZone');
      }
      return {'country': cachedCountry, 'timeZone': cachedTimeZone};
    }

    String countryCode = 'US';
    String timeZone = 'UTC';

    try {
      if (kDebugMode) {
        print('📡 Attempting to call ipapi.co...');
      }
      // Country
      final countryRes = await http.get(
        Uri.parse('https://ipapi.co/country'),
        headers: {
          'User-Agent': 'WorkApp/1.0',
          'Accept': 'text/plain',
        },
      ).timeout(const Duration(seconds: 5));
      if (countryRes.statusCode == 200) {
        final code = countryRes.body.trim();
        if (code.length == 2) {
          countryCode = code;
        }
      }
      // Time zone
      final tzRes = await http.get(
        Uri.parse('https://ipapi.co/timezone'),
        headers: {
          'User-Agent': 'WorkApp/1.0',
          'Accept': 'text/plain',
        },
      ).timeout(const Duration(seconds: 5));
      if (tzRes.statusCode == 200) {
        final tz = tzRes.body.trim();
        if (tz.isNotEmpty) {
          timeZone = tz;
        }
      }
      await prefs.setString('cached_country_code', countryCode);
      await prefs.setString('cached_time_zone', timeZone);
      await prefs.setInt('cached_country_timestamp', now);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching country/timezone: $e');
      }
    }
    return {'country': countryCode, 'timeZone': timeZone};
  }

  void _continue() async {
    setState(() => _loading = true);
    final result = await fetchCountryAndTimeZone();
    setState(() => _loading = false);
    if (!mounted) return;
    if (kDebugMode) {
      print('Final country code: ${result['country']}');
      print('Final time zone: ${result['timeZone']}');
    }
    Navigator.pushReplacementNamed(context, '/auth', arguments: result);
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
            ..onTap = () => Navigator.pushNamed(context, '/terms-privacy'),
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
            ..onTap = () => Navigator.pushNamed(context, '/terms-privacy'),
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