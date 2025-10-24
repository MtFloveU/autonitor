import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart'; 
class CommitsPage extends StatelessWidget {
  const CommitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      // 3. 添加 AppBar
      appBar: AppBar(
        title: Text(l10n.data),
      ),
      body: const Center(
        child: Text('Data Page - Coming Soon'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: 在这里添加点击搜索按钮的逻辑
        },
        child: const Icon(Icons.search),
      ),
    );
  }
}