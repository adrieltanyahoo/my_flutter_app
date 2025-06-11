import 'package:flutter/material.dart';

class UserProfileNotifier extends ChangeNotifier {
  String? _avatarUrl;
  String _displayName = '';
  String? _localAvatarPath;

  String? get avatarUrl => _avatarUrl;
  String get displayName => _displayName;
  String? get localAvatarPath => _localAvatarPath;

  void updateProfile({String? avatarUrl, String? displayName, String? localAvatarPath}) {
    if (avatarUrl != null) _avatarUrl = avatarUrl;
    if (displayName != null) _displayName = displayName;
    if (localAvatarPath != null) _localAvatarPath = localAvatarPath;
    notifyListeners();
  }

  void setAvatarUrl(String? url) {
    _avatarUrl = url;
    notifyListeners();
  }

  void setDisplayName(String name) {
    _displayName = name;
    notifyListeners();
  }

  void setLocalAvatarPath(String? path) {
    _localAvatarPath = path;
    notifyListeners();
  }

  void clearLocalAvatarPath() {
    _localAvatarPath = null;
    notifyListeners();
  }

  void loadProfile({String? avatarUrl, String? displayName, String? localAvatarPath}) {
    _avatarUrl = avatarUrl;
    _displayName = displayName ?? '';
    _localAvatarPath = localAvatarPath;
    notifyListeners();
  }
} 