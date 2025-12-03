import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../repositories/search_repository.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SearchRepository(db);
});
