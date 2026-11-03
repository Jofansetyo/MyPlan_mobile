import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/transaction_model.dart';

class FinanceProvider extends ChangeNotifier {
  final Box _box;

  // Kunci untuk menyimpan budget di Hive
  static const String _budgetKey = '__budget_limit__';
  static const double _defaultBudget = 1000000.0;
  static const String _categoryBudgetKeyPrefix = '__category_budget__:';
  static const String _initialBalanceCashKey = '__initial_balance_cash__';
  static const String _initialBalanceEWalletKey = '__initial_balance_ewallet__';
  static const List<String> budgetCategories = [
    'Makan',
    'Transportasi',
    'Belanja',
    'Hiburan',
    'Kesehatan',
    'Tagihan',
    'Lainnya',
  ];

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

  // ============ SALDO AWAL ============
  double get initialBalanceCash {
    final stored = _box.get(_initialBalanceCashKey);
    return stored is num ? stored.toDouble() : 0;
  }

  double get initialBalanceEWallet {
    final stored = _box.get(_initialBalanceEWalletKey);
    return stored is num ? stored.toDouble() : 0;
  }

  void setInitialBalance(String walletType, double amount) {
    if (!{'Cash', 'E-Wallet'}.contains(walletType) ||
        !amount.isFinite ||
        amount < 0) {
      throw ArgumentError('Saldo awal tidak valid.');
    }
    final key = walletType == 'Cash'
        ? _initialBalanceCashKey
        : _initialBalanceEWalletKey;
    _box.put(key, amount);
    notifyListeners();
  }

  double categoryBudget(String category) {
    final stored = _box.get('$_categoryBudgetKeyPrefix$category');
    return stored is num ? stored.toDouble() : 0;
  }

  Map<String, double> get categoryBudgets => {
        for (final category in budgetCategories)
          if (categoryBudget(category) > 0) category: categoryBudget(category),
      };

  void setCategoryBudget(String category, double limit) {
    if (!budgetCategories.contains(category) || !limit.isFinite || limit < 0) {
      throw ArgumentError('Batas anggaran kategori tidak valid.');
    }

    final key = '$_categoryBudgetKeyPrefix$category';
    if (limit == 0) {
      _box.delete(key);
    } else {
      _box.put(key, limit);
    }
    notifyListeners();
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

  double categoryExpense(String category) => transactions
      .where((t) => t.type == 'Pengeluaran' && t.category == category)
      .fold(0, (sum, item) => sum + item.amount);

  Map<String, double> get expensesByCategory {
    final totals = <String, double>{};
    for (final transaction
        in transactions.where((t) => t.type == 'Pengeluaran')) {
      totals.update(
        transaction.category,
        (total) => total + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }
    return totals;
  }

  double get remainingBalance => totalIncome - totalExpense;

  // ============ RINGKASAN BULAN INI (hanya currentMonth) ============
  double get totalIncomeCash => transactions
      .where((t) => t.type == 'Pemasukan' && t.walletType == 'Cash')
      .fold(0, (sum, item) => sum + item.amount);

  double get totalExpenseCash => transactions
      .where((t) => t.type == 'Pengeluaran' && t.walletType == 'Cash')
      .fold(0, (sum, item) => sum + item.amount);

  double get totalIncomeEWallet => transactions
      .where((t) => t.type == 'Pemasukan' && t.walletType == 'E-Wallet')
      .fold(0, (sum, item) => sum + item.amount);

  double get totalExpenseEWallet => transactions
      .where((t) => t.type == 'Pengeluaran' && t.walletType == 'E-Wallet')
      .fold(0, (sum, item) => sum + item.amount);

  // ============ SALDO SAAT INI (akumulatif semua transaksi + saldo awal) ============
  double get balanceCash =>
      initialBalanceCash +
      _allIncomeForWallet('Cash') -
      _allExpenseForWallet('Cash') +
      _allTransfersInto('Cash') -
      _allTransfersOutOf('Cash');

  double get balanceEWallet =>
      initialBalanceEWallet +
      _allIncomeForWallet('E-Wallet') -
      _allExpenseForWallet('E-Wallet') +
      _allTransfersInto('E-Wallet') -
      _allTransfersOutOf('E-Wallet');

  double get currentBalanceTotal => balanceCash + balanceEWallet;

  double _allIncomeForWallet(String wallet) => allTransactions
      .where((t) => t.type == 'Pemasukan' && t.walletType == wallet)
      .fold(0, (sum, item) => sum + item.amount);

  double _allExpenseForWallet(String wallet) => allTransactions
      .where((t) => t.type == 'Pengeluaran' && t.walletType == wallet)
      .fold(0, (sum, item) => sum + item.amount);

  double _allTransfersInto(String wallet) => allTransactions
      .where((t) => t.type == 'Transfer' && t.transferToWallet == wallet)
      .fold(0, (sum, item) => sum + item.amount);

  double _allTransfersOutOf(String wallet) => allTransactions
      .where((t) => t.type == 'Transfer' && t.walletType == wallet)
      .fold(0, (sum, item) => sum + item.amount);

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

  void transferBalance(Transaction transfer) {
    if (transfer.type != 'Transfer' ||
        transfer.amount <= 0 ||
        !transfer.amount.isFinite ||
        !{'Cash', 'E-Wallet'}.contains(transfer.walletType) ||
        !{'Cash', 'E-Wallet'}.contains(transfer.transferToWallet) ||
        transfer.walletType == transfer.transferToWallet) {
      throw ArgumentError('Data transfer saldo tidak valid.');
    }

    final availableBalance =
        transfer.walletType == 'Cash' ? balanceCash : balanceEWallet;
    // balanceCash/balanceEWallet sudah akumulatif semua transaksi + saldo awal
    if (transfer.amount > availableBalance) {
      throw ArgumentError('Saldo dompet asal tidak mencukupi.');
    }

    _box.put(transfer.id, transfer);
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
