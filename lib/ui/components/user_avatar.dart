// lib/ui/components/user_avatar.dart
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
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

  static final RegExp _avatarSizeRegex = RegExp(r'_(normal|bigger|400x400)');

  String? _getAbsoluteLocalPath() {
    if (mediaDir != null &&
        avatarLocalPath != null &&
        avatarLocalPath!.isNotEmpty) {
      return p.join(mediaDir!, avatarLocalPath!);
    }
    return null;
  }

  String _getEffectiveUrl() {
    final url = avatarUrl ?? '';
    if (url.isEmpty) return '';

    // Replace size suffix if high quality is requested
    if (isHighQuality) {
      return url.replaceFirst(_avatarSizeRegex, '_400x400');
    }
    // Default usually is _normal or _bigger depending on API,
    // keep as is or force _bigger for list views if needed.
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final double diameter = radius * 2;
    final absolutePath = _getAbsoluteLocalPath();
    final effectiveUrl = _getEffectiveUrl();

    // Placeholder widget
    final placeholder = SizedBox(
      width: diameter,
      height: diameter,
      child: const Icon(Icons.person, color: Colors.grey),
    );

    Widget imageContent;

    if (absolutePath != null && File(absolutePath).existsSync()) {
      imageContent = Image.file(
        File(absolutePath),
        width: diameter,
        height: diameter,
        fit: BoxFit.cover,
        // Small cache optimization for local files in lists
        cacheWidth: (diameter * 2).toInt(),
        errorBuilder: (context, error, stackTrace) {
          // Fallback to network if local file is corrupted
          if (effectiveUrl.isNotEmpty) {
            return CachedNetworkImage(
              imageUrl: effectiveUrl,
              width: diameter,
              height: diameter,
              fit: BoxFit.cover,
              placeholder: (_, _) => placeholder,
              errorWidget: (_, _, _) => placeholder,
            );
          }
          return placeholder;
        },
      );
    } else if (effectiveUrl.isNotEmpty) {
      imageContent = CachedNetworkImage(
        imageUrl: effectiveUrl,
        width: diameter,
        height: diameter,
        fit: BoxFit.cover,
        memCacheWidth: (diameter * 2).toInt(),
        placeholder: (_, _) => placeholder,
        errorWidget: (_, _, _) => placeholder,
        fadeInDuration: const Duration(milliseconds: 200),
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
