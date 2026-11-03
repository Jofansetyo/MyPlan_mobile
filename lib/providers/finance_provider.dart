import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/transaction_model.dart';

class FinanceProvider extends ChangeNotifier {
  final Box _box;

  // Kunci untuk menyimpan budget di Hive
  static const String _budgetKey = '__budget_limit__';
  static const double _defaultBudget = 1000000.0;

  FinanceProvider({required Box box}) : _box = box;

  // ============ BUDGET LIMIT (dari Hive) ============
  double get budgetLimit {
    final stored = _box.get(_budgetKey);
    if (stored is num) return stored.toDouble();
    return _defaultBudget;
  }

  void setBudgetLimit(double limit) {
    if (limit > 0) {
      _box.put(_budgetKey, limit);
      notifyListeners();
    }
  }

  // ============ STATE VIEW ============
  DateTime _currentMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime get currentMonth => _currentMonth;

  void nextMonth() {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    notifyListeners();
  }

  void previousMonth() {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    notifyListeners();
  }

  // ============ GETTER ============
  List<Transaction> get allTransactions =>
      _box.values.whereType<Transaction>().toList();

  List<Transaction> get transactions {
    return allTransactions.where((t) {
      return t.date.month == _currentMonth.month &&
          t.date.year == _currentMonth.year;
    }).toList();
  }

  double get totalIncome => transactions
      .where((t) => t.type == 'Pemasukan')
      .fold(0, (sum, item) => sum + item.amount);

  double get totalExpense => transactions
      .where((t) => t.type == 'Pengeluaran')
      .fold(0, (sum, item) => sum + item.amount);

  double get remainingBalance => totalIncome - totalExpense;

  // ============ PER WALLET ============
  double get totalIncomeCash => transactions
      .where((t) => t.type == 'Pemasukan' && t.walletType == 'Cash')
      .fold(0, (sum, item) => sum + item.amount);

  double get totalExpenseCash => transactions
      .where((t) => t.type == 'Pengeluaran' && t.walletType == 'Cash')
      .fold(0, (sum, item) => sum + item.amount);

  double get balanceCash => totalIncomeCash - totalExpenseCash;

  double get totalIncomeEWallet => transactions
      .where((t) => t.type == 'Pemasukan' && t.walletType == 'E-Wallet')
      .fold(0, (sum, item) => sum + item.amount);

  double get totalExpenseEWallet => transactions
      .where((t) => t.type == 'Pengeluaran' && t.walletType == 'E-Wallet')
      .fold(0, (sum, item) => sum + item.amount);

  double get balanceEWallet => totalIncomeEWallet - totalExpenseEWallet;

  double get spendingPercentage {
    if (budgetLimit == 0) return 0;
    return totalExpense / budgetLimit;
  }

  String get autoSummary {
    final expenses =
        transactions.where((t) => t.type == 'Pengeluaran').toList();
    if (expenses.isEmpty) return "Belum ada pengeluaran bulan ini.";

    final Map<String, double> categoryTotals = {};
    for (var exp in expenses) {
      categoryTotals[exp.category] =
          (categoryTotals[exp.category] ?? 0) + exp.amount;
    }

    final topCategory =
        categoryTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
    final percentage = (spendingPercentage * 100).toInt();

    return "Pengeluaran terbesar ada di kategori ${topCategory.key}. "
        "Kamu sudah memakai $percentage% dari batas pengeluaran.";
  }

  // ============ CRUD ============
  void addTransaction(Transaction transaction) {
    _box.put(transaction.id, transaction);
    notifyListeners();
  }

  void updateTransaction(Transaction updatedTransaction) {
    _box.put(updatedTransaction.id, updatedTransaction);
    notifyListeners();
  }

  void deleteTransaction(String id) {
    _box.delete(id);
    notifyListeners();
  }
}
