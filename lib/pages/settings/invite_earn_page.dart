import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InviteEarnPage extends StatelessWidget {
  const InviteEarnPage({super.key});

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
      body: Center(child: Text('Invite & Earn Placeholder', style: GoogleFonts.montserrat(fontSize: 18))),
    );
  }
} 