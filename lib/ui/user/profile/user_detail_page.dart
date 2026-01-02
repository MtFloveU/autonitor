import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:autonitor/l10n/app_localizations.dart';
import 'package:autonitor/models/twitter_user.dart';
import 'package:autonitor/providers/media_provider.dart';
import 'package:autonitor/repositories/history_repository.dart';
import 'package:autonitor/services/log_service.dart';
import 'package:autonitor/ui/components/full_screen_image_viewer.dart';
import 'package:autonitor/ui/components/profile_change_card.dart';
import 'package:autonitor/ui/user/user_history_page.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

part 'user_detail_page_utils.dart';
part 'user_detail_page_logic.dart';
part 'user_detail_page_header_widgets.dart';
part 'user_detail_page_info_widgets.dart';
part 'user_detail_page_stat_widgets.dart';
part 'user_detail_page_misc_widgets.dart';

class UserDetailPage extends ConsumerStatefulWidget {
  final TwitterUser user;
  final String ownerId;
  final bool isFromHistory;
  final String? snapshotJson;
  final String? snapshotId;
  final DateTime? snapshotTimestamp;
  final String? heroTag;

  const UserDetailPage({
    super.key,
    required this.user,
    required this.ownerId,
    this.isFromHistory = false,
    this.snapshotJson,
    this.snapshotId,
    this.snapshotTimestamp,
    this.heroTag,
  });

  @override
  ConsumerState<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends ConsumerState<UserDetailPage>
    with TickerProviderStateMixin {
  final List<Widget Function(BuildContext)> _builders = [];

  // 0: Banner+Avatar (Hero) - Static
  // 1: Spacing - Static
  // 2: UserInfo - Animated Start
  int _visibleCount = 2;
  final List<AnimationController?> _fadeControllers = [];
  bool _isCheckingHistory = false;

  void _setState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _prepareBuilders();
    _ensureControllersList();
    _startRenderLoop();
  }

  @override
  void dispose() {
    for (final c in _fadeControllers) {
      try {
        c?.dispose();
      } catch (_) {}
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user.name ?? 'Unknown'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            offset: const Offset(0, 40),
            onSelected: (value) {
              if (value == 'compare') {
                _showLatestDiff(context);
              }
              if (value == 'json') {
                final l10n = AppLocalizations.of(context)!;
                _showJsonDialog(context, l10n);
              }
            },
            itemBuilder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return [
                if (!widget.isFromHistory)
                  PopupMenuItem(
                    value: 'compare',
                    child: Row(
                      children: [
                        Icon(
                          Icons.history_edu_outlined,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        const SizedBox(width: 8),
                        Text(l10n.compare),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'json',
                  child: Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      const SizedBox(width: 8),
                      const Text('JSON'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: List.generate(_visibleCount.clamp(0, _builders.length), (
          index,
        ) {
          Widget child = _builders[index](context);

          // 大屏适配适配：内容居中，最大宽度限制为 800
          Widget content = Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: SizedBox(width: double.infinity, child: child),
            ),
          );

          if (index < 2) {
            return content;
          }

          final controller = _fadeControllers.length > index
              ? _fadeControllers[index]
              : null;

          if (controller != null) {
            return FadeTransition(
              opacity: controller.drive(CurveTween(curve: Curves.easeOut)),
              child: SlideTransition(
                position: controller.drive(
                  Tween<Offset>(
                    begin: const Offset(0, 0.03),
                    end: Offset.zero,
                  ).chain(CurveTween(curve: Curves.easeOut)),
                ),
                child: content,
              ),
            );
          } else {
            return content;
          }
        }),
      ),
    );
  }
}
