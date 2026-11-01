import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_plan/main.dart';
import 'package:my_plan/models/adapters.dart';
import 'package:my_plan/providers/app_provider.dart';
import 'package:my_plan/providers/task_provider.dart';
import 'package:my_plan/providers/finance_provider.dart';

void main() {
  setUpAll(() async {
    // Setup Hive untuk environment testing
    Hive.init('./test_hive_dir');
    Hive.registerAdapter(TransactionAdapter());
    Hive.registerAdapter(TaskAdapter());

    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  testWidgets('App builds successfully smoke test',
      (WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    final taskBox = await Hive.openBox<dynamic>('tasksBox_test');
    final transactionBox = await Hive.openBox<dynamic>('transactionsBox_test');

    await tester.pumpWidget(
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

    await tester.pumpAndSettle();

    // Cek greeting default 'Halo, Pengguna'
    expect(find.textContaining('Halo,'), findsOneWidget);
  });
}
