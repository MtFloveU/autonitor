import 'dart:async';
import 'package:autonitor/providers/search_provider.dart';
import 'package:autonitor/providers/search_history_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/media_provider.dart';
import 'subpages/user/profile/user_detail_page.dart';
import 'subpages/user/user_list_page.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => SearchPageState();
}

class SearchPageState extends ConsumerState<SearchPage>
    with AutomaticKeepAliveClientMixin {
  final SearchController _searchController = SearchController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

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
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void requestSearchFocus() {
    if (!mounted) return;
    if (!_searchFocusNode.hasFocus) {
      _searchFocusNode.requestFocus();
    }
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
                    focusNode: _searchFocusNode,
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
          scrollCacheExtent: ScrollCacheExtent.pixels(8000.0), controller: _scrollController,
          itemCount: itemCount,
          padding: const EdgeInsets.only(bottom: 16),
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

                      final searchTerm = _searchController.text.trim();
                      if (searchTerm.isNotEmpty) {
                        ref
                            .read(searchHistoryProvider.notifier)
                            .addSearchTerm(searchTerm);
                      }

                      // 在第一个 await 之前使用 context 是安全的
                      FocusScope.of(context).unfocus();

                      setState(() => _activatingHeroId = user.restId);

                      // 异步间隙 1
                      await Future.delayed(const Duration(milliseconds: 16));

                      // 修复点：使用 context.mounted 守卫后续对 context 的使用
                      if (!context.mounted) return;

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

                      // 异步间隙 2 (从详情页返回后)
                      if (mounted) {
                        await Future.delayed(const Duration(milliseconds: 350));
                        // 再次检查 mounted 确保 State 依然存在
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.filter),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: l10n.reset,
            onPressed: _onReset,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
        children: [
          _buildSection(
            context,
            title: l10n.search_fields,
            icon: Icons.manage_search_rounded,
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  secondary: Icon(
                    Icons.fingerprint_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  title: Text(l10n.enable_restid_searching),
                  subtitle: Text(l10n.enable_restid_searching_subtitle),
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
                const Divider(height: 24, indent: 4, endIndent: 4),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: SearchField.values
                          .where((field) => field != SearchField.restId)
                          .map(
                            (field) => FilterChip(
                              label: Text(_formatEnumLabel(field.name)),
                              selected: _tempSearchFields.contains(field),
                              onSelected: (selected) {
                                setState(() {
                                  selected
                                      ? _tempSearchFields.add(field)
                                      : _tempSearchFields.remove(field);
                                });
                              },
                              showCheckmark: false,
                              avatar: _tempSearchFields.contains(field)
                                  ? Icon(
                                      Icons.check_rounded,
                                      size: 18,
                                      color: colorScheme.onSecondaryContainer,
                                    )
                                  : null,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            title: l10n.followers,
            icon: Icons.people_outline_rounded,
            child: Column(
              children: [
                _buildTriStateFilter(
                  context,
                  l10n.followers,
                  _tempIsFollower,
                  (val) => setState(() => _tempIsFollower = val),
                  Icons.person_outline_rounded,
                ),
                const Divider(height: 24, indent: 44),
                _buildTriStateFilter(
                  context,
                  l10n.following,
                  _tempIsFollowing,
                  (val) => setState(() => _tempIsFollowing = val),
                  Icons.person_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            title: l10n.attributes,
            icon: Icons.verified_user_outlined,
            child: Column(
              children: [
                _buildTriStateFilter(
                  context,
                  l10n.protected,
                  _tempIsProtected,
                  (val) => setState(() => _tempIsProtected = val),
                  Icons.lock_outline_rounded,
                ),
                const Divider(height: 24, indent: 44),
                _buildTriStateFilter(
                  context,
                  l10n.verified,
                  _tempIsVerified,
                  (val) => setState(() => _tempIsVerified = val),
                  Icons.verified_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            title: l10n.account_status,
            icon: Icons.account_circle_outlined,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AccountStatus.values
                      .map(
                        (status) => FilterChip(
                          label: Text(_formatEnumLabel(status.name)),
                          selected: _tempStatuses.contains(status),
                          onSelected: (selected) {
                            setState(() {
                              selected
                                  ? _tempStatuses.add(status)
                                  : _tempStatuses.remove(status);
                            });
                          },
                          showCheckmark: false,
                          avatar: _tempStatuses.contains(status)
                              ? Icon(
                                  Icons.check_rounded,
                                  size: 18,
                                  color: colorScheme.onSecondaryContainer,
                                )
                              : null,
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
          ),
          child: FilledButton.icon(
            onPressed: _onApply,
            icon: const Icon(Icons.done_rounded),
            label: Text(l10n.apply),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: colorScheme.primary),
              const SizedBox(width: 10),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  String _formatEnumLabel(String value) {
    return value
        .replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])'), (_) => ' ')
        .replaceFirstMapped(
          RegExp(r'^[a-z]'),
          (match) => match[0]!.toUpperCase(),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 420;
        final selector = SegmentedButton<FilterState>(
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
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 12),
            ),
            textStyle: WidgetStatePropertyAll(theme.textTheme.labelLarge),
          ),
        );

        final labelWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
            ],
            Text(label, style: theme.textTheme.bodyLarge),
          ],
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [labelWidget, const SizedBox(height: 12), selector],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [labelWidget, selector],
        );
      },
    );
  }
}
