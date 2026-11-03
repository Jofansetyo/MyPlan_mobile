import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_plan/main.dart';
import 'package:my_plan/models/adapters.dart';
import 'package:my_plan/providers/app_provider.dart';
import 'package:my_plan/providers/task_provider.dart';
import 'package:my_plan/providers/finance_provider.dart';

void main() {
  late Directory hiveDirectory;
  late Box<dynamic> taskBox;
  late Box<dynamic> transactionBox;

  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
    hiveDirectory =
        await Directory.systemTemp.createTemp('my_plan_widget_test_');
    Hive.init(hiveDirectory.path);
    Hive.registerAdapter(TransactionAdapter());
    Hive.registerAdapter(TaskAdapter());

    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    taskBox = await Hive.openBox<dynamic>('tasksBox_test');
    transactionBox = await Hive.openBox<dynamic>('transactionsBox_test');
  });

  tearDownAll(() async {
    await taskBox.close();
    await transactionBox.close();
    await hiveDirectory.delete(recursive: true);
  });

  testWidgets('App builds successfully smoke test',
      (WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();

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

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.textContaining('Halo,'), findsOneWidget);
  });
}
