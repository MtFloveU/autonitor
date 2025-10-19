import 'package:flutter/material.dart';
import 'home_page.dart';
import 'commits_page.dart';
import 'accounts_page.dart';
import 'settings_page.dart';

// [新文件]
// 这个Widget是应用的新“骨架”，它包含底部导航栏并管理当前显示的页面。
// 它是一个StatefulWidget，因为它需要“记住”当前选中的是哪个标签。
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  // --- 状态 ---
  // `_selectedIndex` 变量用于存储当前选中的标签页的索引
  int _selectedIndex = 0;

  // --- 页面列表 ---
  // 将所有需要在底部导航栏切换的页面放在一个列表中
  static const List<Widget> _pages = <Widget>[
    HomePage(),
    CommitsPage(),
    AccountsPage(),
    SettingsPage(),
  ];
  
  // --- 事件处理 ---
  // 当用户点击底部导航栏的某个标签时，这个函数会被调用
  void _onItemTapped(int index) {
    // setState是StatefulWidget的核心，它会通知Flutter状态已改变，需要重绘UI
    setState(() {
      _selectedIndex = index;
    });
  }

  // --- UI构建 ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar现在由主框架统一管理
      appBar: AppBar(
        title: const Text('Autonitor'),
      ),
      // body会根据_selectedIndex动态地显示列表中的对应页面
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      // IndexedStack可以保持每个页面的状态，切换回来时不会重置
      
      // 底部导航栏
      bottomNavigationBar: NavigationBar(
        // Material 3 风格的导航栏
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped, // 绑定点击事件
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow, // 总是显示文字标签
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Commits',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_alt_outlined),
            selectedIcon: Icon(Icons.people_alt),
            label: 'Accounts',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
