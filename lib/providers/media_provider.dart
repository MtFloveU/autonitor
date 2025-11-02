import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// 提供 Application Support Directory 的绝对路径
/// UI 层将 watch 这个 Provider
final appSupportDirProvider = FutureProvider<String>((ref) async {
  final supportDir = await getApplicationSupportDirectory();
  return supportDir.path;
});
