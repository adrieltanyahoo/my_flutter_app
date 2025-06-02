import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Tasks Screen',
        style: GoogleFonts.montserrat(fontSize: 24),
      ),
    );
  }
} 