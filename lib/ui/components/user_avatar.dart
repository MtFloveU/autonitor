// lib/ui/components/user_avatar.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String? avatarLocalPath;
  final String? mediaDir;
  final double radius;
  final String? heroTag;
  final bool isHighQuality;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    required this.avatarUrl,
    this.avatarLocalPath,
    this.mediaDir,
    this.radius = 24,
    this.heroTag,
    this.isHighQuality = false,
    this.onTap,
  });

  String? _getAbsoluteLocalPath() {
    if (mediaDir != null &&
        avatarLocalPath != null &&
        avatarLocalPath!.isNotEmpty) {
      return p.join(mediaDir!, avatarLocalPath!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final double diameter = radius * 2;
    final absolutePath = _getAbsoluteLocalPath();

    // Placeholder widget
    final placeholder = SizedBox(
      width: diameter,
      height: diameter,
      child: Icon(
        Icons.person,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );

    Widget imageContent;

    if (absolutePath != null && File(absolutePath).existsSync()) {
      imageContent = Image.file(
        File(absolutePath),
        width: diameter,
        height: diameter,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return placeholder;
        },
      );
    } else {
      imageContent = placeholder;
    }

    Widget content = ClipOval(child: imageContent);

    if (heroTag != null) {
      content = Hero(tag: heroTag!, child: content);
    }

    // Wrap in CircleAvatar to provide background color (transparency handling)
    content = CircleAvatar(
      radius: radius,
      backgroundColor: Colors.transparent,
      child: content,
    );

    if (onTap != null) {
      content = GestureDetector(onTap: onTap, child: content);
    }

    return content;
  }
}
