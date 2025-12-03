import 'package:autonitor/providers/search_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import 'user_detail_page.dart';

// Convert to ConsumerStatefulWidget to manage text controller state
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => SearchPageState();
}

class SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void focusSearch() {
    if (!_searchFocusNode.hasFocus) {
      _searchFocusNode.requestFocus();
    }
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() => _isSearching = true);

    try {
      final activeAccount = ref.read(activeAccountProvider);
      if (activeAccount == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select an active account first.'),
            ),
          );
        }
        return;
      }

      // Search via repository
      final user = await ref
          .read(searchRepositoryProvider)
          .searchUserInContext(activeAccount.id, query);

      if (!mounted) return;

      if (user != null) {
        // Navigate to detail page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                UserDetailPage(user: user, ownerId: activeAccount.id),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.error,
            content: Text(
              'User "$query" not found in local data.',
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 大标题滚动 AppBar
          SliverAppBar(
            expandedHeight: kToolbarHeight,
            pinned: true,
            toolbarHeight: kToolbarHeight,
            automaticallyImplyLeading: false,

            flexibleSpace: FlexibleSpaceBar(
              title: Padding(
                // ✅ 只能靠手动 Padding
                padding: const EdgeInsets.only(left: 16),
                child: Text(l10n.search),
              ),
              collapseMode: CollapseMode.pin,
            ),
          ),

          // 搜索输入框
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  labelText: 'Screen Name / Rest ID',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: _isSearching ? null : _performSearch,
                  ),
                ),
                onSubmitted: (_) => _isSearching ? null : _performSearch(),
              ),
            ),
          ),

          // Loading 指示器或占位
          SliverFillRemaining(
            hasScrollBody: false,
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
