import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsPrivacyPage extends StatelessWidget {
  const TermsPrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Check for initialTab argument
    final args = ModalRoute.of(context)?.settings.arguments;
    int initialTab = 0;
    if (args is Map && args['tab'] == 'privacy') initialTab = 1;
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.green),
            onPressed: () => Navigator.of(context).pop(),
            splashRadius: 24,
            padding: const EdgeInsets.only(left: 16),
          ),
          title: null,
          bottom: TabBar(
            labelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 14),
            tabs: const [
              Tab(text: 'Terms of Service'),
              Tab(text: 'Privacy Policy'),
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
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Terms of Service', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 12),
        Text('By using Workaton, you agree to our terms. You must be at least 16 years old to use this service. You are responsible for your account and all activity. Do not use Workaton for illegal, harmful, or abusive activities. We may suspend or terminate accounts that violate our terms.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        Text('Account Responsibilities', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 11)),
        const SizedBox(height: 8),
        Text('You are responsible for keeping your account secure. Do not share your verification codes or passwords. If you believe your account has been compromised, contact support immediately.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        Text('Acceptable Use', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 11)),
        const SizedBox(height: 8),
        Text('You agree not to use Workaton for spam, harassment, or illegal activities. We reserve the right to remove content or suspend accounts that violate these terms.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        Text('Changes to Terms', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 11)),
        const SizedBox(height: 8),
        Text('We may update these terms from time to time. We will notify you of significant changes. Continued use of Workaton means you accept the updated terms.', style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _PrivacyPolicyContent extends StatelessWidget {
  const _PrivacyPolicyContent();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Privacy Policy', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 12),
        Text('Workaton values your privacy. We use end-to-end encryption for your messages. We collect only the information needed to provide and improve our services, such as your phone number, profile information, and usage data. We do not sell your data to third parties. Your data may be shared with trusted partners (e.g., cloud providers) only as needed to operate the service. You can request deletion of your data at any time.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        Text('Data Security', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 11)),
        const SizedBox(height: 8),
        Text('We use industry-standard security measures to protect your data. Access to your data is restricted to authorized personnel only. We regularly review our security practices.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        Text('Your Rights', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 11)),
        const SizedBox(height: 8),
        Text('You can request access to, correction of, or deletion of your data at any time. Contact support@workaton.com for assistance.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        Text('Contact', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 11)),
        const SizedBox(height: 8),
        Text('If you have questions about this privacy policy, contact us at support@workaton.com.', style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
} 