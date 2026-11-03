import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:my_plan/models/adapters.dart';
import 'package:my_plan/models/transaction_model.dart';
import 'package:my_plan/providers/finance_provider.dart';

void main() {
  late Directory hiveDirectory;
  late Box<dynamic> transactionBox;
  late FinanceProvider financeProvider;

  setUpAll(() async {
    hiveDirectory =
        await Directory.systemTemp.createTemp('my_plan_finance_test_');
    Hive.init(hiveDirectory.path);
    Hive.registerAdapter(TransactionAdapter());
    transactionBox = await Hive.openBox<dynamic>('transactions');
    financeProvider = FinanceProvider(box: transactionBox);
  });

  setUp(() async {
    await transactionBox.clear();
    financeProvider = FinanceProvider(box: transactionBox);
  });

  tearDownAll(() async {
    await transactionBox.close();
    await Hive.deleteFromDisk();
    await hiveDirectory.delete(recursive: true);
  });

  test('transfer moves wallet balance without changing income or expenses', () {
    financeProvider.addTransaction(
      _transaction(id: 'cash-income', type: 'Pemasukan', amount: 10000),
    );
    financeProvider.addTransaction(
      _transaction(
        id: 'ewallet-income',
        type: 'Pemasukan',
        amount: 4000,
        walletType: 'E-Wallet',
      ),
    );
    financeProvider.addTransaction(
      _transaction(id: 'cash-expense', type: 'Pengeluaran', amount: 1000),
    );

    financeProvider.transferBalance(
      _transaction(
        id: 'transfer',
        type: 'Transfer',
        amount: 2500,
        category: 'Transfer',
        walletType: 'Cash',
        transferToWallet: 'E-Wallet',
      ),
    );

    expect(financeProvider.balanceCash, 6500);
    expect(financeProvider.balanceEWallet, 6500);
    expect(financeProvider.totalIncome, 14000);
    expect(financeProvider.totalExpense, 1000);
    expect(transactionBox.get('transfer'), isA<Transaction>());
  });

  test('transfer rejects an amount greater than the source balance', () {
    expect(
      () => financeProvider.transferBalance(
        _transaction(
          id: 'too-large',
          type: 'Transfer',
          amount: 20000,
          category: 'Transfer',
          walletType: 'Cash',
          transferToWallet: 'E-Wallet',
        ),
      ),
      throwsArgumentError,
    );
    expect(transactionBox.containsKey('too-large'), isFalse);
  });

  test('category budget tracks this month expense and can be removed', () {
    financeProvider.addTransaction(
      _transaction(
        id: 'food-expense',
        type: 'Pengeluaran',
        amount: 75000,
        category: 'Makan',
      ),
    );
    financeProvider.addTransaction(
      _transaction(
        id: 'transport-expense',
        type: 'Pengeluaran',
        amount: 25000,
        category: 'Transportasi',
      ),
    );
    financeProvider.setCategoryBudget('Makan', 100000);

    expect(financeProvider.categoryExpense('Makan'), 75000);
    expect(financeProvider.categoryBudgets, {'Makan': 100000});

    financeProvider.setCategoryBudget('Makan', 0);
    expect(financeProvider.categoryBudget('Makan'), 0);
    expect(financeProvider.categoryBudgets, isEmpty);
  });
}

Transaction _transaction({
  required String id,
  required String type,
  required double amount,
  String category = 'Makan',
  String walletType = 'Cash',
  String? transferToWallet,
}) {
  return Transaction(
    id: id,
    type: type,
    amount: amount,
    category: category,
    date: DateTime.now(),
    note: type == 'Transfer' ? 'Pindah saldo' : 'Catatan',
    walletType: walletType,
    transferToWallet: transferToWallet,
  );
}
