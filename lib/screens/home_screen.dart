import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/paper_background.dart';
import '../providers/task_provider.dart';
import '../providers/finance_provider.dart';
import '../providers/app_provider.dart';
import 'add_transaction_screen.dart';
import 'add_task_screen.dart';
import 'settings_screen.dart';
import 'transfer_balance_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Cek alert setelah frame pertama tampil
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAlerts();
    });
  }

  void _checkAlerts() {
    final taskProvider = context.read<TaskProvider>();
    final financeProvider = context.read<FinanceProvider>();
    final appProvider = context.read<AppProvider>();

    // Hitung tugas terlambat
    final overdueTasks = taskProvider.tasks.where((t) {
      return t.status != 'Selesai' && t.deadline.isBefore(DateTime.now());
    }).toList();

    // Hitung budget
    final percentage = financeProvider.spendingPercentage;

    final alerts = <Map<String, dynamic>>[];

    // Cek tugas terlambat
    if (appProvider.deadlineReminder && overdueTasks.isNotEmpty) {
      alerts.add({
        'icon': Icons.assignment_late_outlined,
        'title': '${overdueTasks.length} Tugas Terlambat!',
        'message': overdueTasks.map((t) => '• ${t.name}').join('\n'),
        'color': AppTheme.expenseRed,
      });
    }

    // Cek budget
    if (appProvider.spendingWarning && percentage >= 0.8) {
      final isOver = percentage >= 1.0;
      final currencyFormatter = NumberFormat.currency(
          locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
      alerts.add({
        'icon': isOver ? Icons.dangerous_outlined : Icons.warning_amber_rounded,
        'title': isOver ? 'Budget Terlampaui!' : 'Pengeluaran Tinggi',
        'message': isOver
            ? 'Pengeluaran sudah ${(percentage * 100).toInt()}% dari batas!\n'
                'Sisa: ${currencyFormatter.format(financeProvider.budgetLimit - financeProvider.totalExpense)}'
            : 'Pengeluaran sudah ${(percentage * 100).toInt()}% dari batas.\n'
                'Hati-hati mengeluarkan uang lagi.',
        'color': AppTheme.expenseRed,
      });
    }

    if (alerts.isEmpty || !mounted) return;

    _showAlertDialog(alerts);
  }

  void _showAlertDialog(List<Map<String, dynamic>> alerts) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textColor = isDark ? AppTheme.darkText : AppTheme.inkNavy;

        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDark ? AppTheme.inkSky : AppTheme.inkNavy,
              width: 1.5,
            ),
          ),
          title: Row(
            children: [
              Icon(Icons.notifications_active_outlined,
                  color: AppTheme.inkSky, size: 24),
              const SizedBox(width: 8),
              Text('Peringatan', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: alerts.map((alert) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(alert['icon'] as IconData,
                        color: alert['color'] as Color, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(alert['title'] as String,
                              style: TextStyle(
                                fontFamily: 'KodeMono',
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: alert['color'] as Color,
                              )),
                          const SizedBox(height: 4),
                          Text(alert['message'] as String,
                              style: TextStyle(
                                fontFamily: 'FiraSans',
                                fontSize: 13,
                                color: textColor,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('MENGERTI'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCategoryBudgetDialog(
    FinanceProvider financeProvider, {
    String? initialCategory,
  }) async {
    var selectedCategory =
        initialCategory ?? FinanceProvider.budgetCategories.first;
    final controller = TextEditingController(
      text: financeProvider.categoryBudget(selectedCategory) > 0
          ? financeProvider.categoryBudget(selectedCategory).toInt().toString()
          : '',
    );
    final formKey = GlobalKey<FormState>();

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Anggaran Kategori'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: FinanceProvider.budgetCategories
                        .map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        selectedCategory = value;
                        final budget =
                            financeProvider.categoryBudget(selectedCategory);
                        controller.text =
                            budget > 0 ? budget.toInt().toString() : '';
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Batas per bulan',
                      prefixText: 'Rp ',
                      helperText: 'Isi 0 untuk menghapus batas.',
                    ),
                    validator: (value) {
                      final amount = double.tryParse(value ?? '');
                      if (amount == null || !amount.isFinite) {
                        return 'Masukkan jumlah yang valid.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('BATAL'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  financeProvider.setCategoryBudget(
                    selectedCategory,
                    double.parse(controller.text),
                  );
                  Navigator.pop(dialogContext);
                },
                child: const Text('SIMPAN'),
              ),
            ],
          ),
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final financeProvider = context.watch<FinanceProvider>();
    final appProvider = context.watch<AppProvider>();

    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final today = DateFormat('EEEE / d MMM', 'id_ID')
        .format(DateTime.now())
        .toUpperCase();

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? AppTheme.darkText : AppTheme.inkNavy;
    final borderColor = isDarkMode ? AppTheme.inkSky : AppTheme.inkNavy;

    final nearestTask = taskProvider.nearestTask;
    Color taskPriorityColor = AppTheme.priorityLow;
    int sisaHari = 0;

    if (nearestTask != null) {
      if (nearestTask.priority == 'Tinggi') {
        taskPriorityColor = AppTheme.priorityHigh;
      } else if (nearestTask.priority == 'Sedang') {
        taskPriorityColor = AppTheme.priorityMed;
      }
      sisaHari = nearestTask.deadline.difference(DateTime.now()).inDays;
    }

    // Cek tugas terlambat untuk banner
    final overdueTasks = taskProvider.tasks
        .where(
            (t) => t.status != 'Selesai' && t.deadline.isBefore(DateTime.now()))
        .toList();
    final recentTransactions = financeProvider.allTransactions
      ..sort((a, b) => b.date.compareTo(a.date));
    final categoryBudgets = financeProvider.categoryBudgets;
    final categoryExpenses = financeProvider.expensesByCategory;

    return PaperBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(today,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: textColor.withValues(alpha: 0.7),
                        letterSpacing: 1.2,
                      )),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Halo, ${appProvider.userName.split(' ').first}',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontSize: 28, color: textColor)),
                  IconButton(
                    icon: Icon(Icons.settings_outlined,
                        color: textColor, size: 28),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SettingsScreen()));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ====== BANNER PERINGATAN (jika ada tugas terlambat) ======
              if (overdueTasks.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.expenseRed.withValues(alpha: 0.1),
                    border: Border.all(color: AppTheme.expenseRed, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppTheme.expenseRed, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${overdueTasks.length} tugas sudah terlambat!',
                          style: const TextStyle(
                            fontFamily: 'KodeMono',
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppTheme.expenseRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // KARTU SALDO
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SALDO SAAT INI',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(color: textColor)),
                      const SizedBox(height: 12),
                      Text(
                          currencyFormatter
                              .format(financeProvider.currentBalanceTotal),
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(fontSize: 36, color: textColor)),
                      const SizedBox(height: 16),
                      Divider(color: borderColor, thickness: 1.5),
                      const SizedBox(height: 12),
                      // BARIS CASH & E-WALLET
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? AppTheme.darkPanel
                                    : AppTheme.paleSky,
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: borderColor, width: 1),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.payments_outlined,
                                          size: 14,
                                          color:
                                              textColor.withValues(alpha: 0.7)),
                                      const SizedBox(width: 4),
                                      Text('CASH',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                  fontSize: 11,
                                                  color: textColor.withValues(
                                                      alpha: 0.7))),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                      currencyFormatter
                                          .format(financeProvider.balanceCash),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color:
                                                financeProvider.balanceCash < 0
                                                    ? AppTheme.expenseRed
                                                    : textColor,
                                            fontWeight: FontWeight.bold,
                                          )),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? AppTheme.darkPanel
                                    : AppTheme.paleSky,
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: borderColor, width: 1),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                          Icons.account_balance_wallet_outlined,
                                          size: 14,
                                          color:
                                              textColor.withValues(alpha: 0.7)),
                                      const SizedBox(width: 4),
                                      Text('E-WALLET',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                  fontSize: 11,
                                                  color: textColor.withValues(
                                                      alpha: 0.7))),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                      currencyFormatter.format(
                                          financeProvider.balanceEWallet),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color:
                                                financeProvider.balanceEWallet <
                                                        0
                                                    ? AppTheme.expenseRed
                                                    : textColor,
                                            fontWeight: FontWeight.bold,
                                          )),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TransferBalanceScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.swap_horiz),
                          label: const Text('PINDAH SALDO'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Divider(color: borderColor, thickness: 1.5),
                      const SizedBox(height: 4),
                      Text(
                        'RINGKASAN ${DateFormat('MMMM yyyy', 'id_ID').format(financeProvider.currentMonth).toUpperCase()}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: textColor.withValues(alpha: 0.6),
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('PEMASUKAN',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                          fontSize: 12, color: textColor)),
                              const SizedBox(height: 4),
                              Text(
                                  '+${currencyFormatter.format(financeProvider.totalIncome)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: AppTheme.incomeGreen,
                                        fontWeight: FontWeight.bold,
                                      )),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('PENGELUARAN',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                          fontSize: 12, color: textColor)),
                              const SizedBox(height: 4),
                              Text(
                                  '-${currencyFormatter.format(financeProvider.totalExpense)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: AppTheme.expenseRed,
                                        fontWeight: FontWeight.bold,
                                      )),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ANGGARAN PER KATEGORI
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ANGGARAN KATEGORI',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    letterSpacing: 1.2,
                                    color: textColor,
                                  )),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMMM yyyy', 'id_ID')
                            .format(financeProvider.currentMonth)
                            .toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: textColor.withValues(alpha: 0.6),
                            ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () => _showCategoryBudgetDialog(financeProvider),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('ATUR'),
                  ),
                ],
              ),
              if (categoryBudgets.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Atur batas bulanan untuk memantau pengeluaran tiap kategori.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: textColor.withValues(alpha: 0.7)),
                    ),
                  ),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: categoryBudgets.entries.map((entry) {
                        final spent = categoryExpenses[entry.key] ?? 0;
                        final ratio = spent / entry.value;
                        final isOverBudget = ratio >= 1;
                        final isNearBudget = ratio >= 0.8;
                        final progressColor = isOverBudget
                            ? AppTheme.expenseRed
                            : isNearBudget
                                ? AppTheme.priorityMed
                                : AppTheme.inkSky;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.key,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(color: textColor),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => _showCategoryBudgetDialog(
                                      financeProvider,
                                      initialCategory: entry.key,
                                    ),
                                    child: const Text('UBAH'),
                                  ),
                                ],
                              ),
                              Text(
                                '${currencyFormatter.format(spent)} / ${currencyFormatter.format(entry.value)}'
                                ' • ${(ratio * 100).toInt()}%'
                                '${isOverBudget ? ' • MELEBIHI BATAS' : isNearBudget ? ' • HAMPIR BATAS' : ''}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: isOverBudget
                                          ? AppTheme.expenseRed
                                          : textColor.withValues(alpha: 0.7),
                                    ),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: ratio.clamp(0.0, 1.0),
                                  minHeight: 8,
                                  color: progressColor,
                                  backgroundColor: borderColor.withValues(
                                    alpha: 0.15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // TRANSAKSI TERBARU
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TRANSAKSI TERBARU',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            letterSpacing: 1.2,
                            color: textColor,
                          )),
                  if (recentTransactions.isNotEmpty)
                    Text(
                      '3 TERAKHIR',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: textColor.withValues(alpha: 0.6),
                          ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: recentTransactions.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Belum ada transaksi.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color: textColor.withValues(alpha: 0.7)),
                        ),
                      )
                    : Column(
                        children: recentTransactions.take(3).map((transaction) {
                          final isIncome = transaction.type == 'Pemasukan';
                          final isTransfer = transaction.type == 'Transfer';
                          final amountColor = isTransfer
                              ? textColor
                              : isIncome
                                  ? AppTheme.incomeGreen
                                  : AppTheme.expenseRed;
                          final amountPrefix = isTransfer
                              ? ''
                              : isIncome
                                  ? '+'
                                  : '-';
                          final details = isTransfer
                              ? '${transaction.walletType} ke ${transaction.transferToWallet}'
                              : '${transaction.category} • ${transaction.walletType}';
                          return ListTile(
                            leading: Icon(
                              isTransfer
                                  ? Icons.swap_horiz
                                  : Icons.payments_outlined,
                              color: amountColor,
                            ),
                            title: Text(
                              transaction.note,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '$details • ${DateFormat('d MMM', 'id_ID').format(transaction.date)}',
                            ),
                            trailing: Text(
                              '$amountPrefix${currencyFormatter.format(transaction.amount)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(color: amountColor),
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 24),

              // TUGAS TERDEKAT
              Text('TUGAS TERDEKAT',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        letterSpacing: 1.2,
                        color: textColor,
                      )),
              const SizedBox(height: 12),
              if (nearestTask != null) ...[
                Card(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                          left: BorderSide(color: taskPriorityColor, width: 8)),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nearestTask.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: textColor)),
                        const SizedBox(height: 4),
                        Text(nearestTask.course ?? 'Tanpa Mata Kuliah',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    color: textColor.withValues(alpha: 0.7))),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: sisaHari < 0
                                        ? AppTheme.expenseRed
                                        : borderColor),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                  sisaHari < 0
                                      ? 'TERLAMBAT'
                                      : 'SISA $sisaHari HARI',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                          fontSize: 11,
                                          color: sisaHari < 0
                                              ? AppTheme.expenseRed
                                              : textColor)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? AppTheme.darkBg
                                    : AppTheme.paleSky,
                                borderRadius: BorderRadius.circular(20),
                                border:
                                    Border.all(color: borderColor, width: 1),
                              ),
                              child: Text(nearestTask.status.toUpperCase(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                          fontSize: 11, color: textColor)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Tidak ada tugas terdekat. Waktunya bersantai!',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: textColor)),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const AddTransactionScreen()));
                      },
                      child: const Text('+ TRANSAKSI'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const AddTaskScreen()));
                      },
                      child: const Text('+ TUGAS'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
