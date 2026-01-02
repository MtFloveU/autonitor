part of 'user_detail_page.dart';

extension _UserDetailPageMiscWidgets on _UserDetailPageState {
  Widget _buildPinnedTweetSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (widget.user.pinnedTweetIdStr == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 1, 0),
          child: Text(
            l10n.user_content,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
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
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
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
        "RUN ID: ${widget.snapshotId}\n${DateFormat.yMd().add_Hms().format(DateTime.fromMillisecondsSinceEpoch(widget.snapshotTimestamp!.millisecondsSinceEpoch))} ",
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.outline,
        ),
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
}
