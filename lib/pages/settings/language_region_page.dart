import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LanguageRegionPage extends StatelessWidget {
  const LanguageRegionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.green),
          onPressed: () => Navigator.of(context).pop(),
          splashRadius: 24,
          padding: const EdgeInsets.only(left: 16),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            "Language & Region Placeholder\n\nMeeting and calendar times will sync with the creator's time zone and display in your local time zone, including daylight savings.",
            style: GoogleFonts.montserrat(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
} 