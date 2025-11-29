import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:autonitor/providers/media_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:cached_network_image/cached_network_image.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/twitter_user.dart';
import 'user_history_page.dart';

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
    _builders.add(_buildVisitButton);
    _builders.add((c) => const SizedBox(height: 5));
    _builders.add(_buildUserInfoColumn);
    _builders.add((c) => const SizedBox(height: 5));
    _builders.add(_buildMetadataRow);
    _builders.add(_buildCountsRow);
    _builders.add(_buildExternalLinksSection);
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
          if (!widget.isFromHistory)
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: AppLocalizations.of(context)!.history,
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

  Widget _buildVisitButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(right: 16.0, top: 8.0),
      child: Align(
        alignment: Alignment.centerRight,
        child: FilledButton.tonalIcon(
          onPressed: () => _showJsonDialog(context, l10n),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.pink.shade100,
            foregroundColor: Colors.pink.shade800,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          ),
          icon: const Icon(Icons.description_outlined, size: 20),
          label: const Text('View on Twitter'),
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
            '${l10n.joined} ${widget.user.joinedTime}',
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

  Widget _buildExternalLinksSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.view_on_twitter,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          _buildExternalLinks(context),
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
        widget.snapshotTimestamp == null)
      return const SizedBox.shrink();
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
    return Row(
      children: [
        Flexible(
          child: SelectableText.rich(
            TextSpan(
              children: [
                // @username
                TextSpan(
                  text: '@${widget.user.screenName ?? ''} ',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
                ),

                // Follows you 标签，如果为 true 才显示
                if (widget.user.isFollower)
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        l10n.follows_you,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAutomation(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Flexible(
          child: SelectableText.rich(
            TextSpan(
              children: [
                // @username
                TextSpan(
                  text: '@${widget.user.screenName ?? ''} ',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
                ),

                // Follows you 标签，如果为 true 才显示
                if (widget.user.isFollower)
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        l10n.follows_you,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
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

  Widget _buildExternalLinks(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildExternalLinkItem(
            context,
            'ByScreenName',
            'https://x.com/${widget.user.screenName}',
          ),
          const SizedBox(width: 12),
          _buildExternalLinkItem(
            context,
            'ByRestId',
            'https://x.com/intent/user?user_id=${widget.user.restId}',
          ),
        ],
      ),
    );
  }

  Widget _buildExternalLinkItem(
    BuildContext context,
    String title,
    String url,
  ) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.link,
            color: Theme.of(context).colorScheme.primary,
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => _launchURL(context, url),
                  child: Text(
                    url,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.blue,
                    ),
                  ),
                ),
              ],
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
        title: const Text('View on Twitter'),
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
}
