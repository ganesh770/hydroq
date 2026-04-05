import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(const ProviderScope(child: HydroQApp()));
}

class HydroQApp extends StatelessWidget {
  const HydroQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HydroQ - water reminder and tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const _Shell(),
    );
  }
}

class _Shell extends StatefulWidget {
  const _Shell();

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _index = 0;

  final _screens = const [
    HomeScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          border: Border(top: BorderSide(color: context.divider, width: 0.5)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          backgroundColor: Colors.transparent,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.water_drop_outlined),
              selectedIcon: Icon(Icons.water_drop),
              label: 'Today',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
