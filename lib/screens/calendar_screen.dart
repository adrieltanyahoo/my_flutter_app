import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Calendar Screen',
        style: GoogleFonts.montserrat(fontSize: 24),
      ),
    );
  }
} 