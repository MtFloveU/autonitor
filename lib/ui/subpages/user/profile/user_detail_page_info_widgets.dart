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
    final textStyle = Theme.of(
      context,
    ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold);
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
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF1DA1F2),
                    BlendMode.srcIn,
                  ),
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
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.onSurface,
                    BlendMode.srcIn,
                  ),
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
      Text(
        '@',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      SelectableText(
        widget.user.screenName ?? '',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
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
      crossAxisAlignment: WrapCrossAlignment.start,
      children: children,
    );
  }

  Widget _buildBioRichText(BuildContext context, String bio) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final entities = <_TextEntity>[];

    if (widget.user.bioLinks.isNotEmpty) {
      final uniqueLinks =
          widget.user.bioLinks
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
          entities.add(
            _TextEntity(index, index + link.length, link, 'link', link),
          );
          startIndex = index + link.length;
        }
      }
    }

    final mentionRegex = RegExp(r'@[a-zA-Z0-9_]+');
    for (final match in mentionRegex.allMatches(bio)) {
      entities.add(
        _TextEntity(
          match.start,
          match.end,
          match.group(0)!,
          'mention',
          match.group(0)!.substring(1),
        ),
      );
    }

    entities.sort((a, b) => a.start.compareTo(b.start));
    final List<TextSpan> spans = [];
    int currentPos = 0;

    for (final entity in entities) {
      if (entity.start < currentPos) continue;
      if (entity.start > currentPos) {
        spans.add(
          TextSpan(
            text: bio.substring(currentPos, entity.start),
            style: theme.textTheme.bodyLarge,
          ),
        );
      }
      spans.add(
        TextSpan(
          text: entity.text,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => entity.type == 'link'
                ? _launchURL(context, entity.data)
                : _openExternalProfile(context, l10n, screenName: entity.data),
        ),
      );
      currentPos = entity.end;
    }

    if (currentPos < bio.length) {
      spans.add(
        TextSpan(
          text: bio.substring(currentPos),
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

    if (widget.user.professionalCategory != null &&
        widget.user.professionalCategory!.isNotEmpty) {
      items.add(
        _buildIconText(
          context,
          Icons.business_center_outlined,
          widget.user.professionalCategory!,
        ),
      );
    }
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
    int? parseDatePart(dynamic part) {
      if (part == null || part.toString().isEmpty) return null;
      return int.tryParse(part.toString());
    }

    final int? y = parseDatePart(widget.user.birthdateYear);
    final int? m = parseDatePart(widget.user.birthdateMonth);
    final int? d = parseDatePart(widget.user.birthdateDay);

    if (y != null || (m != null && d != null)) {
      DateTime dummyDate = DateTime(y ?? 2000, m ?? 1, d ?? 1);
      String locale = Localizations.localeOf(context).toString();
      String formattedBirthday = '';

      if (y != null && m != null && d != null) {
        formattedBirthday = DateFormat.yMd(locale).format(dummyDate);
      } else if (m != null && d != null) {
        formattedBirthday = DateFormat.Md(locale).format(dummyDate);
      } else if (y != null) {
        formattedBirthday = DateFormat.y(locale).format(dummyDate);
      }

      if (formattedBirthday.isNotEmpty) {
        items.add(
          _buildIconText(context, Icons.cake_outlined, formattedBirthday),
        );
      }
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
      child: Wrap(spacing: 16.0, runSpacing: 4.0, children: items),
    );
  }

  Widget _buildIconText(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 16,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: SelectableText(
            text,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLinkItem(BuildContext context, String url) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.link,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 16,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: SelectableText.rich(
            TextSpan(
              text: url,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
              recognizer: TapGestureRecognizer()
                ..onTap = () => _launchURL(context, url),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAutomation(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (widget.user.automatedScreenName == null ||
        widget.user.automatedScreenName!.isEmpty) {
      return const SizedBox.shrink();
    }
    final name = widget.user.automatedScreenName!;
    final theme = Theme.of(context);
    const marker = '__NAME__';
    final parts = l10n.automated_by(marker).split(marker);

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icon/bot.svg',
            width: 18,
            height: 18,
            colorFilter: ColorFilter.mode(theme.hintColor, BlendMode.srcIn),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(parts.first, style: theme.textTheme.bodySmall),
                Text(
                  '@',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                SelectableText.rich(
                  TextSpan(
                    text: name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () =>
                          _openExternalProfile(context, l10n, screenName: name),
                  ),
                ),
                if (parts.length > 1)
                  Text(parts.last, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParodyLabel(BuildContext context) {
    final label = widget.user.parodyCommentaryFanLabel;
    if (label == null || label == "None") return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          SvgPicture.asset('assets/icon/mask.svg', width: 18, height: 18),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              "$label account",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPrompts(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final List<Widget> prompts = [];

    // 检查封禁状态 (Taiwan: 遭停權)
    if (widget.user.status == "suspended") {
      prompts.add(
        _buildPromptCard(
          context,
          icon: Icons.lock_outlined,
          title: l10n.account_suspended,
          subtitle: l10n.account_suspended_description,
          color: theme.colorScheme.errorContainer,
          onColor: theme.colorScheme.onErrorContainer,
        ),
      );
    }

    // 检查停用状态
    if (widget.user.status == "deactivated") {
      prompts.add(
        _buildPromptCard(
          context,
          icon: Icons.no_accounts_outlined,
          title: l10n.account_deactivated,
          subtitle: l10n.account_deactivated_description,
          color: theme.colorScheme.errorContainer,
          onColor: theme.colorScheme.onErrorContainer,
        ),
      );
    }

    // 检查暂时受限状态
    if (widget.user.status == "temporarily_restricted" ||
        widget.user.keptIdsStatus == "temporarily_restricted") {
      prompts.add(
        _buildPromptCard(
          context,
          icon: Icons.warning_amber_rounded,
          title: l10n.account_temporarily_restricted,
          subtitle: l10n.account_temporarily_restricted_description,
          color: theme.colorScheme.errorContainer,
          onColor: theme.colorScheme.onErrorContainer,
        ),
      );
    }

    if (prompts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Wrap(
        spacing: 8.0, // 子组件之间的水平间距
        runSpacing: 8.0, // 行与行之间的垂直间距
        alignment: WrapAlignment.start, // 整体左对齐
        children: prompts,
      ),
    );
  }

  Widget _buildPromptCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color onColor,
  }) {
    return Card(
      elevation: 0,
      color: color,
      margin: EdgeInsets.zero, // 由 Wrap 的 spacing 控制间距
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisSize: MainAxisSize.min, // 允许卡片宽度根据内容自适应，从而在 Wrap 中并排
          crossAxisAlignment: CrossAxisAlignment.center, // 关键：强制所有内容垂直居中
          children: [
            Icon(icon, color: onColor, size: 24),
            const SizedBox(width: 12),
            // 使用 Flexible 防止文本过长导致溢出，同时在 Wrap 中能正确换行
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                // 这里不需要额外的垂直对齐设置，因为父级 Row 已经处理了
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: onColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      height: 1.2, // 微调行高
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: onColor.withAlpha(200),
                      fontSize: 12,
                      height: 1.2,
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
}
