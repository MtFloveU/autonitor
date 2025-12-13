// lib/providers/search_history_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryNotifier extends StateNotifier<List<String>> {
  SearchHistoryNotifier() : super([]) {
    _loadHistory();
  }

  static const String _key = 'search_history_v1';
  static const int _maxHistoryLength = 20;

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_key) ?? [];
    state = history;
  }

  Future<void> addSearchTerm(String term) async {
    if (term.trim().isEmpty) return;
    final cleanTerm = term.trim();

    // Remove duplicate and move to front
    final currentList = List<String>.from(state);
    currentList.remove(cleanTerm);
    currentList.insert(0, cleanTerm);

    if (currentList.length > _maxHistoryLength) {
      currentList.removeLast();
    }

    state = currentList;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, currentList);
  }

  Future<void> removeSearchTerm(String term) async {
    final currentList = List<String>.from(state);
    currentList.remove(term);
    state = currentList;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, currentList);
  }

  Future<void> clearHistory() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

final searchHistoryProvider =
    StateNotifierProvider<SearchHistoryNotifier, List<String>>((ref) {
      return SearchHistoryNotifier();
    });
