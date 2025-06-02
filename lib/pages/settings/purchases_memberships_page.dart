import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PurchasesMembershipsPage extends StatelessWidget {
  const PurchasesMembershipsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      ),
      body: Center(child: Text('Purchases & Memberships Placeholder', style: GoogleFonts.montserrat(fontSize: 18))),
    );
  }
} 