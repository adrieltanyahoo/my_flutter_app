import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/user_profile_notifier.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserAvatar extends StatelessWidget {
  final String? localPath;
  final String? networkUrl;
  final String initials;
  final double radius;

  const UserAvatar({
    super.key,
    this.localPath,
    this.networkUrl,
    required this.initials,
    this.radius = 50,
  });

  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<UserProfileNotifier>(context);
    final String? effectiveNetworkUrl = networkUrl ?? notifier.avatarUrl;
    final String effectiveInitials = initials.isNotEmpty 
        ? initials 
        : (notifier.displayName.isNotEmpty 
            ? notifier.displayName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase() 
            : 'U');
    
    // Prefer notifier's localAvatarPath, then localPath
    String? localPathToUse = notifier.localAvatarPath ?? localPath;
    
    // Verify local file exists
    if (localPathToUse != null) {
      final file = File(localPathToUse);
      if (!file.existsSync()) {
        print('[UserAvatar] Local file does not exist: $localPathToUse');
        localPathToUse = null;
      }
    }

    // Log the state for debugging
    print('[UserAvatar] State:'
        '\n  - Local path: ${localPathToUse ?? 'null'}'
        '\n  - Network URL: ${effectiveNetworkUrl ?? 'null'}'
        '\n  - Notifier local path: ${notifier.localAvatarPath ?? 'null'}'
        '\n  - Notifier network URL: ${notifier.avatarUrl ?? 'null'}'
        '\n  - Initials: $effectiveInitials');

    // Determine the image provider
    ImageProvider<Object>? imageProvider;
    if (localPathToUse != null) {
      imageProvider = FileImage(File(localPathToUse));
    } else if (effectiveNetworkUrl != null && effectiveNetworkUrl.isNotEmpty) {
      imageProvider = CachedNetworkImageProvider(effectiveNetworkUrl);
    } else {
      imageProvider = null;
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[200],
      backgroundImage: imageProvider,
      child: (imageProvider == null)
          ? Text(
              effectiveInitials,
              style: TextStyle(fontSize: radius * 0.64, color: Colors.grey[600]),
            )
          : null,
    );
  }
} 