import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _phoneController = TextEditingController();
  final _hobbiesController = TextEditingController();
  String _timeZone = '';
  String _language = 'English';
  String? _avatarPath;
  bool _isLoading = false;

  // Add a list of IATA time zones (sample, you can expand as needed)
  static const List<String> iataTimeZones = [
    'UTC',
    'Asia/Kuala_Lumpur',
    'Asia/Singapore',
    'Asia/Tokyo',
    'Asia/Shanghai',
    'Asia/Bangkok',
    'Europe/London',
    'Europe/Paris',
    'Europe/Berlin',
    'America/New_York',
    'America/Los_Angeles',
    'America/Chicago',
    'America/Sao_Paulo',
    'Australia/Sydney',
    'Africa/Johannesburg',
    // ... add more as needed
  ];

  @override
  void initState() {
    super.initState();
    _loadTimeZone();
  }

  Future<void> _loadTimeZone() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedTimeZone = prefs.getString('cached_time_zone');
    
    if (cachedTimeZone != null) {
      setState(() {
        _timeZone = cachedTimeZone;
      });
      if (kDebugMode) {
        print('📱 Loaded timezone from storage: $_timeZone');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _jobTitleController.dispose();
    _phoneController.dispose();
    _hobbiesController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      String prefillPhoneNumber = args['phoneNumber'] ?? '';
      String uid = args['uid'] ?? '';

      if (kDebugMode) {
        print('📲 Pre-filling profile setup:');
        print('   • UID: $uid');
        print('   • Phone: $prefillPhoneNumber');
      }

      // Set this into your controllers or state
      _phoneController.text = prefillPhoneNumber;
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _avatarPath = pickedFile.path;
      });
    }
  }

  Future<void> _completeSetup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (kDebugMode) {
        print('📝 Saving profile data:');
        print('   • Name: ${_nameController.text}');
      }

      // TODO: Save profile data to your backend

      // Navigate to messages page
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/messages');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving profile:');
        print('   • Error: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save profile. Please try again.',
              style: GoogleFonts.montserrat(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  Text(
                    'Set Up Profile',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please provide your information',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Profile Picture Placeholder
                  Center(
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: _pickAvatar,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _avatarPath != null
                              ? FileImage(File(_avatarPath!))
                              : null,
                            child: _avatarPath == null
                                ? Text(
                                    _nameController.text.isNotEmpty
                                        ? _nameController.text.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
                                        : 'AT',
                                    style: GoogleFonts.montserrat(fontSize: 32, color: Colors.grey[600]),
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.green[600],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Display Name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Display Name',
                      labelStyle: GoogleFonts.montserrat(color: Colors.grey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Email
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: GoogleFonts.montserrat(color: Colors.grey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Company Name
                  TextFormField(
                    controller: _companyController,
                    decoration: InputDecoration(
                      labelText: 'Company Name',
                      labelStyle: GoogleFonts.montserrat(color: Colors.grey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Job Title
                  TextFormField(
                    controller: _jobTitleController,
                    decoration: InputDecoration(
                      labelText: 'Job Title',
                      labelStyle: GoogleFonts.montserrat(color: Colors.grey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Phone Number (not editable)
                  TextFormField(
                    controller: _phoneController,
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      labelStyle: GoogleFonts.montserrat(color: Colors.grey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Time Zone (dropdown)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return DropdownButtonFormField<String>(
                        value: iataTimeZones.contains(_timeZone) ? _timeZone : null,
                        items: iataTimeZones.map((tz) => DropdownMenuItem(
                          value: tz,
                          child: SizedBox(
                            width: constraints.maxWidth - 60, // prevent overflow
                            child: Text(tz, style: GoogleFonts.montserrat(), overflow: TextOverflow.ellipsis),
                          ),
                        )).toList(),
                        onChanged: (val) {
                          setState(() {
                            _timeZone = val ?? '';
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Time Zone',
                          labelStyle: GoogleFonts.montserrat(color: Colors.grey[600]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (val) => val == null || val.isEmpty ? 'Please select a time zone' : null,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Language (not editable, link to settings)
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/settings-language-timezone');
                    },
                    child: AbsorbPointer(
                      child: TextFormField(
                        initialValue: _language,
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: 'Language',
                          labelStyle: GoogleFonts.montserrat(color: Colors.grey[600]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Hobbies & Interests
                  TextFormField(
                    controller: _hobbiesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Hobbies & Interests',
                      labelStyle: GoogleFonts.montserrat(color: Colors.grey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Share your hobbies and interests',
                      hintStyle: GoogleFonts.montserrat(color: Colors.grey[400]),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Save Changes Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _completeSetup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Save Changes',
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 