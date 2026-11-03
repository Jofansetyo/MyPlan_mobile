import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'providers/task_provider.dart';
import 'providers/finance_provider.dart';
import 'screens/home_screen.dart';
import 'screens/finance_screen.dart';
import 'screens/task_screen.dart';
import 'screens/history_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/add_task_screen.dart';
import 'models/adapters.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  await Hive.initFlutter();
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(TaskAdapter());

  final transactionBox = await Hive.openBox<dynamic>('transactionsBox');
  final taskBox = await Hive.openBox<dynamic>('tasksBox');

  final prefs = await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider(prefs: prefs)),
        ChangeNotifierProvider(create: (_) => TaskProvider(box: taskBox)),
        ChangeNotifierProvider(
            create: (_) => FinanceProvider(box: transactionBox)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();

    return MaterialApp(
      title: 'MyPlan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appProvider.themeMode,
      // UBAH: home sekarang SplashScreen
      home: const SplashScreen(destination: MainNavigation()),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const FinanceScreen(),
    const TaskScreen(),
    const HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final navBgColor = isDarkMode ? AppTheme.darkPanel : AppTheme.panelBg;
    final navSelectedColor = isDarkMode ? AppTheme.inkSky : AppTheme.inkNavy;
    final navUnselectedColor = isDarkMode
        ? AppTheme.darkText.withValues(alpha: 0.5)
        : AppTheme.inkNavy.withValues(alpha: 0.5);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: _currentIndex == 0 || _currentIndex == 2
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_currentIndex == 0 || _currentIndex == 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: FloatingActionButton.small(
                      heroTag: 'fab_transaction',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddTransactionScreen()),
                      ),
                      tooltip: 'Tambah Transaksi',
                      child: const Icon(Icons.account_balance_wallet_outlined),
                    ),
                  ),
                FloatingActionButton(
                  heroTag: 'fab_main',
                  onPressed: () {
                    if (_currentIndex == 2) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddTaskScreen()),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddTransactionScreen()),
                      );
                    }
                  },
                  tooltip:
                      _currentIndex == 2 ? 'Tambah Tugas' : 'Tambah Transaksi',
                  child: const Icon(Icons.add),
                ),
              ],
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDarkMode ? AppTheme.inkSky : AppTheme.inkNavy,
              width: 1.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: navBgColor,
          selectedItemColor: navSelectedColor,
          unselectedItemColor: navUnselectedColor,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: const TextStyle(
            fontFamily: 'KodeMono',
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'KodeMono',
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'HOME'),
            BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_outlined),
                activeIcon: Icon(Icons.account_balance_wallet),
                label: 'KEUANGAN'),
            BottomNavigationBarItem(
                icon: Icon(Icons.check_box_outlined),
                activeIcon: Icon(Icons.check_box),
                label: 'TUGAS'),
            BottomNavigationBarItem(
                icon: Icon(Icons.history), label: 'RIWAYAT'),
          ],
        ),
      ),
    );
  }
}
