import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsPrivacyPage extends StatelessWidget {
  const TermsPrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Text(
              '‹',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
            splashRadius: 24,
            padding: const EdgeInsets.only(left: 16),
          ),
          bottom: TabBar(
            labelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 14),
            tabs: const [
              Tab(text: 'Terms'),
              Tab(text: 'Privacy'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _TermsOfServiceContent(),
            _PrivacyPolicyContent(),
          ],
        ),
      ),
    );
  }
}

class _TermsOfServiceContent extends StatelessWidget {
  const _TermsOfServiceContent();
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Terms of Service',
            style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Terms of Service content will go here...\n\nThis is a placeholder for your legal terms. Add paragraphs as needed for clarity and compliance.',
            style: GoogleFonts.montserrat(fontSize: 12, height: 1.7),
          ),
        ],
      ),
    );
  }
}

class _PrivacyPolicyContent extends StatelessWidget {
  const _PrivacyPolicyContent();
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Privacy Policy',
            style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Privacy Policy content will go here...\n\nThis is a placeholder for your privacy policy. Add paragraphs as needed for clarity and compliance.',
            style: GoogleFonts.montserrat(fontSize: 12, height: 1.7),
          ),
        ],
      ),
    );
  }
} 