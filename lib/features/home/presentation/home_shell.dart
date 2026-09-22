import 'package:flutter/material.dart';
import 'package:trail_path/core/localization/app_localizations.dart';
import 'package:trail_path/features/offline/presentation/offline_screen.dart';
import 'package:trail_path/features/outdoor/presentation/outdoor_screen.dart';
import 'package:trail_path/features/planner/presentation/planner_screen.dart';
import 'package:trail_path/features/recording/presentation/record_screen.dart';
import 'package:trail_path/features/routes/presentation/routes_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const List<Widget> _pages = [
    PlannerScreen(),
    RecordScreen(),
    RoutesScreen(),
    OfflineScreen(),
    OutdoorScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() => _index = value);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.route_outlined),
            selectedIcon: const Icon(Icons.route),
            label: strings.planner,
          ),
          NavigationDestination(
            icon: const Icon(Icons.radio_button_checked_outlined),
            selectedIcon: const Icon(Icons.radio_button_checked),
            label: strings.record,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bookmark_outline),
            selectedIcon: const Icon(Icons.bookmark),
            label: strings.routes,
          ),
          NavigationDestination(
            icon: const Icon(Icons.cloud_download_outlined),
            selectedIcon: const Icon(Icons.cloud_done_rounded),
            label: strings.offline,
          ),
          NavigationDestination(
            icon: const Icon(Icons.landscape_outlined),
            selectedIcon: const Icon(Icons.landscape_rounded),
            label: strings.outdoor,
          ),
        ],
      ),
    );
  }
}
