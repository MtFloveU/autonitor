import 'package:flutter/material.dart';
import 'home_page.dart';
import 'search_page.dart';
import 'accounts_page.dart';
import 'settings_page.dart';
import '../l10n/app_localizations.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;
  final GlobalKey<SearchPageState> _searchPageKey = GlobalKey();
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) {
      if (index == 1) {
        // 如果再次点击搜索，可以在这里处理（例如清空或聚焦）
      }
      return;
    }

    // [核心修复] 切换页面时，强制收起键盘并取消所有焦点
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _selectedIndex = index;
    });

    _pageController.jumpToPage(index);
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final bool useSideNav = MediaQuery.of(context).size.width >= 640;

    final Color navigationBackgroundColor =
        theme.navigationBarTheme.backgroundColor ??
        theme.colorScheme.surfaceContainer;

    final List<Widget> pages = <Widget>[
      HomePage(onNavigateToAccounts: () => _onItemTapped(2)),
      SearchPage(key: _searchPageKey),
      // 将 useSideNav 传给 AccountsPage，使其根据侧边导航决定网格布局行为
      AccountsPage(useSideNav: useSideNav),
      const SettingsPage(),
    ];

    return Scaffold(
      body: Row(
        children: [
          if (useSideNav)
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: NavigationRail(
                        backgroundColor: navigationBackgroundColor,
                        selectedIndex: _selectedIndex,
                        onDestinationSelected: _onItemTapped,
                        labelType: NavigationRailLabelType.all,
                        groupAlignment: -1.0,
                        destinations: [
                          NavigationRailDestination(
                            icon: const Icon(Icons.home_outlined),
                            selectedIcon: const Icon(Icons.home),
                            label: Text(l10n.home),
                          ),
                          NavigationRailDestination(
                            icon: const Icon(Icons.search_outlined),
                            selectedIcon: const Icon(Icons.search),
                            label: Text(l10n.search),
                          ),
                          NavigationRailDestination(
                            icon: const Icon(Icons.people_alt_outlined),
                            selectedIcon: const Icon(Icons.people_alt),
                            label: Text(l10n.accounts),
                          ),
                          NavigationRailDestination(
                            icon: const Icon(Icons.settings_outlined),
                            selectedIcon: const Icon(Icons.settings),
                            label: Text(l10n.settings),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: const NeverScrollableScrollPhysics(),
              children: pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: useSideNav
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              backgroundColor: navigationBackgroundColor,
              destinations: <NavigationDestination>[
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home),
                  label: l10n.home,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.search_outlined),
                  selectedIcon: const Icon(Icons.search),
                  label: l10n.search,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.people_alt_outlined),
                  selectedIcon: const Icon(Icons.people_alt),
                  label: l10n.accounts,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.settings_outlined),
                  selectedIcon: const Icon(Icons.settings),
                  label: l10n.settings,
                ),
              ],
            ),
    );
  }
}
