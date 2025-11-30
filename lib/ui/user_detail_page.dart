import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:autonitor/providers/media_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:cached_network_image/cached_network_image.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/twitter_user.dart';
import '../services/log_service.dart';
import 'user_history_page.dart';
import 'full_screen_image_viewer.dart';

String formatJoinedTime(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  try {
    final cleaned = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    final parts = cleaned.split(' ');
    if (parts.length < 6) return raw;

    final monthMap = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };
    final month = monthMap[parts[1]];
    if (month == null) return raw;

    final day = int.parse(parts[2]);
    final timeParts = parts[3].split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final second = int.parse(timeParts[2]);
    final year = int.parse(parts[5]);

    final utc = DateTime.utc(year, month, day, hour, minute, second);
    final local = utc.toLocal();

    final formatter = DateFormat.yMd().add_Hms();
    return formatter.format(local);
  } catch (e) {
    debugPrint('formatJoinTime error: $e');
    return raw;
  }
}

class UserDetailPage extends ConsumerStatefulWidget {
  final TwitterUser user;
  final String ownerId;
  final bool isFromHistory;
  final String? snapshotJson;
  final int? snapshotId;
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
  int _visibleCount = 3;
  final List<AnimationController?> _fadeControllers = [];

  @override
  void initState() {
    super.initState();
    _prepareBuilders();
    _ensureControllersList();
    _startRenderLoop();
  }

  void _ensureControllersList() {
    _fadeControllers.clear();
    for (var i = 0; i < _builders.length; i++) {
      if (i >= 3) {
        _fadeControllers.add(
          AnimationController(vsync: this, duration: _fadeDurationFor(i)),
        );
      } else {
        _fadeControllers.add(null);
      }
    }
  }

  Duration _fadeDurationFor(int index) {
    final base = 60;
    final step = 5;
    return Duration(milliseconds: base + (index * step));
  }

  Duration _delayFor(int index) {
    final base = 14;
    final step = 4;
    return Duration(milliseconds: base + (index * step));
  }

  void _prepareBuilders() {
    _builders.clear();
    // 1. Banner + Avatar + Buttons (Merged Section)
    _builders.add(_buildBannerAvatarSection);

    // 2. User Info
    _builders.add((c) => const SizedBox(height: 5));
    _builders.add(_buildUserInfoColumn);
    _builders.add((c) => const SizedBox(height: 12));

    // 3. Metadata (Location, Link, Joined)
    _builders.add(_buildMetadataRow);

    // 6. Flexible Grid (Statistics Table)
    _builders.add((c) => const SizedBox(height: 5));
    _builders.add(_buildFlexibleStatGrid);

    // 7. Extra Info
    _builders.add(_buildPinnedTweetSection);
    _builders.add(_buildIdentityTile);
    _builders.add(_buildSnapshotInfo);
  }

  Future<void> _startRenderLoop() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      if (_fadeControllers.length != _builders.length) {
        _ensureControllersList();
      }

      final route = ModalRoute.of(context);
      final animation = route?.animation;
      if (animation != null && animation.status != AnimationStatus.completed) {
        final completer = Completer<void>();
        late final AnimationStatusListener listener;
        listener = (status) {
          if (status == AnimationStatus.completed) {
            animation.removeStatusListener(listener);
            if (!completer.isCompleted) completer.complete();
          }
        };
        animation.addStatusListener(listener);
        if (animation.status != AnimationStatus.completed) {
          await completer.future;
        }
      }

      if (!mounted) return;

      setState(() {
        _visibleCount = _visibleCount < 3 ? 3 : _visibleCount;
      });

