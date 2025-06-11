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

  ImageProvider<Object>? _getAvatarImage() {
    if (localPath != null) {
      return FileImage(File(localPath!));
    } else if (networkUrl != null && networkUrl!.isNotEmpty) {
      return CachedNetworkImageProvider(networkUrl!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<UserProfileNotifier>(context);
    final String? effectiveNetworkUrl = networkUrl ?? notifier.avatarUrl;
    final String effectiveInitials = initials.isNotEmpty ? initials : (notifier.displayName.isNotEmpty ? notifier.displayName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase() : 'U');
    // Prefer notifier's localAvatarPath, then localPath, then network
    String? localPathToUse = notifier.localAvatarPath ?? localPath;
    if (localPathToUse != null && !File(localPathToUse).existsSync()) {
      localPathToUse = null;
    }
    // Cache busting: append timestamp to URL if present
    String? cacheBustedUrl = effectiveNetworkUrl;
    if (effectiveNetworkUrl != null && effectiveNetworkUrl.isNotEmpty) {
      final now = DateTime.now().millisecondsSinceEpoch;
      cacheBustedUrl = effectiveNetworkUrl.contains('?')
        ? '${effectiveNetworkUrl}&t=$now'
        : '${effectiveNetworkUrl}?t=$now';
    }
    print('[UserAvatar] localPath: '
        '\u001b[33m$localPathToUse\u001b[0m, networkUrl: '
        '\u001b[36m$cacheBustedUrl\u001b[0m');
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[200],
      backgroundImage: (localPathToUse != null)
        ? FileImage(File(localPathToUse)) as ImageProvider<Object>
        : (cacheBustedUrl != null && cacheBustedUrl.isNotEmpty
            ? CachedNetworkImageProvider(cacheBustedUrl) as ImageProvider<Object>
            : null),
      child: (localPathToUse == null && (cacheBustedUrl == null || cacheBustedUrl.isEmpty))
          ? Text(
              effectiveInitials,
              style: TextStyle(fontSize: radius * 0.64, color: Colors.grey[600]),
            )
          : null,
    );
  }
} 