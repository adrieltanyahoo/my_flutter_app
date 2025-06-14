import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

class LanguageRegionPage extends StatefulWidget {
  const LanguageRegionPage({super.key});

  @override
  State<LanguageRegionPage> createState() => _LanguageRegionPageState();
}

class _LanguageRegionPageState extends State<LanguageRegionPage> {
  String _selectedLanguage = 'English';
  String? _selectedTimeZone;
  String? _autoDetectedTimeZone;
  List<String> _ianaTimeZones = [];
  Map<String, String> _ianaTimeZoneLabels = {};

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
  ];

  static const Map<String, String> ianaTimeZoneLabels = {
    'UTC': 'UTC (Universal Time)',
    'Asia/Kuala_Lumpur': 'Kuala Lumpur (UTC+8)',
    'Asia/Singapore': 'Singapore (UTC+8)',
    'Asia/Tokyo': 'Tokyo (UTC+9)',
    'Asia/Shanghai': 'Shanghai (UTC+8)',
    'Asia/Bangkok': 'Bangkok (UTC+7)',
    'Europe/London': 'London (UTC+0)',
    'Europe/Paris': 'Paris (UTC+1)',
    'Europe/Berlin': 'Berlin (UTC+1)',
    'America/New_York': 'New York (UTC-5)',
    'America/Los_Angeles': 'Los Angeles (UTC-8)',
    'America/Chicago': 'Chicago (UTC-6)',
    'America/Sao_Paulo': 'Sao Paulo (UTC-3)',
    'Australia/Sydney': 'Sydney (UTC+10)',
    'Africa/Johannesburg': 'Johannesburg (UTC+2)',
  };

  @override
  void initState() {
    super.initState();
    _initializeTimeZones();
    _loadTimeZone();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    if (args != null) {
      String detectedTimeZone = args['timeZone'] ?? '';
      
      if (kDebugMode) {
        print('📱 Detected timezone: $detectedTimeZone');
      }
      
      // Restore: If detected timezone is in the list, set it directly
      if (detectedTimeZone.isNotEmpty && _ianaTimeZones.isNotEmpty) {
        if (_ianaTimeZones.contains(detectedTimeZone)) {
          setState(() {
            _selectedTimeZone = detectedTimeZone;
          });
          if (kDebugMode) {
            print('📱 Direct match for timezone: $_selectedTimeZone');
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
              _selectedTimeZone = closestTimeZone;
            });
            if (kDebugMode) {
              print('📱 Fallback to closest timezone: $_selectedTimeZone');
            }
          }
        }
      }
    }
  }

  Future<void> _initializeTimeZones() async {
    tzdata.initializeTimeZones();
    final locations = tz.timeZoneDatabase.locations;
    final now = DateTime.now().toUtc();
    
    // Create a list of timezone entries with their offsets (no deduplication)
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
    
    if (kDebugMode) {
      print('\n📋 YOUR ACTUAL DROPDOWN LIST:');
      for (var i = 0; i < timezoneEntries.length; i++) {
        print('${i + 1}. ${timezoneEntries[i]['label']}');
      }
    }
    
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
    setState(() {
      _selectedTimeZone = (cachedTimeZone != null && iataTimeZones.contains(cachedTimeZone))
          ? cachedTimeZone
          : iataTimeZones.first;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedTimeZone != null) {
      await prefs.setString('cached_time_zone', _selectedTimeZone!);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Settings saved successfully', style: GoogleFonts.montserrat(fontSize: 12)),
          behavior: SnackBarBehavior.floating,
        ),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Language & Region',
                style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.language, size: 24, color: Colors.green),
                        const SizedBox(width: 8),
                        Text('Language', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('App interface language', style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w400)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedLanguage,
                      items: [
                        DropdownMenuItem(
                          value: 'English',
                          child: Text('English', style: GoogleFonts.montserrat(fontSize: 12, color: Colors.black)),
                        ),
                      ],
                      onChanged: null, // Not editable
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      style: GoogleFonts.montserrat(fontSize: 12, color: Colors.black),
                      icon: const Icon(Icons.check, color: Colors.green, size: 20),
                      dropdownColor: Colors.white,
                      disabledHint: Text('English', style: GoogleFonts.montserrat(fontSize: 12, color: Colors.black)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 24, color: Colors.green),
                        const SizedBox(width: 8),
                        Text('Time Zone', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Select your time zone', style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w400)),
                    const SizedBox(height: 12),
                    if (_ianaTimeZones.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: _selectedTimeZone != null && _ianaTimeZones.contains(_selectedTimeZone) ? _selectedTimeZone : _ianaTimeZones.first,
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
                        onChanged: (value) {
                          setState(() {
                            _selectedTimeZone = value;
                          });
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        style: GoogleFonts.montserrat(fontSize: 12, color: Colors.black),
                        icon: const Icon(Icons.check, color: Colors.green, size: 20),
                        dropdownColor: Colors.white,
                        isExpanded: true,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _saveSettings,
                  child: Text('Save', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 