import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:autonitor/providers/media_provider.dart';
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
import 'user_history_page.dart';

String formatJoinedTime(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  try {
    // 清理多余空格
    final cleaned = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    final parts = cleaned.split(' ');
    if (parts.length < 6) return raw;

    // 月份映射
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

  const UserDetailPage({
    super.key,
    required this.user,
    required this.ownerId,
    this.isFromHistory = false,
    this.snapshotJson,
    this.snapshotId,
    this.snapshotTimestamp,
  });

  @override
  ConsumerState<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends ConsumerState<UserDetailPage>
    with TickerProviderStateMixin {
  // builders 列表（构造每一项的 Widget）
  final List<Widget Function(BuildContext)> _builders = [];
  // 控制当前可见数量（异步逐个增加）
  int _visibleCount = 3;
  // ✅ index < 4 我们不做 fade（保证名字立即显示）
  final List<AnimationController?> _fadeControllers = [];

  @override
  void initState() {
    super.initState();
    _prepareBuilders();
    _ensureControllersList();
    _startRenderLoop();
  }

  void _ensureControllersList() {
    // 初始化 controllers 列表（保持与 builders 长度一致），只为 index >= 3 创建 controller
    _fadeControllers.clear();
    for (var i = 0; i < _builders.length; i++) {
      if (i >= 3) {
        _fadeControllers.add(
          AnimationController(vsync: this, duration: _fadeDurationFor(i)),
        );
      } else {
        _fadeControllers.add(null); // 前三个默认不使用 fade（可修改）
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
    _builders.add(_buildBannerAvatarSection);
    _builders.add(_buildButtons);
    _builders.add((c) => const SizedBox(height: 5));
    _builders.add(_buildUserInfoColumn);
    _builders.add((c) => const SizedBox(height: 5));
    _builders.add(_buildMetadataRow);
    _builders.add(_buildCountsRow);
    _builders.add(_buildPinnedTweetSection);
    _builders.add(_buildMetadataTiles);
    _builders.add(_buildIdentityTile);
    _builders.add(_buildSnapshotInfo);
  }

  Future<void> _startRenderLoop() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // 确保 controllers 数量与 builders 一致（万一 builders 在 init 后被改）
      if (_fadeControllers.length != _builders.length) {
        _ensureControllersList();
      }

      // 1) 等待路由（Hero）动画完成再显示主要内容
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
        // 若 animation 已是 completed，就跳过等待（防护）
        if (animation.status != AnimationStatus.completed) {
          await completer.future;
        }
      }

      if (!mounted) return;

      // 2) Hero 完成后立刻显示前三项（0..2）
      //    我们保持前三项不使用淡入（可选）
      setState(() {
        _visibleCount = _visibleCount < 3 ? 3 : _visibleCount;
      });

      // 3) 其余项逐个异步出现，并使用各自的 fade controller 渐显
      for (var i = 3; i < _builders.length; i++) {
        if (!mounted) return;

        // 先让 Widget 被 build（加入 ListView）
        setState(() {
          _visibleCount = i + 1;
        });

        // 触发对应的 fade 动画（如果存在 controller）
        final controller = _fadeControllers.length > i
            ? _fadeControllers[i]
            : null;
        controller?.forward();

        // 等待下一项出现（动态节奏）
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('无法打开链接: 格式错误')));
      }
      return;
    }
    try {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('无法打开链接: $e')));
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
              final l10n = AppLocalizations.of(context)!;
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
        children: List.generate(
          // 仍只 build <= _visibleCount 的元素，保留异步加载意义
          _visibleCount.clamp(0, _builders.length),
          (index) {
            // 前 3 项我们不做 fade（确保 Hero 与首批立即显示）
            if (index < 3) {
              return _builders[index](context);
            }

            // 对于后续项，如果有 controller 则使用 FadeTransition（可叠加位移）
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
              // 保底：如果没有 controller，直接显示
              return _builders[index](context);
            }
          },
        ),
      ),
    );
  }

  // ------------------------- 以下是你原有的 builder 方法（未改动逻辑） -------------------------

  Widget _buildBannerAvatarSection(BuildContext context) {
    final String highQualityNetworkUrl = (widget.user.avatarUrl ?? '')
        .replaceFirst(RegExp(r'_(normal|bigger|400x400)'), '_400x400');
    const double bannerAspectRatio = 3 / 1;
    const double avatarOverhang = 40.0;

    // 直接从 Provider 获取值，不使用 await
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

    Widget buildNetworkAvatar() {
      if (highQualityNetworkUrl.isEmpty) return const SizedBox.shrink();
      return CachedNetworkImage(
        imageUrl: highQualityNetworkUrl,
        fit: BoxFit.cover,
        width: 84,
        height: 84,
        fadeInDuration: const Duration(milliseconds: 300),
        placeholder: (c, u) => const SizedBox.shrink(),
        errorWidget: (c, u, e) => const SizedBox.shrink(),
      );
    }

    Widget buildNetworkBanner() => _buildNetworkBanner(context);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Banner
        AspectRatio(
          aspectRatio: bannerAspectRatio,
          child: bannerLocalPath != null
              ? Image.file(
                  File(bannerLocalPath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      buildNetworkBanner(),
                )
              : buildNetworkBanner(),
        ),

        // Avatar with Hero
        Positioned(
          left: 16,
          bottom: -avatarOverhang,
          child: Hero(
            tag: 'avatar_${widget.user.restId}',
            child: CircleAvatar(
              radius: 45,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 42,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                child: ClipOval(
                  child: SizedBox(
                    width: 84,
                    height: 84,
                    child: avatarLocalPath != null
                        ? Image.file(
                            File(avatarLocalPath),
                            fit: BoxFit.cover,
                            width: 84,
                            height: 84,
                            errorBuilder: (context, error, stackTrace) =>
                                buildNetworkAvatar(),
                          )
                        : buildNetworkAvatar(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkBanner(BuildContext context) {
    if (widget.user.bannerUrl != null && widget.user.bannerUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.user.bannerUrl!,
        fit: BoxFit.cover,
        placeholder: (c, u) => Container(color: Colors.grey.shade300),
        errorWidget: (c, u, e) => Container(color: Colors.grey.shade300),
      );
    }
    return Container(color: Colors.grey.shade300);
  }

  Widget _buildButtons(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // 右边访问按钮高度，和 padding 一致
    final buttonHeight = 32.0; // 对应 padding: vertical: 6 + 图标 20 ≈ 32

    return Padding(
      padding: const EdgeInsets.only(right: 16.0, top: 8.0),
      child: Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 左边历史按钮，正方形，高度和右边一致
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
                  padding: EdgeInsets.zero, // 图标紧贴按钮中心
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

            // 右边访问按钮
            FilledButton.tonalIcon(
              onPressed: () => _openExternalProfile(context, l10n),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.pink.shade100,
                foregroundColor: Colors.pink.shade800,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.open_in_new, size: 20),
              label: Text(l10n.visit),
            ),
          ],
        ),
      ),
    );
  }

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
          const SizedBox(height: 4),
          SelectableText(
            widget.user.bio ?? '',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Wrap(
        spacing: 16.0,
        runSpacing: 4.0,
        children: [
          if (widget.user.location != null && widget.user.location!.isNotEmpty)
            _buildIconText(
              context,
              Icons.location_on_outlined,
              widget.user.location!,
            ),
          if (widget.user.link != null && widget.user.link!.isNotEmpty)
            _buildLinkItem(context, widget.user.link!),
          _buildIconText(
            context,
            Icons.calendar_month_outlined,
            l10n.joined(formatJoinedTime(widget.user.joinedTime)),
          ),
        ],
      ),
    );
  }

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

  void _openExternalProfile(BuildContext context, AppLocalizations l10n) async {
    final screenName = widget.user.screenName;
    if (screenName == null || screenName.isEmpty) return;
    final appUrl = Uri.parse('twitter://user?screen_name=$screenName');
    final webUrl = Uri.parse('https://x.com/$screenName');
    if (await canLaunchUrl(appUrl)) {
      await launchUrl(appUrl);
    } else {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }
}