      for (var i = 3; i < _builders.length; i++) {
        if (!mounted) return;
        setState(() {
          _visibleCount = i + 1;
        });
        final controller = _fadeControllers.length > i
            ? _fadeControllers[i]
            : null;
        controller?.forward();
        await Future.delayed(_delayFor(i));
      }
    });
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

  void _launchURL(BuildContext context, String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    final Uri? uri = Uri.tryParse(urlString);
    if (uri == null) {
      if (mounted) {
        logger.e('Unable to parse URL: invalid format');
      }
      return;
    }
    try {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (e) {
      if (mounted) {
        logger.e('Unable to launch URL: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user.name ?? 'Unknown'),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            offset: const Offset(0, 40),
            onSelected: (value) {
              if (value == 'json') {
                final l10n = AppLocalizations.of(context)!;
                _showJsonDialog(context, l10n);
              }
            },
            itemBuilder: (context) {
              return [
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
                      Text('JSON'),
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
          if (index < 3) {
            return _builders[index](context);
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
                child: _builders[index](context),
              ),
            );
          } else {
            return _builders[index](context);
          }
        }),
      ),
    );
  }

  // --- Header Section with Fixed Layout ---

  Widget _buildBannerAvatarSection(BuildContext context) {
    final String highQualityAvatarUrl = (widget.user.avatarUrl ?? '')
        .replaceFirst(RegExp(r'_(normal|bigger|400x400)'), '_400x400');
    final mediaDir = ref.watch(appSupportDirProvider).value;

    final String? avatarLocalPath =
        (mediaDir != null &&
            widget.user.avatarLocalPath != null &&
            widget.user.avatarLocalPath!.isNotEmpty)
        ? p.join(mediaDir, widget.user.avatarLocalPath!)
        : null;

    final String? bannerLocalPath =
        (mediaDir != null &&
            widget.user.bannerLocalPath != null &&
            widget.user.bannerLocalPath!.isNotEmpty)
        ? p.join(mediaDir, widget.user.bannerLocalPath!)
        : null;

    ImageProvider? avatarProvider;
    if (avatarLocalPath != null) {
      avatarProvider = FileImage(File(avatarLocalPath));
    } else if (highQualityAvatarUrl.isNotEmpty) {
      avatarProvider = CachedNetworkImageProvider(highQualityAvatarUrl);
    }

    ImageProvider? bannerProvider;
    if (bannerLocalPath != null) {
      bannerProvider = FileImage(File(bannerLocalPath));
    } else if (widget.user.bannerUrl != null &&
        widget.user.bannerUrl!.isNotEmpty) {
      bannerProvider = CachedNetworkImageProvider(widget.user.bannerUrl!);
    }

    final avatarHeroTag = widget.heroTag ?? 'avatar_${widget.user.restId}';
    final bannerHeroTag = 'banner_${widget.user.restId}';

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate banner height (3:1 ratio)
        final double bannerHeight = constraints.maxWidth / 3.0;
        const double avatarRadius = 45.0;
        const double avatarDiameter = avatarRadius * 2;

        // Avatar top position calculation to match original overlap
        // Original: bottom: -40. Height 90. Top = BannerHeight - (90 - 40) = BannerHeight - 50.
        final double avatarTop = bannerHeight - 50.0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: bannerProvider == null
                      ? null
                      : () => FullScreenImageViewer.show(
                          context,
                          imageProvider: bannerProvider!,
                          heroTag: bannerHeroTag,
                          imageUrl: widget.user.bannerUrl!,
                          localFilePath: bannerLocalPath ?? '',
                        ),
                  child: Hero(
                    tag: bannerHeroTag,
                    child: SizedBox(
                      height: bannerHeight,
                      width: double.infinity,
                      child: bannerProvider != null
                          ? Image(
                              image: bannerProvider,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildNetworkBanner(context),
                            )
                          : _buildNetworkBanner(context),
                    ),
                  ),
                ),
                // Button area
                Container(
                  padding: const EdgeInsets.only(top: 8.0, right: 16.0),
                  // Ensure minimum height to cover avatar overhang (40px) plus margin
                  constraints: const BoxConstraints(minHeight: 45.0),
                  child: _buildButtonsRow(context),
                ),
              ],
            ),
            Positioned(
              left: 16,
              top: avatarTop,
              child: GestureDetector(
                onTap: avatarProvider == null
                    ? null
                    : () => FullScreenImageViewer.show(
                        context,
                        imageProvider: avatarProvider!,
                        heroTag: avatarHeroTag,
                        imageUrl: highQualityAvatarUrl,
                        localFilePath: avatarLocalPath ?? '',
                      ),
                child: Hero(
                  tag: avatarHeroTag,
                  child: CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    child: CircleAvatar(
                      radius: 42,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      child: ClipOval(
                        child: SizedBox(
                          width: avatarDiameter,
                          height: avatarDiameter,
                          child: avatarProvider != null
                              ? Image(
                                  image: avatarProvider,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox.shrink(),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNetworkBanner(BuildContext context) {
    // Fallback widget
    return Container(color: Colors.grey.shade300);
  }

  Widget _buildButtonsRow(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final buttonHeight = 32.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.isFromHistory)
          SizedBox(
            width: buttonHeight,
            height: buttonHeight,
            child: FilledButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserHistoryPage(
                      user: widget.user,
                      ownerId: widget.ownerId,
                    ),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.pink.shade100,
                foregroundColor: Colors.pink.shade800,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Icon(Icons.history_outlined, size: 20),
            ),
          ),
        const SizedBox(width: 8),
        SizedBox(
          height: buttonHeight,
          child: FilledButton.tonalIcon(
            onPressed: () => _openExternalProfile(context, l10n),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.pink.shade100,
              foregroundColor: Colors.pink.shade800,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: Size(0, buttonHeight),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.open_in_new, size: 20),
            label: Text(l10n.visit),
          ),
        ),
      ],
    );
  }

  // --- Info Sections ---

  Widget _buildUserInfoColumn(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          _buildNameHeader(context),
          _buildScreenName(context),
          _buildAutomation(context),
          _buildParodyLabel(context),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.user.bio != null && widget.user.bio!.isNotEmpty) ...[
                const SizedBox(height: 4),
                _buildBioRichText(context, widget.user.bio!),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBioRichText(BuildContext context, String bio) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final regex = RegExp(r'(@[\w]+)|(https?:\/\/[^\s]+)');
    final List<TextSpan> spans = [];
    int lastIndex = 0;

    for (final match in regex.allMatches(bio)) {
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: bio.substring(lastIndex, match.start),
            style: theme.textTheme.bodyLarge,
          ),
        );
      }

      final matchedText = match[0]!;
      if (matchedText.startsWith('@')) {
        final username = matchedText.substring(1);
        spans.add(
          TextSpan(
            text: matchedText,
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.blue),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                _openExternalProfile(context, l10n, screenName: username);
              },
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: matchedText,
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.blue),
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                final uri = Uri.tryParse(matchedText);
                if (uri != null) {
                  try {
                    await launchUrl(uri, mode: LaunchMode.platformDefault);
                  } catch (_) {}
                }
              },
          ),
        );
      }
      lastIndex = match.end;
    }

    if (lastIndex < bio.length) {
      spans.add(
        TextSpan(
          text: bio.substring(lastIndex),
          style: theme.textTheme.bodyLarge,
        ),
      );
    }

    return SelectableText.rich(TextSpan(children: spans));
  }

  Widget _buildMetadataRow(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final List<Widget> items = [];

    if (widget.user.location != null && widget.user.location!.isNotEmpty) {
      items.add(
        _buildIconText(
          context,
          Icons.location_on_outlined,
          widget.user.location!,
        ),
      );
    }

    if (widget.user.link != null && widget.user.link!.isNotEmpty) {
      items.add(_buildLinkItem(context, widget.user.link!));
    }

    items.add(
      _buildIconText(
        context,
        Icons.calendar_month_outlined,
        l10n.joined(formatJoinedTime(widget.user.joinedTime)),
      ),
    );

    if (widget.user.restId != widget.ownerId) {
      items.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mail_outlined,
              size: 16,
              color: widget.user.canDm
                  ? theme.colorScheme.tertiary
                  : theme.highlightColor,
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.tag_outlined,
              size: 16,
              color: widget.user.canMediaTag
                  ? theme.colorScheme.tertiary
                  : theme.highlightColor,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Wrap(
        spacing: 16.0,
        runSpacing: 4.0,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: items,
      ),
    );
  }

  // ignore: unused_element
  Widget _buildCountsRow(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Wrap(
        spacing: 16.0,
        runSpacing: 4.0,
        children: [
          _buildCountText(context, widget.user.followingCount, l10n.following),
          _buildCountText(context, widget.user.followersCount, l10n.followers),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildMetadataTiles(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 1, 0),
          child: Text(
            l10n.metadata,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        _buildInfoTile(
          context,
          Icons.create,
          l10n.tweets,
          widget.user.statusesCount.toString(),
        ),
        _buildInfoTile(
          context,
          Icons.image,
          l10n.media_count,
          widget.user.mediaCount.toString(),
        ),
        _buildInfoTile(
          context,
          Icons.favorite,
          l10n.likes,
          widget.user.favouritesCount.toString(),
        ),
        _buildInfoTile(
          context,
          Icons.list_alt,
          l10n.listed_count,
          widget.user.listedCount.toString(),
        ),
      ],
    );
  }

  Widget _buildFlexibleStatGrid(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Prepare all 6 data items
    final items = [
      _StatItemData(
        Icons.group_outlined,
        l10n.following,
        widget.user.followingCount.toString(),
      ),
      _StatItemData(
        Icons.group,
        l10n.followers,
        widget.user.followersCount.toString(),
      ),
      _StatItemData(
        Icons.create,
        l10n.tweets,
        widget.user.statusesCount.toString(),
      ),
      _StatItemData(
        Icons.image,
        l10n.media_count,
        widget.user.mediaCount.toString(),
      ),
      _StatItemData(
        Icons.favorite,
        l10n.likes,
        widget.user.favouritesCount.toString(),
      ),
      _StatItemData(
        Icons.list_alt,
        l10n.listed_count,
        widget.user.listedCount.toString(),
      ),
    ];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withAlpha((0.2 * 255).round()),
        ),
      ),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 16.0,
        alignment: WrapAlignment.spaceEvenly,
        children: items.map((item) => _buildGridItem(context, item)).toList(),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, _StatItemData item) {
    final double desiredWidth =
        (MediaQuery.of(context).size.width - 32 - 16 - 20) / 3;
    final double itemWidth = desiredWidth < 90 ? 90 : desiredWidth;

    return SizedBox(
      width: itemWidth,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icon,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        item.value,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinnedTweetSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (widget.user.pinnedTweetIdStr == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 1, 0),
          child: Text(
            l10n.user_content,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.left,
          ),
        ),
        _buildInfoTile(
          context,
          Icons.push_pin,
          l10n.pinned_tweet_id,
          widget.user.pinnedTweetIdStr.toString(),
        ),
      ],
    );
  }

  Widget _buildIdentityTile(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 1, 0),
          child: Text(
            AppLocalizations.of(context)!.identity,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        _buildInfoTile(
          context,
          Icons.fingerprint,
          "Rest ID",
          widget.user.restId,
        ),
      ],
    );
  }

  Widget _buildSnapshotInfo(BuildContext context) {
    if (!widget.isFromHistory ||
        widget.snapshotId == null ||
        widget.snapshotTimestamp == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Text(
        "Snapshot ID: ${widget.snapshotId}\nTimestamp: ${widget.snapshotTimestamp!.toLocal()}",
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
      ),
    );
  }

  Widget _buildNameHeader(BuildContext context) {
    return SelectableText.rich(
      TextSpan(
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        children: [
          TextSpan(text: widget.user.name),
          if (widget.user.isVerified)
            WidgetSpan(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: SvgPicture.asset(
                  'assets/icon/verified.svg',
                  width: 23,
                  height: 23,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF1DA1F2),
                    BlendMode.srcIn,
                  ),
                ),
              ),
              alignment: PlaceholderAlignment.middle,
            ),
          if (widget.user.isProtected)
            WidgetSpan(
              child: Padding(
                padding: EdgeInsets.only(
                  left: widget.user.isVerified ? 0.0 : 4.0,
                  right: 4.0,
                ),
                child: SvgPicture.asset(
                  'assets/icon/protected.svg',
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.onSurface,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              alignment: PlaceholderAlignment.middle,
            ),
        ],
      ),
    );
  }

  Widget _buildScreenName(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final children = <Widget>[
      Text(
        '@',
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
      ),
      SelectableText(
        widget.user.screenName ?? '',
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
      ),
    ];

    if (widget.user.isFollower) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border.all(color: Colors.transparent, width: 1.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              l10n.follows_you,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    if (widget.user.isFollowing) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).canvasColor,
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              l10n.following,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.normal),
            ),
          ),
        ),
      );
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }

  Widget _buildAutomation(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (widget.user.automatedScreenName == null ||
        widget.user.automatedScreenName!.isEmpty) {
      return const SizedBox.shrink();
    }
    final children = <Widget>[
      SvgPicture.asset(
        'assets/icon/bot.svg',
        width: 18,
        height: 18,
        colorFilter: ColorFilter.mode(
          Theme.of(context).hintColor,
          BlendMode.srcIn,
        ),
      ),
      const SizedBox(width: 4),
      Flexible(
        child: Text(
          l10n.automated_by(widget.user.automatedScreenName!),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(),
        ),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(children: children),
    );
  }

  Widget _buildParodyLabel(BuildContext context) {
    final label = widget.user.parodyCommentaryFanLabel;
    if (label == null || label == "None") {
      return const SizedBox.shrink();
    }
    final children = <Widget>[
      SvgPicture.asset('assets/icon/mask.svg', width: 18, height: 18),
      const SizedBox(width: 4),
      Flexible(
        child: Text(
          "$label account",
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(children: children),
    );
  }

  Widget _buildIconText(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.grey, size: 16),
        const SizedBox(width: 4),
        Flexible(
          child: SelectableText(
            text,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildLinkItem(BuildContext context, String url) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.link, color: Colors.grey, size: 16),
        const SizedBox(width: 4),
        Flexible(
          child: InkWell(
            onTap: () => _launchURL(context, url),
            child: Text(
              url,
              style: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
                decorationColor: Colors.blue,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountText(BuildContext context, int? count, String label) {
    return Text.rich(
      TextSpan(
        text: (count ?? 0).toString(),
        style: const TextStyle(fontWeight: FontWeight.bold),
        children: [
          TextSpan(
            text: ' $label',
            style: const TextStyle(
              fontWeight: FontWeight.normal,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: SelectableText(subtitle),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
    );
  }

  void _showJsonDialog(BuildContext context, AppLocalizations l10n) {
    String rawJson = widget.snapshotJson ?? jsonEncode(widget.user.toJson());
    if (rawJson.isEmpty) return;

    String formattedJson = rawJson;
    try {
      final dynamic jsonObj = jsonDecode(rawJson);
      const encoder = JsonEncoder.withIndent('  ');
      formattedJson = encoder.convert(jsonObj);
    } catch (_) {}

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('JSON'),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: TextEditingController(text: formattedJson),
              readOnly: true,
              maxLines: null,
              decoration: const InputDecoration.collapsed(hintText: null),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(l10n.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: formattedJson));
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l10n.copied_to_clipboard,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                ),
              );
            },
          ),
          ElevatedButton(
            child: Text(l10n.ok),
            onPressed: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
    );
  }

  void _openExternalProfile(
    BuildContext context,
    AppLocalizations l10n, {
    String? screenName,
  }) async {
    final name = screenName ?? widget.user.screenName;
    if (name == null || name.isEmpty) return;
    final appUrl = Uri.parse('twitter://user?screen_name=$name');
    final webUrl = Uri.parse('https://x.com/$name');
    if (await canLaunchUrl(appUrl)) {
      await launchUrl(appUrl);
    } else {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }
}

class _StatItemData {
  final IconData icon;
  final String label;
  final String value;

  _StatItemData(this.icon, this.label, this.value);
}
