import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {
        'question': 'How do I create a group?',
        'answer': 'Tap the "+" icon on the main screen, select "New Group", add participants, and set a group name.'
      },
      {
        'question': 'How do I change my phone number?',
        'answer': 'Go to Settings > Accounts > Change Phone Number. Follow the on-screen instructions to verify your new number.'
      },
      {
        'question': 'How do I delete my account?',
        'answer': 'Go to Settings > Accounts > Delete Account. Follow the steps to permanently remove your account and data.'
      },
      {
        'question': 'How do I manage notifications?',
        'answer': 'Go to Settings > Notifications to customize your notification preferences.'
      },
      {
        'question': 'Is my data private and secure?',
        'answer': 'Workaton uses end-to-end encryption for your messages and stores your data securely. See our Privacy Policy for more.'
      },
      {
        'question': 'How do I contact support?',
        'answer': 'You can contact support via the Send Feedback option in Settings or email us at support@workaton.com.'
      },
    ];
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
        title: null,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: faqs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 20),
        itemBuilder: (context, i) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(faqs[i]['question']!, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 11)),
            const SizedBox(height: 6),
            Text(faqs[i]['answer']!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
} 