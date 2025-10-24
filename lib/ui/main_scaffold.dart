import 'package:flutter/material.dart';
import 'home_page.dart';
import 'commits_page.dart';
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final List<Widget> pages = <Widget>[
      HomePage(onNavigateToAccounts: () => _onItemTapped(2)),
      CommitsPage(),
      AccountsPage(),
      SettingsPage(),
    ];

    final List<Widget> pagesWithVisibility = <Widget>[
      pages[0], // HomePage
      Visibility(
        visible: _selectedIndex == 1,
        maintainState: false,
        child: pages[1], // CommitsPage
      ),
      pages[2], // AccountsPage
      pages[3], // SettingsPage
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pagesWithVisibility,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.folder_outlined),
            selectedIcon: const Icon(Icons.folder_open_outlined),
            label: l10n.data,
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
