import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../providers/log_provider.dart'; // <--- Import the provider file

// --- 2. Create a custom LogOutput ---
class _RiverpodLogOutput extends LogOutput {

  @override
  void output(OutputEvent event) {
    for (var line in event.lines) {
      
      // --- MODIFICATION: Call the global notifier ---
      // (修改：调用全局 notifier)
      globalLogHistoryNotifier.addLog(line);
      // --- END MODIFICATION ---
    }
  }

}

// --- 3. RESTORE the global logger variable ---
// (恢复全局的 logger 变量)
final logger = Logger(
  printer: SimplePrinter(
    colors: false,
    printTime: true,
  ),

  filter: ProductionFilter(), // ✅ 永远启用日志（新增）

  // (Set the output to *both* Console and our new Notifier)
  output: MultiOutput([
    if (!bool.fromEnvironment('dart.vm.product')) ConsoleOutput(), // ✅ 仅在非 release 下输出到控制台
    _RiverpodLogOutput(), // (This sends to our LogHistoryNotifier)
  ]),
);

// --- 4. REWRITE the loggerProvider ---
// (重写 loggerProvider)
final loggerProvider = Provider<Logger>((ref) {
  // (The provider now just returns the global instance)
  // (provider 现在只返回全局实例)
  return logger;
});
