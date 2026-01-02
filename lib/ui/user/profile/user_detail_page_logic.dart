part of 'user_detail_page.dart';

extension _UserDetailPageLogic on _UserDetailPageState {
  void _ensureControllersList() {
    _fadeControllers.clear();
    for (var i = 0; i < _builders.length; i++) {
      if (i >= 2) {
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
    _builders.add(_buildBannerAvatarSection);
    _builders.add((c) => const SizedBox(height: 5));
    _builders.add(_buildUserInfoColumn);
    _builders.add((c) => const SizedBox(height: 12));
    _builders.add(_buildMetadataRow);
    _builders.add((c) => const SizedBox(height: 5));
    _builders.add(_buildFlexibleStatGrid);
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

      _setState(() {
        _visibleCount = _visibleCount < 2 ? 2 : _visibleCount;
      });

      for (var i = 2; i < _builders.length; i++) {
        if (!mounted) return;
        _setState(() {
          _visibleCount = i + 1;
        });
        final controller = _fadeControllers.length > i ? _fadeControllers[i] : null;
        controller?.forward();
        await Future.delayed(_delayFor(i));
      }
    });
  }

  void _launchURL(BuildContext context, String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    final Uri? uri = Uri.tryParse(urlString);
    if (uri == null) {
      if (mounted) logger.e('Unable to parse URL: invalid format');
      return;
    }
    try {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (e) {
      if (mounted) logger.e('Unable to launch URL: $e');
    }
  }

  Future<void> _showLatestDiff(BuildContext context) async {
    if (_isCheckingHistory) return;
    _setState(() => _isCheckingHistory = true);

    try {
      final repository = ref.read(historyRepositoryProvider);
      final result = await repository.getLatestRelevantDiff(
        widget.ownerId,
        widget.user.restId,
      );

      if (!context.mounted) return;

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.no_history_found),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final String rawDiff = result['diffJson'];
      final Map<String, dynamic> uiDiffMap = {};
      final keyMapping = {'avatar_url': 'avatar', 'banner_url': 'banner'};

      try {
        final parsed = jsonDecode(rawDiff) as Map<String, dynamic>;
        parsed.forEach((k, v) {
          final mappedKey = keyMapping[k] ?? k;
          uiDiffMap[mappedKey] = v;
        });
      } catch (_) {}

      final currentUserMap = widget.user.toJson();
      final cardJson = jsonEncode({'diff': uiDiffMap, 'user': currentUserMap});
      final timestamp = DateTime.fromMillisecondsSinceEpoch(result['timestampMs']);

      showModalBottomSheet(
        context: context,
        useSafeArea: true,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (ctx) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.4,
            minChildSize: 0.2,
            maxChildSize: 0.8,
            builder: (context, scrollController) {
              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Text(
                    AppLocalizations.of(context)!.changes_since_last_update,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ProfileChangeCard(
                    jsonContent: cardJson,
                    timestamp: timestamp,
                    mediaDir: ref.read(appSupportDirProvider).value,
                    heroTag: 'diff_detail_${widget.user.restId}',
                    avatarLocalPath: widget.user.avatarLocalPath,
                  ),
                  const SizedBox(height: 32),
                ],
              );
            },
          );
        },
      );
    } finally {
      if (mounted) _setState(() => _isCheckingHistory = false);
    }
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
                  behavior: SnackBarBehavior.floating,
                  content: Text(
                    l10n.copied_to_clipboard,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
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