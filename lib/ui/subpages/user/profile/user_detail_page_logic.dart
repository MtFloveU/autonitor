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
    _builders.add(_buildStatusPrompts);
    if (widget.user.status != 'suspended' &&
        widget.user.status != 'deactivated' &&
        widget.user.status != 'temporary_restricted' &&
        widget.user.keptIdsStatus != 'temporary_restricted') {
      _builders.add((c) => const SizedBox(height: 12));
    }
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
        final controller = _fadeControllers.length > i
            ? _fadeControllers[i]
            : null;
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
        final colorScheme = Theme.of(context).colorScheme;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: colorScheme.inverseSurface,
            content: Text(
              AppLocalizations.of(context)!.no_history_found,
              style: TextStyle(color: colorScheme.onInverseSurface),
            ),
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
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        result['timestampMs'],
      );

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

  void _showJsonDialog(BuildContext pageContext, AppLocalizations l10n) {
    String rawJson = widget.snapshotJson ?? jsonEncode(widget.user.toJson());
    if (rawJson.isEmpty) return;

    String formattedJson = rawJson;
    try {
      final dynamic jsonObj = jsonDecode(rawJson);
      const encoder = JsonEncoder.withIndent('  ');
      formattedJson = encoder.convert(jsonObj);
    } catch (_) {}

    showModalBottomSheet(
      context: pageContext,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.35,
        maxChildSize: 0.95,
        builder: (sheetBodyContext, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              Text(
                'JSON',
                style: Theme.of(sheetBodyContext).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      sheetBodyContext,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Scrollbar(
                    controller: scrollController,
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(12),
                      child: SelectableText(
                        formattedJson,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Theme.of(
                            sheetBodyContext,
                          ).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.copy),
                    label: Text(l10n.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: formattedJson));
                      Navigator.pop(sheetContext);
                      ScaffoldMessenger.of(pageContext).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text(
                            l10n.copied_to_clipboard,
                            style: TextStyle(
                              color: Theme.of(
                                pageContext,
                              ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          backgroundColor: Theme.of(
                            pageContext,
                          ).colorScheme.primaryContainer,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openExternalProfile(
    BuildContext context,
    AppLocalizations l10n, {
    String? screenName,
    String? restId,
  }) async {
    final name = screenName ?? widget.user.screenName;

    if (name == null || name.isEmpty) return;

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.45,
        minChildSize: 0.25,
        maxChildSize: 0.8,
        builder: (sheetBodyContext, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              l10n.visit,
              style: Theme.of(sheetBodyContext).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (Platform.isAndroid)
              ListTile(
                leading: const Icon(Icons.android),
                title: Text(l10n.open_in_app),
                subtitle: Text(
                  'twitter://user?screen_name=$name',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final appUrl = Uri.parse('twitter://user?screen_name=$name');
                  if (await canLaunchUrl(appUrl)) {
                    await launchUrl(appUrl);
                  }
                },
              ),
            if (restId == null || restId.isEmpty)
              ListTile(
                leading: Image.asset(
                  'assets/icon/icon_nobg.png',
                  width: 24,
                  height: 24,
                  color: IconTheme.of(sheetBodyContext).color,
                  colorBlendMode: BlendMode.srcIn,
                ),
                title: Text(l10n.open_in_autonitor),
                subtitle: Text('@$name', overflow: TextOverflow.ellipsis),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openLocalUserProfile(name, l10n);
                },
              ),
            ListTile(
              leading: const Icon(Icons.alternate_email),
              title: Text(l10n.browser_via_screen_name),
              subtitle: Text('@$name', overflow: TextOverflow.ellipsis),
              onTap: () {
                Navigator.pop(sheetContext);
                launchUrl(
                  Uri.parse('https://x.com/$name'),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
            if (restId != null && restId.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.fingerprint),
                title: Text(l10n.browser_via_rest_id),
                subtitle: Text('ID: $restId', overflow: TextOverflow.ellipsis),
                onTap: () {
                  Navigator.pop(sheetContext);
                  launchUrl(
                    Uri.parse('https://x.com/intent/user?user_id=$restId'),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openLocalUserProfile(
    String screenName,
    AppLocalizations l10n,
  ) async {
    TwitterUser? user;
    try {
      user = await ref.read(
        localUserByScreenNameProvider(
          UserLookupParam(ownerId: widget.ownerId, screenName: screenName),
        ).future,
      );
    } catch (e, s) {
      logger.e(
        'Unable to find local user @$screenName',
        error: e,
        stackTrace: s,
      );
    }

    if (!mounted) return;

    if (user == null) {
      final colorScheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              l10n.user_not_found(screenName),
              style: TextStyle(color: colorScheme.onError),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: colorScheme.error,
          ),
        );
      return;
    }

    final targetUser = user;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserDetailPage(
          user: targetUser,
          ownerId: widget.ownerId,
          heroTag: 'profile_${targetUser.restId}',
        ),
      ),
    );
  }
}
