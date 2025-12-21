import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/twitter_user.dart';
import '../repositories/search_repository.dart';
import 'package:autonitor/services/log_service.dart';
import '../main.dart'; // For databaseProvider

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SearchRepository(db);
});

enum SearchField { restId, screenName, name, bio, location, link }

enum FilterState { all, yes, no }

enum AccountStatus { normal, suspended, deactivated, temporarilyRestricted }

@immutable
class SearchParam {
  final String ownerId;
  final String query;

  // Complex Filters
  final Set<SearchField> searchFields;
  final FilterState isProtected;
  final FilterState isVerified;
  final FilterState isFollower;
  final FilterState isFollowing;
  final Set<AccountStatus> statuses;

  const SearchParam({
    required this.ownerId,
    required this.query,
    this.searchFields = const {
      SearchField.restId,
      SearchField.screenName,
      SearchField.name,
    },
    this.isProtected = FilterState.all,
    this.isVerified = FilterState.all,
    this.isFollower = FilterState.all,
    this.isFollowing = FilterState.all,
    this.statuses = const {},
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchParam &&
          runtimeType == other.runtimeType &&
          ownerId == other.ownerId &&
          query == other.query &&
          setEquals(searchFields, other.searchFields) &&
          isProtected == other.isProtected &&
          isVerified == other.isVerified &&
          isFollower == other.isFollower &&
          isFollowing == other.isFollowing &&
          setEquals(statuses, other.statuses);

  @override
  int get hashCode =>
      ownerId.hashCode ^
      query.hashCode ^
      Object.hashAll(searchFields) ^
      isProtected.hashCode ^
      isVerified.hashCode ^
      isFollower.hashCode ^
      isFollowing.hashCode ^
      Object.hashAll(statuses);

  SearchParam copyWith({
    String? ownerId,
    String? query,
    Set<SearchField>? searchFields,
    FilterState? isProtected,
    FilterState? isVerified,
    FilterState? isFollower,
    FilterState? isFollowing,
    Set<AccountStatus>? statuses,
  }) {
    return SearchParam(
      ownerId: ownerId ?? this.ownerId,
      query: query ?? this.query,
      searchFields: searchFields ?? this.searchFields,
      isProtected: isProtected ?? this.isProtected,
      isVerified: isVerified ?? this.isVerified,
      isFollower: isFollower ?? this.isFollower,
      isFollowing: isFollowing ?? this.isFollowing,
      statuses: statuses ?? this.statuses,
    );
  }
}

const int _kSearchResultsPageSize = 20; // Increased slightly

class SearchResultsNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<TwitterUser>, SearchParam> {
  final List<TwitterUser> _users = [];
  bool _hasMore = true;
  bool _isFetching = false;
  late SearchParam _param;

  @override
  Future<List<TwitterUser>> build(SearchParam arg) async {
    _param = arg;
    _users.clear();
    _hasMore = true;
    _isFetching = false;

    return _fetchPage(0);
  }

  Future<List<TwitterUser>> _fetchPage(int offset) async {
    final repository = ref.read(searchRepositoryProvider);
    try {
      final newUsers = await repository.searchUsersInContext(
        _param.ownerId,
        _param.query.isEmpty
            ? SearchParam(ownerId: _param.ownerId, query: '')
            : _param,
        limit: _kSearchResultsPageSize,
        offset: offset,
      );

      if (newUsers.length < _kSearchResultsPageSize) {
        _hasMore = false;
      }

      if (offset == 0) {
        _users.clear();
      }
      _users.addAll(newUsers);

      return List<TwitterUser>.from(_users);
    } catch (e, s) {
      logger.e(
        "SearchResultsNotifier: Error fetching page",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  Future<void> fetchMore() async {
    if (_isFetching || !_hasMore) return;
    _isFetching = true;

    try {
      final offset = _users.length;
      await _fetchPage(offset);
      state = AsyncData(List<TwitterUser>.from(_users));
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    } finally {
      _isFetching = false;
    }
  }

  bool hasMore() => _hasMore;
}

final searchResultsProvider = AsyncNotifierProvider.family
    .autoDispose<SearchResultsNotifier, List<TwitterUser>, SearchParam>(
      () => SearchResultsNotifier(),
    );
