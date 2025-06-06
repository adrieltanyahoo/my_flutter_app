import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/user_profile_service.dart';

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
  DateTime? _birthday;
  String? _birthdayString;
  bool _isFetching = false;

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
    _loadProfile();
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

  Future<void> _loadProfile() async {
    setState(() => _isFetching = true);
    try {
      final profile = await UserProfileService.fetchProfile();
      if (profile != null) {
        setState(() {
          _nameController.text = profile.displayName;
          _emailController.text = profile.email;
          _companyController.text = profile.company;
          _jobTitleController.text = profile.jobTitle;
          _phoneController.text = profile.phone;
          _hobbiesController.text = profile.hobbies ?? '';
          _avatarPath = null;
          if (profile.birthday != null) {
            _birthdayString = profile.birthday;
            _birthday = DateTime.tryParse(profile.birthday!);
          }
        });
      }
    } catch (e, st) {
      if (kDebugMode) print('❌ Error loading profile: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile. Please check your connection.', style: GoogleFonts.montserrat()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetching = false);
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
    if (!_formKey.currentState!.validate() || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');
      String? avatarUrl;
      if (_avatarPath != null) {
        try {
          avatarUrl = await UserProfileService.uploadAvatar(user.uid, _avatarPath!);
        } catch (e) {
          if (kDebugMode) print('❌ Avatar upload error: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload avatar. Please try again.', style: GoogleFonts.montserrat()),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      } else {
        final existing = await UserProfileService.fetchProfile();
        avatarUrl = existing?.avatarUrl;
      }
      final profile = UserProfile(
        uid: user.uid,
        displayName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        company: _companyController.text.trim(),
        jobTitle: _jobTitleController.text.trim(),
        phone: _phoneController.text.trim(),
        birthday: _birthdayString,
        hobbies: _hobbiesController.text.trim(),
        avatarUrl: avatarUrl,
      );
      await UserProfileService.saveProfile(profile);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/messages');
      }
    } catch (e, st) {
      if (kDebugMode) print('❌ Error saving profile: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile. Please try again.', style: GoogleFonts.montserrat()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isFetching
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 60),
                      Text(
                        'Edit Your Profile',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Update your personal information',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Profile Picture
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
                      const SizedBox(height: 12),
                      Text(
                        'Tap to change your profile picture',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),
                      // Display Name
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Display Name',
                          labelStyle: GoogleFonts.montserrat(color: Colors.grey[600]),
                          prefixIcon: const Icon(Icons.person_outline),
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
                          prefixIcon: const Icon(Icons.email_outlined),
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
                          prefixIcon: const Icon(Icons.apartment_outlined),
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
                          prefixIcon: const Icon(Icons.work_outline),
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
                          prefixIcon: const Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'To change phone numbers, go to the settings page',
                        style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      // Birthday (bank app style)
                      GestureDetector(
                        onTap: () async {
                          FocusScope.of(context).unfocus();
                          final now = DateTime.now();
                          final initialDate = _birthday ?? DateTime(now.year - 18, now.month, now.day);
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: initialDate,
                            firstDate: DateTime(now.year - 100),
                            lastDate: DateTime(now.year - 10),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: Colors.green[600]!,
                                    onPrimary: Colors.white,
                                    onSurface: Colors.black,
                                  ),
                                  textButtonTheme: TextButtonThemeData(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.green[600],
                                    ),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              _birthday = picked;
                              _birthdayString = picked.toIso8601String().split('T')[0];
                            });
                          }
                        },
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: TextEditingController(text: _birthday != null ? _birthdayString : ''),
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Birthday',
                              labelStyle: GoogleFonts.montserrat(color: Colors.grey[600]),
                              prefixIcon: const Icon(Icons.cake_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              hintText: 'Select your birthday',
                            ),
                            validator: (value) {
                              if (_birthday == null) {
                                return 'Please select your birthday';
                              }
                              return null;
                            },
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
                          prefixIcon: const Icon(Icons.interests_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          hintText: 'Share your hobbies and interests',
                          hintStyle: GoogleFonts.montserrat(color: Colors.grey[400]),
                          helperText: 'Tell us what you enjoy doing in your free time',
                          helperStyle: GoogleFonts.montserrat(color: Colors.grey[600]),
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