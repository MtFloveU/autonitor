part of 'user_detail_page.dart';

extension _UserDetailPageHeaderWidgets on _UserDetailPageState {
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
        final double bannerHeight = constraints.maxWidth / 3.0;
        const double avatarRadius = 45.0;
        const double avatarDiameter = avatarRadius * 2;
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
                              errorBuilder: (_, _, _) =>
                                  _buildNetworkBanner(context),
                            )
                          : _buildNetworkBanner(context),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(top: 8.0, right: 16.0),
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
                                  errorBuilder: (_, _, _) =>
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
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                foregroundColor: Theme.of(context).colorScheme.primary,
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
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              foregroundColor: Theme.of(context).colorScheme.primary,
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
}