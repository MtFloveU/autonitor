import 'dart:convert';
import 'package:autonitor/models/history_snapshot.dart';
import 'package:autonitor/ui/components/profile_change_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autonitor/providers/media_provider.dart';
import 'package:autonitor/providers/history_provider.dart';
import 'package:autonitor/ui/user_detail_page.dart';
import '../models/twitter_user.dart';
import '../l10n/app_localizations.dart';
import 'user_list_page.dart';

class UserHistoryPage extends ConsumerStatefulWidget {
  final TwitterUser user;
  final String ownerId;

  const UserHistoryPage({super.key, required this.user, required this.ownerId});

  @override
  ConsumerState<UserHistoryPage> createState() => _UserHistoryPageState();
}

class _UserHistoryPageState extends ConsumerState<UserHistoryPage> {
  bool _routeAnimationCompleted = false;
  late final ScrollController _scrollController;
  int? _expandedEntryId;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = ModalRoute.of(context);
      final animation = route?.animation;

      if (animation == null || animation.status == AnimationStatus.completed) {
        _markRouteCompleted();
      } else {
        late void Function(AnimationStatus) listener;
        listener = (status) {
          if (status == AnimationStatus.completed) {
            animation.removeStatusListener(listener);
            _markRouteCompleted();
          }
        };
        animation.addStatusListener(listener);
      }
    });
  }

  void _markRouteCompleted() {
    if (mounted) {
      setState(() {
        _routeAnimationCompleted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userId = widget.user.restId;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.user_history_page_title),
            const SizedBox(height: 2),
            Text(
              '@${widget.user.screenName}',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
      body: Builder(
        builder: (context) {
          const loadingWidget = Center(child: CircularProgressIndicator());

          if (!_routeAnimationCompleted) {
            return loadingWidget;
          }

          final params = ProfileHistoryParams(
            ownerId: widget.ownerId,
            userId: userId,
          );
          final historyAsync = ref.watch(profileHistoryProvider(params));
          final mediaDirAsync = ref.watch(appSupportDirProvider);

          return historyAsync.when(
            loading: () => loadingWidget,
            error: (err, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('${l10n.failed_to_load_user_list}:\n$err'),
              ),
            ),
            data: (pagedState) {
              if (pagedState.snapshots.isEmpty) {
                return Center(child: Text(l10n.no_users_in_this_category));
              }

              void goToPage(int page) {
                if (page < 1 || page > pagedState.totalPages) return;
                ref.read(profileHistoryProvider(params).notifier).setPage(page);
                _scrollController.jumpTo(0);
                setState(() => _expandedEntryId = null);
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: pagedState.snapshots.length,
                      itemBuilder: (context, index) {
                        final snapshot = pagedState.snapshots[index];
                        final entryId = snapshot.entry.id;
                        final isExpanded = _expandedEntryId == entryId;

                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 800),
                            child: _HistoryItem(
                              key: ValueKey(
                                '${snapshot.entry.id}_${snapshot.user.restId}',
                              ),
                              snapshot: snapshot,
                              mediaDir: mediaDirAsync.value,
                              l10n: l10n,
                              ownerId: widget.ownerId,
                              uniqueHeroTag:
                                  'avatar_${snapshot.user.restId}_${snapshot.entry.id}',
                              isExpanded: isExpanded,
                              onToggle: () {
                                setState(() {
                                  _expandedEntryId = isExpanded
                                      ? null
                                      : entryId;
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  _PaginationControls(
                    currentPage: pagedState.currentPage,
                    totalPages: pagedState.totalPages,
                    totalCount: pagedState.totalCount,
                    onPageChanged: goToPage,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final HistorySnapshot snapshot;
  final String? mediaDir;
  final AppLocalizations l10n;
  final String ownerId;
  final String uniqueHeroTag;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _HistoryItem({
    super.key,
    required this.snapshot,
    required this.mediaDir,
    required this.l10n,
    required this.ownerId,
    required this.uniqueHeroTag,
    required this.isExpanded,
    required this.onToggle,
  });

  String _generateCardJson() {
    // rawDiff 已经是 Worker 计算好的正向 Diff
    final rawDiff = snapshot.entry.reverseDiffJson;
    final rawFull = snapshot.fullJson;

    Map<String, dynamic> userMap = {};
    try {
      if (rawFull.isNotEmpty) {
        final parsed = jsonDecode(rawFull);
        if (parsed is Map<String, dynamic>) {
          userMap = parsed;
        }
      }
    } catch (_) {}
    if (userMap.isEmpty) {
      userMap = snapshot.user.toJson();
    }

    final Map<String, dynamic> diffMap = {};
    String? debugMessage;

    if (rawDiff.isEmpty) {
      debugMessage = "";
    } else {
      try {
        final dynamic parsed = jsonDecode(rawDiff);
        if (parsed is Map<String, dynamic>) {
          if (parsed.isEmpty) {
            debugMessage = "";
          } else {
            // Key 映射: Worker 返回的是原始 API Key (avatar_url)，UI Card 期望的是 (avatar)
            final keyMapping = {'avatar_url': 'avatar', 'banner_url': 'banner'};
            parsed.forEach((k, v) {
              final mappedKey = keyMapping[k] ?? k;
              diffMap[mappedKey] = v;
            });
          }
        }
      } catch (e) {
        debugMessage = "Error: $e";
      }
    }

    if (diffMap.isEmpty) {
      diffMap['System'] = {
        'old': null,
        'new': debugMessage?.isNotEmpty == true
            ? debugMessage
            : 'No visible changes',
      };
    }

    return jsonEncode({'diff': diffMap, 'user': userMap});
  }

  @override
  Widget build(BuildContext context) {
    final cardJson = isExpanded ? _generateCardJson() : "";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            "ID: ${snapshot.entry.id}  (${snapshot.entry.timestamp.toLocal().toString().substring(0, 16)})",
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),

        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          alignment: Alignment.topCenter,
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,

          firstChild: Stack(
            children: [
              UserListTile(
                user: snapshot.user,
                mediaDir: mediaDir,
                followingLabel: l10n.following,
                isFollower: snapshot.user.isFollower,
                customHeroTag: uniqueHeroTag,
                onTap: _navigateToDetail(context),
              ),
              Positioned(
                right: 4,
                top: 4,
                child: IconButton(
                  icon: const Icon(Icons.expand_more, color: Colors.grey),
                  onPressed: onToggle,
                ),
              ),
            ],
          ),

          secondChild: Stack(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).dividerColor.withAlpha((0.2 * 255).round()),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ProfileChangeCard(
                  jsonContent: cardJson,
                  timestamp: snapshot.entry.timestamp,
                  mediaDir: mediaDir,
                  heroTag: '${uniqueHeroTag}_expanded',
                  avatarLocalPath: snapshot.user.avatarLocalPath,
                  onTap: _navigateToDetail(context),
                ),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).scaffoldBackgroundColor.withAlpha((0.8 * 255).round()),
                  radius: 18,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.expand_less, size: 20),
                    onPressed: onToggle,
                    tooltip: 'Collapse',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  VoidCallback _navigateToDetail(BuildContext context) {
    return () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserDetailPage(
            user: snapshot.user,
            ownerId: ownerId,
            isFromHistory: true,
            snapshotJson: snapshot.fullJson,
            snapshotId: snapshot.entry.id,
            snapshotTimestamp: snapshot.entry.timestamp,
            heroTag: isExpanded ? '${uniqueHeroTag}_expanded' : uniqueHeroTag,
          ),
        ),
      );
    };
  }
}

class _PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final ValueChanged<int> onPageChanged;

  const _PaginationControls({
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.onPageChanged,
  });

  void _showJumpDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) {
        final viewInsets = MediaQuery.of(context).viewInsets;
        void clampValue() {
          final text = controller.text;
          if (text.isEmpty) return;
          final value = int.tryParse(text);
          if (value == null) return;
          final clamped = value.clamp(1, totalPages);
          if (clamped.toString() != text) {
            controller.value = TextEditingValue(
              text: clamped.toString(),
              selection: TextSelection.collapsed(
                offset: clamped.toString().length,
              ),
            );
          }
        }

        controller.addListener(clampValue);
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: '${l10n.jump_to_page} (1-$totalPages)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                autofocus: true,
                onSubmitted: (_) {
                  final page = int.tryParse(controller.text);
                  if (page != null) {
                    onPageChanged(page);
                    Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  final page = int.tryParse(controller.text);
                  if (page != null) {
                    onPageChanged(page);
                    Navigator.pop(context);
                  }
                },
                child: Text(l10n.ok),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: currentPage > 1
                      ? () => onPageChanged(currentPage - 1)
                      : null,
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: InkWell(
                    onTap: totalPages > 1
                        ? () => _showJumpDialog(context)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Tooltip(
                            message: l10n.jump_to_page,
                            child: Text(
                              '$currentPage / $totalPages',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontFeatures: [
                                  const FontFeature.tabularFigures(),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Text(
                            l10n.total(totalCount),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton.filledTonal(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: currentPage < totalPages
                      ? () => onPageChanged(currentPage + 1)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
