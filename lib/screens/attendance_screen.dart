import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Attendance Screen',
        style: GoogleFonts.montserrat(fontSize: 24),
      ),
    );
  }
} 