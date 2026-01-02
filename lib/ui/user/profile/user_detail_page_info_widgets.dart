part of 'user_detail_page.dart';

extension _UserDetailPageInfoWidgets on _UserDetailPageState {
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

  Widget _buildNameHeader(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold);
    return SelectableText.rich(
      TextSpan(
        style: textStyle,
        children: [
          TextSpan(text: widget.user.name ?? "Unknown"),
          if (widget.user.isVerified)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: SvgPicture.asset(
                  'assets/icon/verified.svg',
                  width: 23,
                  height: 23,
                  colorFilter: const ColorFilter.mode(Color(0xFF1DA1F2), BlendMode.srcIn),
                ),
              ),
            ),
          if (widget.user.isProtected)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: SvgPicture.asset(
                  'assets/icon/protected.svg',
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.onSurface, BlendMode.srcIn),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScreenName(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final children = <Widget>[
      Text('@', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600)),
      SelectableText(widget.user.screenName ?? '', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600)),
    ];

    if (widget.user.isFollower) {
      children.add(Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(l10n.follows_you, style: Theme.of(context).textTheme.bodySmall),
        ),
      ));
    }
    return Wrap(crossAxisAlignment: WrapCrossAlignment.start, children: children);
  }

  Widget _buildBioRichText(BuildContext context, String bio) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final entities = <_TextEntity>[];

    if (widget.user.bioLinks.isNotEmpty) {
      final uniqueLinks = widget.user.bioLinks
          .map((e) => e['expanded_url'])
          .where((e) => e != null)
          .cast<String>()
          .toSet()
          .toList()
        ..sort((a, b) => b.length.compareTo(a.length));

      for (final link in uniqueLinks) {
        int startIndex = 0;
        while (true) {
          final index = bio.indexOf(link, startIndex);
          if (index == -1) break;
          entities.add(_TextEntity(index, index + link.length, link, 'link', link));
          startIndex = index + link.length;
        }
      }
    }

    final mentionRegex = RegExp(r'@[a-zA-Z0-9_]+');
    for (final match in mentionRegex.allMatches(bio)) {
      entities.add(_TextEntity(match.start, match.end, match.group(0)!, 'mention', match.group(0)!.substring(1)));
    }

    entities.sort((a, b) => a.start.compareTo(b.start));
    final List<TextSpan> spans = [];
    int currentPos = 0;

    for (final entity in entities) {
      if (entity.start < currentPos) continue;
      if (entity.start > currentPos) {
        spans.add(TextSpan(text: bio.substring(currentPos, entity.start), style: theme.textTheme.bodyLarge));
      }
      spans.add(TextSpan(
        text: entity.text,
        style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.primary),
        recognizer: TapGestureRecognizer()
          ..onTap = () => entity.type == 'link' 
              ? _launchURL(context, entity.data)
              : _openExternalProfile(context, l10n, screenName: entity.data),
      ));
      currentPos = entity.end;
    }

    if (currentPos < bio.length) {
      spans.add(TextSpan(text: bio.substring(currentPos), style: theme.textTheme.bodyLarge));
    }
    return SelectableText.rich(TextSpan(children: spans));
  }

  Widget _buildMetadataRow(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final List<Widget> items = [];

    if (widget.user.location != null && widget.user.location!.isNotEmpty) {
      items.add(_buildIconText(context, Icons.location_on_outlined, widget.user.location!));
    }
    if (widget.user.link != null && widget.user.link!.isNotEmpty) {
      items.add(_buildLinkItem(context, widget.user.link!));
    }
    items.add(_buildIconText(context, Icons.calendar_month_outlined, l10n.joined(formatJoinedTime(widget.user.joinedTime))));

    if (widget.user.restId != widget.ownerId) {
      items.add(Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.mail_outlined, size: 16, color: widget.user.canDm ? theme.colorScheme.tertiary : theme.highlightColor),
        const SizedBox(width: 2),
        Icon(Icons.tag_outlined, size: 16, color: widget.user.canMediaTag ? theme.colorScheme.tertiary : theme.highlightColor),
      ]));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Wrap(spacing: 16.0, runSpacing: 4.0, children: items),
    );
  }

  Widget _buildIconText(BuildContext context, IconData icon, String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: Colors.grey, size: 16),
      const SizedBox(width: 4),
      Flexible(child: SelectableText(text, style: const TextStyle(color: Colors.grey))),
    ]);
  }

  Widget _buildLinkItem(BuildContext context, String url) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.link, color: Colors.grey, size: 16),
      const SizedBox(width: 4),
      Flexible(child: SelectableText.rich(TextSpan(
        text: url,
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
        recognizer: TapGestureRecognizer()..onTap = () => _launchURL(context, url),
      ))),
    ]);
  }

  Widget _buildAutomation(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (widget.user.automatedScreenName == null || widget.user.automatedScreenName!.isEmpty) return const SizedBox.shrink();
    final name = widget.user.automatedScreenName!;
    final theme = Theme.of(context);
    const marker = '__NAME__';
    final parts = l10n.automated_by(marker).split(marker);

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(children: [
        SvgPicture.asset('assets/icon/bot.svg', width: 18, height: 18, colorFilter: ColorFilter.mode(theme.hintColor, BlendMode.srcIn)),
        const SizedBox(width: 4),
        Flexible(child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text(parts.first, style: theme.textTheme.bodySmall),
          Text('@', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
          SelectableText.rich(TextSpan(
            text: name,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
            recognizer: TapGestureRecognizer()..onTap = () => _openExternalProfile(context, l10n, screenName: name),
          )),
          if (parts.length > 1) Text(parts.last, style: theme.textTheme.bodySmall),
        ])),
      ]),
    );
  }

  Widget _buildParodyLabel(BuildContext context) {
    final label = widget.user.parodyCommentaryFanLabel;
    if (label == null || label == "None") return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(children: [
        SvgPicture.asset('assets/icon/mask.svg', width: 18, height: 18),
        const SizedBox(width: 4),
        Flexible(child: Text("$label account", style: Theme.of(context).textTheme.bodySmall)),
      ]),
    );
  }
}