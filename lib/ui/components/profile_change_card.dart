import 'dart:convert';
import 'package:autonitor/l10n/app_localizations.dart';
import 'package:autonitor/ui/user/user_list_page.dart';
import 'package:diff_match_patch/diff_match_patch.dart' as diff_utils;
import 'package:flutter/material.dart';
import 'package:autonitor/models/twitter_user.dart';

class ProfileChangeCard extends StatelessWidget {
  final String jsonContent;
  final DateTime timestamp;
  final VoidCallback? onTap;
  final String? mediaDir;
  final String heroTag;
  final String? avatarLocalPath;

  const ProfileChangeCard({
    super.key,
    required this.jsonContent,
    required this.timestamp,
    this.onTap,
    required this.mediaDir,
    required this.heroTag,
    required this.avatarLocalPath,
  });

  // ===== Unicode 安全处理 =====

  String _safeString(dynamic value) {
    if (value == null) return '';
    final str = value.toString();
    try {
      final bytes = utf8.encode(str);
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return '';
    }
  }

  /// grapheme-aware diff，保证 emoji / ZWJ 不被拆分
  List<diff_utils.Diff> _diffGraphemeAware(String oldText, String newText) {
    final a = _safeString(oldText);
    final b = _safeString(newText);

    final aClusters = a.characters.toList();
    final bClusters = b.characters.toList();

    final unique = <String>{...aClusters, ...bClusters}.toList();

    const puaStart = 0xE000;
    const puaEnd = 0xF8FF;
    final maxPUA = puaEnd - puaStart;

    // 极端情况降级
    if (unique.length > maxPUA) {
      return diff_utils.diff(a, b);
    }

    final Map<String, String> toToken = {};
    final Map<int, String> fromToken = {};

    for (int i = 0; i < unique.length; i++) {
      final token = String.fromCharCode(puaStart + i);
      toToken[unique[i]] = token;
      fromToken[token.codeUnitAt(0)] = unique[i];
    }

    String encode(List<String> clusters) =>
        clusters.map((c) => toToken[c]!).join();

    final encodedA = encode(aClusters);
    final encodedB = encode(bClusters);

    final encodedDiffs = diff_utils.diff(encodedA, encodedB);

    return encodedDiffs.map((d) {
      final buffer = StringBuffer();
      for (final r in d.text.runes) {
        buffer.write(fromToken[r] ?? String.fromCharCode(r));
      }
      return diff_utils.Diff(d.operation, buffer.toString());
    }).toList();
  }

  // ===== UI =====

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Map<String, dynamic> data;

    try {
      data = jsonDecode(jsonContent);
    } catch (_) {
      return const SizedBox.shrink();
    }

    final diff = data['diff'] as Map<String, dynamic>? ?? {};
    final userMap = data['user'] as Map<String, dynamic>?;

    if (userMap == null || diff.isEmpty) return const SizedBox.shrink();

    TwitterUser user;
    try {
      user = TwitterUser.fromJson(userMap);
    } catch (_) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.dividerColor.withAlpha((0.4 * 255).round()),
        ),
      ),
      color: theme.colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IgnorePointer(
              ignoring: true,
              child: UserListTile(
                user: user,
                mediaDir: mediaDir,
                avatarLocalPathOverride: avatarLocalPath,
                onTap: null,
                followingLabel: l10n.following,
                isFollower: user.isFollower,
                customHeroTag: heroTag,
              ),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 先处理普通 diff 行（非 avatar/banner）
                  ...diff.entries
                      .where((e) => e.key != 'avatar' && e.key != 'banner')
                      .map((e) => _buildDiffRow(context, e.key, e.value)),

                  // 再把 avatar/banner 收集起来放 Wrap
                  Builder(
                    builder: (context) {
                      final avatarBannerWidgets = diff.entries
                          .where((e) => e.key == 'avatar' || e.key == 'banner')
                          .map((e) => _buildDiffRow(context, e.key, e.value))
                          .toList();

                      if (avatarBannerWidgets.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: avatarBannerWidgets,
                        ),
                      );
                    },
                  ),

                  // 时间戳
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _formatTimestamp(timestamp),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) =>
      "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
      "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

  Widget _buildDiffRow(BuildContext context, String field, dynamic changeData) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final oldVal = _safeString(changeData['old']);
    final newVal = _safeString(changeData['new']);

    String label = field;
    IconData icon = Icons.edit_outlined;

    switch (field) {
      case 'name':
        label = l10n.name;
        icon = Icons.badge_outlined;
        break;
      case 'screen_name':
        label = l10n.screen_name;
        icon = Icons.alternate_email;
        break;
      case 'bio':
        label = l10n.bio;
        icon = Icons.description_outlined;
        break;
      case 'link':
        label = l10n.link;
        icon = Icons.link_outlined;
        break;
      case 'location':
        label = l10n.location;
        icon = Icons.location_on_outlined;
        break;
      case 'avatar':
        label = l10n.avatar;
        icon = Icons.image_outlined;
        break;
      case 'banner':
        label = l10n.banner;
        icon = Icons.panorama_outlined;
        break;
    }

    if (field == 'avatar' || field == 'banner') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: RichText(
          text: TextSpan(
            children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Icon(icon, size: 18, color: theme.colorScheme.primary),
              ),
              const WidgetSpan(child: SizedBox(width: 8)),
              TextSpan(
                text: '$label ${l10n.updated}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildRichDiff(context, oldVal, newVal),
        ],
      ),
    );
  }

  Widget _buildRichDiff(BuildContext context, String oldText, String newText) {
    final theme = Theme.of(context);

    List<diff_utils.Diff> diffs;
    try {
      diffs = _diffGraphemeAware(oldText, newText);
    } catch (_) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Old: $oldText",
            style: TextStyle(color: theme.colorScheme.error),
          ),
          Text("New: $newText", style: const TextStyle(color: Colors.green)),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.dividerColor.withAlpha((0.5 * 255).round()),
        ),
      ),
      child: RichText(
        text: TextSpan(
          children: diffs.map((diff) {
            TextStyle style = TextStyle(color: theme.colorScheme.onSurface);
            Color? backgroundColor;

            switch (diff.operation) {
              case diff_utils.DIFF_INSERT:
                style = TextStyle(
                  color: theme.brightness == Brightness.dark
                      ? const Color(0xFF4ADE80)
                      : const Color(0xFF166534),
                  fontWeight: FontWeight.bold,
                );
                backgroundColor = theme.brightness == Brightness.dark
                    ? const Color(0xFF14532D)
                    : const Color(0xFFDCFCE7);
                break;
              case diff_utils.DIFF_DELETE:
                style = TextStyle(
                  color: theme.colorScheme.error,
                  decoration: TextDecoration.lineThrough,
                );
                backgroundColor = theme.colorScheme.errorContainer.withAlpha(
                  (0.4 * 255).round(),
                );
                break;
              case diff_utils.DIFF_EQUAL:
                break;
            }

            return TextSpan(
              text: diff.text,
              style: style.copyWith(
                fontSize: 14,
                height: 1.5,
                backgroundColor: backgroundColor,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
