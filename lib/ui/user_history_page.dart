import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/twitter_user.dart';
import '../l10n/app_localizations.dart';

class UserHistoryPage extends ConsumerWidget {
  final TwitterUser user;

  const UserHistoryPage({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final userId = user.id;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.user_history_page_title),
            SizedBox(height: 2),
            Text(
              '@$userId',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
      body: Center(child: Text('History for @$userId will go here.')),
    );
  }
}
