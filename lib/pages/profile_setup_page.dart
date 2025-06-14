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
import 'package:provider/provider.dart';
import '../services/user_profile_notifier.dart';
import 'settings/user_avatar.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

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
  String? _profileAvatarUrl;
  bool _isLoading = false;
  DateTime? _birthday;
  String? _birthdayString;
  bool _isFetching = false;
  List<String> _ianaTimeZones = [];
  Map<String, String> _ianaTimeZoneLabels = {};

  @override
  void initState() {
    super.initState();
    _initializeTimeZones();
    _loadTimeZone();
    _loadProfile();
  }

  Future<void> _initializeTimeZones() async {
    tzdata.initializeTimeZones();
    final locations = tz.timeZoneDatabase.locations;
    final now = DateTime.now().toUtc();
    
    // Create a list of timezone entries with their offsets
    final List<Map<String, dynamic>> timezoneEntries = [];
    
    for (final name in locations.keys) {
      try {
        final location = tz.getLocation(name);
        final offsetMilliseconds = location.currentTimeZone.offset;
        final offsetSeconds = offsetMilliseconds ~/ 1000;
        final totalMinutes = offsetSeconds ~/ 60;
        
        timezoneEntries.add({
          'name': name,
          'offset': totalMinutes,
          'label': _friendlyTimeZoneLabel(name, now)
        });
      } catch (_) {
        // Skip invalid timezones
      }
    }
    
    // Sort by offset (chronologically)
    timezoneEntries.sort((a, b) => a['offset'].compareTo(b['offset']));
    
    setState(() {
      _ianaTimeZones = timezoneEntries.map((e) => e['name'] as String).toList();
      _ianaTimeZoneLabels = {
        for (final entry in timezoneEntries)
          entry['name'] as String: entry['label'] as String
      };
    });
  }

  String _friendlyTimeZoneLabel(String name, DateTime nowUtc) {
    try {
      final location = tz.getLocation(name);
      final offsetMilliseconds = location.currentTimeZone.offset;
      final offsetSeconds = offsetMilliseconds ~/ 1000;

      final totalMinutes = offsetSeconds ~/ 60;
      final sign = totalMinutes >= 0 ? '+' : '-';
      final absMinutes = totalMinutes.abs();
      final hours = absMinutes ~/ 60;
      final minutes = absMinutes % 60;

      final offsetStr = 'GMT$sign${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
      final city = name.split('/').last.replaceAll('_', ' ');
      return '($offsetStr) $city';
    } catch (_) {
      return name;
    }
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
      String detectedTimeZone = args['timeZone'] ?? '';

      if (kDebugMode) {
        print('📲 Pre-filling profile setup:');
        print('   • UID: $uid');
        print('   • Phone: $prefillPhoneNumber');
        print('   • Timezone: $detectedTimeZone');
      }

      // Set this into your controllers or state
      _phoneController.text = prefillPhoneNumber;
      
      // Restore: If detected timezone is in the list, set it directly
      if (detectedTimeZone.isNotEmpty && _ianaTimeZones.isNotEmpty) {
        if (_ianaTimeZones.contains(detectedTimeZone)) {
          setState(() {
            _timeZone = detectedTimeZone;
          });
          if (kDebugMode) {
            print('📱 Direct match for timezone: $_timeZone');
          }
        } else {
          // Fallback to offset-matching
          final gmtOffset = detectedTimeZone.replaceAll('GMT', '').trim();
          String? closestTimeZone;
          int? minDifference;
          for (final tzName in _ianaTimeZones) {
            try {
              final location = tz.getLocation(tzName);
              final offsetMilliseconds = location.currentTimeZone.offset;
              final offsetSeconds = offsetMilliseconds ~/ 1000;
              final totalMinutes = offsetSeconds ~/ 60;
              // Parse the detected timezone
              final detectedHours = int.parse(gmtOffset.substring(1, 3));
              final detectedMinutes = int.parse(gmtOffset.substring(4, 6));
              final detectedTotalMinutes = (detectedHours * 60 + detectedMinutes) * (gmtOffset.startsWith('-') ? -1 : 1);
              final difference = (totalMinutes - detectedTotalMinutes).abs();
              if (minDifference == null || difference < minDifference) {
                minDifference = difference;
                closestTimeZone = tzName;
              }
            } catch (_) {
              continue;
            }
          }
          if (closestTimeZone != null) {
            setState(() {
              _timeZone = closestTimeZone!;
            });
            if (kDebugMode) {
              print('📱 Fallback to closest timezone: $_timeZone');
            }
          }
        }
      }
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
        // Update notifier with new avatar URL and local path
        if (mounted) {
          Provider.of<UserProfileNotifier>(context, listen: false).updateProfile(
            avatarUrl: avatarUrl,
            displayName: profile.displayName,
            localAvatarPath: imagePath,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload avatar. Please try again.', style: GoogleFonts.montserrat()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _completeSetup() async {
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
        await _syncAvatarStateBeforeNavigation();
        Navigator.pushReplacementNamed(context, '/messages');
      }
    } catch (e, st) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile. Please try again.', style: GoogleFonts.montserrat()),
            backgroundColor: Colors.red,
          ),
        );
      }
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _syncAvatarStateBeforeNavigation() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAvatarPath = prefs.getString('local_avatar_path');
    final profile = await UserProfileService.fetchProfile();
    if (profile != null) {
      Provider.of<UserProfileNotifier>(context, listen: false).loadProfile(
        avatarUrl: profile.avatarUrl,
        displayName: profile.displayName,
        localAvatarPath: (savedAvatarPath != null && File(savedAvatarPath).existsSync()) ? savedAvatarPath : null,
      );
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
                        'Setup Your Profile',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Profile Picture
                      Center(
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: _pickAvatar,
                              child: UserAvatar(
                                localPath: _avatarPath,
                                networkUrl: _profileAvatarUrl,
                                initials: _nameController.text.isNotEmpty
                                    ? _nameController.text.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
                                    : 'U',
                                radius: 50,
                              ),
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
                      const SizedBox(height: 24),
                      // Display Name
                      TextFormField(
                        controller: _nameController,
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
                      // Email
                      TextFormField(
                        controller: _emailController,
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
                      // Company Name
                      TextFormField(
                        controller: _companyController,
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
                      // Job Title
                      TextFormField(
                        controller: _jobTitleController,
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
                      // Phone Number
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
                      const SizedBox(height: 16),
                      // Birthday
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
                      // Hobbies & Interests
                      TextFormField(
                        controller: _hobbiesController,
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
                      const SizedBox(height: 16),
                      // Time Zone Dropdown
                      if (_ianaTimeZones.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: DropdownButtonFormField<String>(
                            value: _timeZone.isNotEmpty && _ianaTimeZones.contains(_timeZone) ? _timeZone : _ianaTimeZones.first,
                            items: _ianaTimeZones.map((tzName) => DropdownMenuItem(
                              value: tzName,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 300),
                                child: Text(
                                  _ianaTimeZoneLabels[tzName] ?? tzName,
                                  style: GoogleFonts.montserrat(fontSize: 12, color: Colors.black),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )).toList(),
                            onChanged: (value) async {
                              setState(() {
                                _timeZone = value!;
                              });
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setString('cached_time_zone', _timeZone);
                            },
                            decoration: InputDecoration(
                              labelText: 'Time Zone',
                              labelStyle: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600]),
                              prefixIcon: const Icon(Icons.access_time),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            style: GoogleFonts.montserrat(fontSize: 12, color: Colors.black),
                            icon: const Icon(Icons.check, color: Colors.green, size: 20),
                            dropdownColor: Colors.white,
                            isExpanded: true,
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
              onPressed: _isLoading ? null : _completeSetup,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Save Changes',
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