import 'dart:async';
import 'package:autonitor/providers/search_provider.dart';
import 'package:autonitor/providers/search_history_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/media_provider.dart';
import 'user_detail_page.dart';
import 'user_list_page.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => SearchPageState();
}

class SearchPageState extends ConsumerState<SearchPage>
    with AutomaticKeepAliveClientMixin {
  final SearchController _searchController = SearchController();
  final ScrollController _scrollController = ScrollController();

  // Search Parameters State
  String _currentQuery = '';
  // Default filters
  SearchParam? _currentParam;

  // UI State
  bool _showHistory = true;
  Timer? _debounceTimer;
  String? _activatingHeroId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    ref.read(searchHistoryProvider);
    _searchController.addListener(_onSearchInputChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchInputChanged);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Ensure params exist with current owner
  SearchParam _getEffectiveParam(String ownerId) {
    if (_currentParam == null || _currentParam!.ownerId != ownerId) {
      _currentParam = SearchParam(ownerId: ownerId, query: _currentQuery);
    } else {
      // Keep filters but update query
      _currentParam = _currentParam!.copyWith(
        query: _currentQuery,
        ownerId: ownerId,
      );
    }
    return _currentParam!;
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (currentScroll >= maxScroll - 500) {
      final activeAccount = ref.read(activeAccountProvider);
      if (activeAccount != null && _currentQuery.isNotEmpty) {
        final param = _getEffectiveParam(activeAccount.id);
        final notifier = ref.read(searchResultsProvider(param).notifier);
        if (notifier.hasMore()) {
          notifier.fetchMore();
        }
      }
    }
  }

  void _onSearchInputChanged() {
    final text = _searchController.text.trim();

    if (text.isEmpty) {
      _debounceTimer?.cancel();
      if (!_showHistory) {
        setState(() {
          _showHistory = true;
          _currentQuery = '';
        });
      }
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      if (text != _currentQuery) {
        setState(() {
          _currentQuery = text;
          _showHistory = false;
        });
      }
    });
  }

  void _submitSearch(String query) {
    if (query.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    ref.read(searchHistoryProvider.notifier).addSearchTerm(query);

    setState(() {
      _searchController.text = query;
      _currentQuery = query;
      _showHistory = false;
    });
  }

  // lib/ui/search_page.dart

  Future<void> openComplexSearchFilters() async {
    final activeAccount = ref.read(activeAccountProvider);
    if (activeAccount == null) return;

    // Get current effective parameters
    final initialParam = _getEffectiveParam(activeAccount.id);

    // Push to Full-screen Dialog
    final SearchParam? result = await Navigator.push<SearchParam>(
      context,
      MaterialPageRoute(
        builder: (_) => SearchFiltersPage(initialParam: initialParam),
        fullscreenDialog:
            true, // Key: Enables 'X' close icon and slide-up animation
      ),
    );

    // Update state if filters were applied
    if (result != null) {
      setState(() {
        _currentParam = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Count active filters for icon badge (optional)
    int activeFilterCount = 0;
    if (_currentParam != null) {
      if (_currentParam!.isVerified != FilterState.all) activeFilterCount++;
      if (_currentParam!.isProtected != FilterState.all) activeFilterCount++;
      if (_currentParam!.isFollower != FilterState.all) activeFilterCount++;
      if (_currentParam!.isFollowing != FilterState.all) activeFilterCount++;
      if (_currentParam!.statuses.isNotEmpty) activeFilterCount++;
    }

    return PopScope(
      canPop: _searchController.text.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _searchController.clear();
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SearchBar(
                    controller: _searchController,
                    leading: const Icon(Icons.search),
                    hintText: l10n.search,
                    onSubmitted: _submitSearch,
                    trailing: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _searchController.clear(),
                        ),

                      // Filter Icon with optional Badge
                      IconButton(
                        tooltip: l10n.filter,
                        icon: Badge(
                          isLabelVisible: activeFilterCount > 0,
                          label: Text('$activeFilterCount'),
                          child: Icon(
                            Icons.tune,
                            color: activeFilterCount > 0
                                ? theme.colorScheme.primary
                                : null,
                          ),
                        ),
                        onPressed: openComplexSearchFilters,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _showHistory
                      ? _buildHistoryList(context, theme, l10n)
                      : _buildPaginatedResults(context, theme, l10n),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final history = ref.watch(searchHistoryProvider);

    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.no_recent_searches,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    Widget wrapCentered(Widget child) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: child,
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        wrapCentered(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              l10n.recent_searches,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        ...history.map(
          (term) => wrapCentered(
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(term),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => ref
                    .read(searchHistoryProvider.notifier)
                    .removeSearchTerm(term),
              ),
              onTap: () => _submitSearch(term),
            ),
          ),
        ),
        wrapCentered(const Divider()),
        wrapCentered(
          Center(
            child: TextButton(
              onPressed: () =>
                  ref.read(searchHistoryProvider.notifier).clearHistory(),
              child: Text(l10n.clear_search_history),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaginatedResults(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final activeAccount = ref.watch(activeAccountProvider);
    if (activeAccount == null) {
      return Center(child: Text(l10n.no_active_account_error));
    }

    // Use effective param which combines current query + current filters
    final param = _getEffectiveParam(activeAccount.id);

    final searchAsync = ref.watch(searchResultsProvider(param));
    final mediaDir = ref.watch(appSupportDirProvider).value;

    return searchAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (users) {
        if (users.isEmpty) {
          return Center(
            child: Text(
              l10n.no_users_in_this_category,
              style: theme.textTheme.bodyLarge,
            ),
          );
        }

        final bool hasMore = ref
            .read(searchResultsProvider(param).notifier)
            .hasMore();
        final int itemCount = users.length + (hasMore ? 1 : 0);

        return ListView.builder(
          controller: _scrollController,
          itemCount: itemCount,
          padding: const EdgeInsets.only(bottom: 16),
          cacheExtent: 8000.0,
          itemBuilder: (context, index) {
            if (index == users.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                ),
              );
            }

            final user = users[index];
            final bool isActivating = _activatingHeroId == user.restId;
            final String? heroTag = isActivating
                ? 'search_res_${user.restId}'
                : null;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Card(
                  key: ValueKey(user.restId),
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  color: Colors.transparent,
                  child: UserListTile(
                    user: user,
                    mediaDir: mediaDir,
                    followingLabel: l10n.following,
                    isFollower: user.isFollower,
                    customHeroTag: heroTag,
                    highlightQuery: _currentQuery,
                    onTap: () async {
                      if (_activatingHeroId != null) return;

                      if (_searchController.text.trim().isNotEmpty) {
                        ref
                            .read(searchHistoryProvider.notifier)
                            .addSearchTerm(_searchController.text.trim());
                      }
                      FocusScope.of(context).unfocus();

                      setState(() => _activatingHeroId = user.restId);
                      await Future.delayed(const Duration(milliseconds: 16));

                      if (!mounted) return;

                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserDetailPage(
                            user: user,
                            ownerId: activeAccount.id,
                            heroTag: 'search_res_${user.restId}',
                          ),
                        ),
                      );

                      if (mounted) {
                        await Future.delayed(const Duration(milliseconds: 350));
                        if (mounted && _activatingHeroId == user.restId) {
                          setState(() => _activatingHeroId = null);
                        }
                      }
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class SearchFiltersPage extends StatefulWidget {
  final SearchParam initialParam;

  const SearchFiltersPage({super.key, required this.initialParam});

  @override
  State<SearchFiltersPage> createState() => _SearchFiltersPageState();
}

class _SearchFiltersPageState extends State<SearchFiltersPage> {
  late Set<SearchField> _tempSearchFields;
  late FilterState _tempIsFollower;
  late FilterState _tempIsFollowing;
  late FilterState _tempIsProtected;
  late FilterState _tempIsVerified;
  late Set<AccountStatus> _tempStatuses;

  @override
  void initState() {
    super.initState();
    // Initialize state from passed parameters
    _tempSearchFields = Set.from(widget.initialParam.searchFields);
    _tempIsFollower = widget.initialParam.isFollower;
    _tempIsFollowing = widget.initialParam.isFollowing;
    _tempIsProtected = widget.initialParam.isProtected;
    _tempIsVerified = widget.initialParam.isVerified;
    _tempStatuses = Set.from(widget.initialParam.statuses);
  }

  void _onReset() {
    setState(() {
      _tempSearchFields = {
        SearchField.restId,
        SearchField.screenName,
        SearchField.name,
      };
      _tempIsFollower = FilterState.all;
      _tempIsFollowing = FilterState.all;
      _tempIsProtected = FilterState.all;
      _tempIsVerified = FilterState.all;
      _tempStatuses = {};
    });
  }

  void _onApply() {
    // Optimization: If all statuses selected, treat as empty (no filter)
    final bool isAllStatusesSelected =
        _tempStatuses.length == AccountStatus.values.length;
    final Set<AccountStatus> finalStatuses = isAllStatusesSelected
        ? {}
        : _tempStatuses;

    final newParam = widget.initialParam.copyWith(
      searchFields: _tempSearchFields,
      isFollower: _tempIsFollower,
      isFollowing: _tempIsFollowing,
      isProtected: _tempIsProtected,
      isVerified: _tempIsVerified,
      statuses: finalStatuses,
    );
    Navigator.pop(context, newParam);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Use Scaffold for full-screen layout
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.filter),
        // MD3: "Reset" as an action button in AppBar
        actions: [TextButton(onPressed: _onReset, child: Text(l10n.reset))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // [新增] 独立的 RestId 开关
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: Icon(
              Icons.fingerprint_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            title: Text(l10n.enable_restid_searching),
            subtitle: Text(l10n.enable_restid_searching_subtitle),
            // 判断 restId 是否在当前的筛选集合中
            value: _tempSearchFields.contains(SearchField.restId),
            onChanged: (bool value) {
              setState(() {
                if (value) {
                  _tempSearchFields.add(SearchField.restId);
                } else {
                  _tempSearchFields.remove(SearchField.restId);
                }
              });
            },
          ),
          Text(
            l10n.search_fields,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: SearchField.values
                .where((f) => f != SearchField.restId)
                .map((field) {
                  return FilterChip(
                    label: Text(field.name.toUpperCase()),
                    selected: _tempSearchFields.contains(field),
                    onSelected: (selected) {
                      setState(() {
                        selected
                            ? _tempSearchFields.add(field)
                            : _tempSearchFields.remove(field);
                      });
                    },
                  );
                })
                .toList(),
          ),
          const Divider(height: 32),
          _buildTriStateFilter(
            context,
            l10n.followers,
            _tempIsFollower,
            (val) => setState(() => _tempIsFollower = val),
            Icons.person_outline_outlined,
          ),
          const SizedBox(height: 12),
          _buildTriStateFilter(
            context,
            l10n.following,
            _tempIsFollowing,
            (val) => setState(() => _tempIsFollowing = val),
            Icons.person,
          ),
          const Divider(height: 32),
          Text(l10n.attributes, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _buildTriStateFilter(
            context,
            l10n.protected,
            _tempIsProtected,
            (val) => setState(() => _tempIsProtected = val),
            Icons.lock_outline,
          ),
          const SizedBox(height: 12),
          _buildTriStateFilter(
            context,
            l10n.verified,
            _tempIsVerified,
            (val) => setState(() => _tempIsVerified = val),
            Icons.verified_outlined,
          ),
          const Divider(height: 32),
          Text(
            l10n.account_status,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: AccountStatus.values.map((s) {
              return FilterChip(
                label: Text(s.name),
                selected: _tempStatuses.contains(s),
                onSelected: (selected) {
                  setState(() {
                    selected ? _tempStatuses.add(s) : _tempStatuses.remove(s);
                  });
                },
              );
            }).toList(),
          ),
          // Add extra padding at bottom to avoid FAB overlap if needed
          const SizedBox(height: 80),
        ],
      ),
      // MD3: Primary action (Apply) in a Bottom Bar or FAB
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FilledButton(onPressed: _onApply, child: Text(l10n.apply)),
        ),
      ),
    );
  }

  Widget _buildTriStateFilter(
    BuildContext context,
    String label,
    FilterState current,
    ValueChanged<FilterState> onChanged,
    IconData? icon,
  ) {
    final theme = Theme.of(context);

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 8,
      children: [
        // 左侧：icon + label
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
            ],
            Text(label, style: theme.textTheme.bodyLarge),
          ],
        ),

        // 右侧：三段选择
        SegmentedButton<FilterState>(
          segments: [
            ButtonSegment(
              value: FilterState.all,
              label: Text(AppLocalizations.of(context)!.filters_all),
            ),
            ButtonSegment(
              value: FilterState.yes,
              label: Text(AppLocalizations.of(context)!.filters_yes),
            ),
            ButtonSegment(
              value: FilterState.no,
              label: Text(AppLocalizations.of(context)!.filters_no),
            ),
          ],
          selected: {current},
          onSelectionChanged: (newSet) => onChanged(newSet.first),
          showSelectedIcon: false,
          style: const ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }
}
