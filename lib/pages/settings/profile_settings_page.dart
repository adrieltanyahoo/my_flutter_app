import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../services/user_profile_service.dart';
import 'package:provider/provider.dart';
import '../../services/user_profile_notifier.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'user_avatar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Adriel Tan');
  final _emailController = TextEditingController(text: 'adriel@example.com');
  final _companyController = TextEditingController(text: 'Workaton');
  final _jobTitleController = TextEditingController(text: 'Product Manager');
  final _phoneController = TextEditingController(text: '+60126591036');
  final _hobbiesController = TextEditingController();
  DateTime? _birthday;
  String? _birthdayString;
  String? _avatarPath;
  String? _profileAvatarUrl;
  bool _isLoading = false;
  bool _isFetching = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _isEditing = false;
  }

  Future<void> _loadProfile() async {
    setState(() => _isFetching = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAvatarPath = prefs.getString('local_avatar_path');
      final profile = await UserProfileService.fetchProfile();
      if (profile != null) {
        setState(() {
          _nameController.text = profile.displayName;
          _emailController.text = profile.email;
          _companyController.text = profile.company;
          _jobTitleController.text = profile.jobTitle;
          _phoneController.text = profile.phone;
          _hobbiesController.text = profile.hobbies ?? '';
          _avatarPath = (savedAvatarPath != null && File(savedAvatarPath).existsSync()) ? savedAvatarPath : null;
          _profileAvatarUrl = profile.avatarUrl;
          if (profile.birthday != null) {
            _birthdayString = profile.birthday;
            _birthday = DateTime.tryParse(profile.birthday!);
          }
        });
      }
    } catch (e, st) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile. Please check your connection.', style: GoogleFonts.montserrat(fontSize: 12)),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('❌ Error loading profile: $e\n$st');
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // Compress the image
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        pickedFile.path,
        targetPath,
        quality: 70,
        minWidth: 300,
        minHeight: 300,
        format: CompressFormat.jpeg,
      );
      final localPath = compressedFile?.path ?? pickedFile.path;
      setState(() {
        _avatarPath = localPath;
      });
      // Persist the local path
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('local_avatar_path', localPath);
      // Update notifier with local avatar path
      if (mounted) {
        Provider.of<UserProfileNotifier>(context, listen: false).setLocalAvatarPath(localPath);
      }
      // Start background upload
      _uploadAvatarInBackground(localPath);
    }
  }

  Future<void> _uploadAvatarInBackground(String imagePath) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final avatarUrl = await UserProfileService.uploadAvatar(user.uid, imagePath);
      // Update Firestore with new avatar URL
      final profile = await UserProfileService.fetchProfile();
      if (profile != null) {
        final updatedProfile = UserProfile(
          uid: profile.uid,
          displayName: profile.displayName,
          email: profile.email,
          company: profile.company,
          jobTitle: profile.jobTitle,
          phone: profile.phone,
          birthday: profile.birthday,
          hobbies: profile.hobbies,
          avatarUrl: avatarUrl,
        );
        await UserProfileService.saveProfile(updatedProfile);
        // Update notifier
        if (mounted) {
          Provider.of<UserProfileNotifier>(context, listen: false).updateProfile(
            avatarUrl: avatarUrl,
            displayName: profile.displayName,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload avatar. Please try again.', style: GoogleFonts.montserrat(fontSize: 12)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  ImageProvider<Object>? _getAvatarImage() {
    if (_avatarPath != null) {
      return FileImage(File(_avatarPath!));
    } else if (_profileAvatarUrl != null && _profileAvatarUrl!.isNotEmpty) {
      return NetworkImage(_profileAvatarUrl!);
    }
    return null;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');
      final existing = await UserProfileService.fetchProfile();
      final avatarUrl = existing?.avatarUrl;
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
      Provider.of<UserProfileNotifier>(context, listen: false).updateProfile(
        avatarUrl: avatarUrl,
        displayName: _nameController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated!', style: GoogleFonts.montserrat(fontSize: 12)),
            backgroundColor: Colors.green[600],
          ),
        );
        setState(() {
          _isEditing = false;
        });
        await _loadProfile();
      }
    } catch (e, st) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile. Please try again.', style: GoogleFonts.montserrat(fontSize: 12)),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('❌ Error saving profile: $e\n$st');
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
                      const SizedBox(height: 24),
                      Center(
                        child: GestureDetector(
                          onTap: _pickAvatar,
                          child: Stack(
                            children: [
                              UserAvatar(
                                localPath: _avatarPath,
                                networkUrl: _profileAvatarUrl,
                                initials: _nameController.text.isNotEmpty
                                    ? _nameController.text.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
                                    : 'U',
                                radius: 50,
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.green[600],
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          (_jobTitleController.text.isNotEmpty ? _jobTitleController.text : 'Job Title') +
                            (_companyController.text.isNotEmpty ? ' at ${_companyController.text}' : ''),
                          style: GoogleFonts.montserrat(fontSize: 16, color: Colors.grey[700], fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        enabled: _isEditing,
                        style: GoogleFonts.montserrat(fontSize: 12),
                        decoration: InputDecoration(
                          labelText: 'Display Name',
                          labelStyle: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600]),
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          hintText: 'Enter your name',
                          hintStyle: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[400]),
                          helperText: null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        enabled: _isEditing,
                        style: GoogleFonts.montserrat(fontSize: 12),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600]),
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _companyController,
                        enabled: _isEditing,
                        style: GoogleFonts.montserrat(fontSize: 12),
                        decoration: InputDecoration(
                          labelText: 'Company Name',
                          labelStyle: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600]),
                          prefixIcon: const Icon(Icons.apartment_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _jobTitleController,
                        enabled: _isEditing,
                        style: GoogleFonts.montserrat(fontSize: 12),
                        decoration: InputDecoration(
                          labelText: 'Job Title',
                          labelStyle: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600]),
                          prefixIcon: const Icon(Icons.work_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        enabled: false,
                        style: GoogleFonts.montserrat(fontSize: 12),
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          labelStyle: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600]),
                          prefixIcon: const Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'To change phone numbers, go to the settings page',
                        style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _isEditing
                            ? () async {
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
                              }
                            : null,
                        child: AbsorbPointer(
                          absorbing: !_isEditing,
                          child: TextFormField(
                            controller: TextEditingController(text: _birthday != null ? _birthdayString : ''),
                            readOnly: true,
                            style: GoogleFonts.montserrat(fontSize: 12),
                            decoration: InputDecoration(
                              labelText: 'Birthday',
                              labelStyle: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600]),
                              prefixIcon: const Icon(Icons.cake_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              hintText: 'Select your birthday',
                              hintStyle: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[400]),
                              helperText: null,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      TextFormField(
                        controller: _hobbiesController,
                        enabled: _isEditing,
                        style: GoogleFonts.montserrat(fontSize: 12),
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Hobbies & Interests',
                          labelStyle: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600]),
                          prefixIcon: const Icon(Icons.interests_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          hintText: 'Share your hobbies and interests',
                          hintStyle: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[400]),
                          helperText: 'Tell us what you enjoy doing in your free time',
                          helperStyle: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[600]),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      if (_isEditing) {
                        _saveProfile();
                      } else {
                        setState(() {
                          _isEditing = true;
                        });
                      }
                    },
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
                      _isEditing ? 'Save' : 'Edit',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ),
        ),
      ),
    );
  }
} 