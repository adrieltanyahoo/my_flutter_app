import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String company;
  final String jobTitle;
  final String phone;
  final String? birthday;
  final String? hobbies;
  final String? avatarUrl;

  UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.company,
    required this.jobTitle,
    required this.phone,
    this.birthday,
    this.hobbies,
    this.avatarUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'company': company,
      'jobTitle': jobTitle,
      'phone': phone,
      'birthday': birthday,
      'hobbies': hobbies,
      'avatarUrl': avatarUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      displayName: map['displayName'] ?? '',
      email: map['email'] ?? '',
      company: map['company'] ?? '',
      jobTitle: map['jobTitle'] ?? '',
      phone: map['phone'] ?? '',
      birthday: map['birthday'],
      hobbies: map['hobbies'],
      avatarUrl: map['avatarUrl'],
    );
  }
}

class UserProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String?> uploadAvatar(String uid, String imagePath) async {
    try {
      if (kDebugMode) {
        print('🔄 Starting avatar upload for user: $uid');
        print('�� Image path: $imagePath');
      }
      // Check if file exists
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Image file does not exist at path: $imagePath');
      }
      // Get file info
      final fileSize = await file.length();
      if (kDebugMode) {
        print('📊 File size: ${(fileSize / 1024).toStringAsFixed(2)} KB');
      }
      // Check file size (5MB limit)
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('Image file is too large. Maximum size is 5MB.');
      }
      // Create storage reference with timestamp to avoid conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'avatar_${uid}_$timestamp.jpg';
      final storageRef = _storage.ref().child('avatars/$fileName');
      if (kDebugMode) {
        print('☁️ Uploading to Firebase Storage: avatars/$fileName');
      }
      // Create upload task with metadata
      final uploadTask = storageRef.putFile(
        file,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': uid,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );
      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        if (kDebugMode) {
          print('📤 Upload progress: ${progress.toStringAsFixed(1)}%');
        }
      });
      // Wait for upload completion
      final snapshot = await uploadTask;
      
      if (snapshot.state == TaskState.success) {
        // Get download URL
        final downloadUrl = await snapshot.ref.getDownloadURL();
        
        if (kDebugMode) {
          print('✅ Avatar upload successful!');
          print('🔗 Download URL: $downloadUrl');
        }
        
        return downloadUrl;
      } else {
        throw Exception('Upload failed with state: ${snapshot.state}');
      }
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('❌ Firebase Storage Error: ${e.code} - ${e.message}');
      }
      
      // Handle specific Firebase Storage errors
      switch (e.code) {
        case 'unauthorized':
          throw Exception('You do not have permission to upload images. Please check your authentication.');
        case 'canceled':
          throw Exception('Upload was canceled.');
        case 'unknown':
          throw Exception('An unknown error occurred during upload. Please try again.');
        case 'object-not-found':
          throw Exception('File not found during upload.');
        case 'bucket-not-found':
          throw Exception('Storage bucket not found. Please check Firebase configuration.');
        case 'project-not-found':
          throw Exception('Firebase project not found. Please check configuration.');
        case 'quota-exceeded':
          throw Exception('Storage quota exceeded. Please contact support.');
        case 'unauthenticated':
          throw Exception('User is not authenticated. Please sign in again.');
        case 'retry-limit-exceeded':
          throw Exception('Upload retry limit exceeded. Please try again later.');
        case 'invalid-checksum':
          throw Exception('File checksum validation failed. Please try again.');
        default:
          throw Exception('Upload failed: ${e.message ?? e.code}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ General Upload Error: $e');
      }
      throw Exception('Failed to upload avatar: $e');
    }
  }

  static Future<void> saveProfile(UserProfile profile) async {
    try {
      if (kDebugMode) {
        print('💾 Saving profile for user: ${profile.uid}');
      }
      await _firestore
          .collection('users')
          .doc(profile.uid)
          .set(profile.toMap(), SetOptions(merge: true));
      if (kDebugMode) {
        print('✅ Profile saved successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving profile: $e');
      }
      throw Exception('Failed to save profile: $e');
    }
  }

  static Future<UserProfile?> fetchProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('❌ No authenticated user found');
        }
        return null;
      }
      if (kDebugMode) {
        print('📱 Fetching profile for user: ${user.uid}');
      }
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final profile = UserProfile.fromMap(doc.data()!);
        if (kDebugMode) {
          print('✅ Profile fetched successfully');
        }
        return profile;
      } else {
        if (kDebugMode) {
          print('📭 No profile found for user');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching profile: $e');
      }
      throw Exception('Failed to fetch profile: $e');
    }
  }

  static Future<void> deleteAvatar(String avatarUrl) async {
    try {
      if (kDebugMode) {
        print('🗑️ Deleting avatar: $avatarUrl');
      }
      // Extract the file path from the URL
      final uri = Uri.parse(avatarUrl);
      final pathSegments = uri.pathSegments;
      
      // Find the path after 'o/' in the URL
      final oIndex = pathSegments.indexOf('o');
      if (oIndex != -1 && oIndex + 1 < pathSegments.length) {
        final filePath = pathSegments.sublist(oIndex + 1).join('/');
        final decodedPath = Uri.decodeComponent(filePath);
        
        final ref = _storage.ref().child(decodedPath);
        await ref.delete();
        
        if (kDebugMode) {
          print('✅ Avatar deleted successfully');
        }
      } else {
        throw Exception('Invalid avatar URL format');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting avatar: $e');
      }
      // Don't throw error for deletion failures
    }
  }
} 