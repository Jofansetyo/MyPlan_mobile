import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/finance_provider.dart';
import '../models/transaction_model.dart'; // <-- KUNCI UTAMA ERROR TRANSACTION
import '../widgets/paper_background.dart';
import 'add_transaction_screen.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final financeProvider = context.watch<FinanceProvider>();
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? AppTheme.darkText : AppTheme.inkNavy;
    final borderColor = isDarkMode ? AppTheme.inkSky : AppTheme.inkNavy;
    final isWarning = financeProvider.spendingPercentage > 0.75;

    final monthName = DateFormat('MMMM', 'id_ID')
        .format(financeProvider.currentMonth)
        .toUpperCase();
    final yearName = DateFormat('yyyy').format(financeProvider.currentMonth);

    return PaperBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('KEUANGAN / $monthName',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: textColor.withValues(alpha: 0.7),
                      letterSpacing: 1.2)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Catatan Uang',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontSize: 28)),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddTransactionScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16)),
                    child: const Text('+ BARU'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => financeProvider.previousMonth(),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor, width: 1.5),
                        borderRadius: BorderRadius.circular(8),
                        color:
                            isDarkMode ? AppTheme.darkPanel : AppTheme.paleSky,
                      ),
                      child: Icon(Icons.chevron_left, color: textColor),
                    ),
                  ),
                  Column(
                    children: [
                      Text(monthName,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(yearName,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                  InkWell(
                    onTap: () => financeProvider.nextMonth(),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor, width: 1.5),
                        borderRadius: BorderRadius.circular(8),
                        color:
                            isDarkMode ? AppTheme.darkPanel : AppTheme.paleSky,
                      ),
                      child: Icon(Icons.chevron_right, color: textColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _summaryItem(
                              context,
                              'MASUK',
                              financeProvider.totalIncome,
                              AppTheme.incomeGreen,
                              currencyFormatter),
                          _summaryItem(
                              context,
                              'KELUAR',
                              financeProvider.totalExpense,
                              AppTheme.expenseRed,
                              currencyFormatter),
                          _summaryItem(
                              context,
                              'SISA',
                              financeProvider.remainingBalance,
                              textColor,
                              currencyFormatter),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(color: borderColor, thickness: 1),
                      const SizedBox(height: 12),
                      Text(financeProvider.autoSummary,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(fontSize: 14)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('BATAS PENGELUARAN',
                              style: Theme.of(context).textTheme.labelLarge),
                          Text(
                              '${(financeProvider.spendingPercentage * 100).toInt()}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                      color: isWarning
                                          ? AppTheme.expenseRed
                                          : textColor)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 16,
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor, width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: financeProvider.spendingPercentage
                                .clamp(0.0, 1.0),
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(isWarning
                                ? AppTheme.expenseRed
                                : AppTheme.inkSky),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isWarning
                            ? 'Peringatan: sisa batas ${currencyFormatter.format(financeProvider.budgetLimit - financeProvider.totalExpense)}'
                            : 'Sisa batas aman: ${currencyFormatter.format(financeProvider.budgetLimit - financeProvider.totalExpense)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color:
                                  isWarning ? AppTheme.expenseRed : textColor,
                              fontWeight: isWarning
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('RIWAYAT TRANSAKSI',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(letterSpacing: 1.2)),
              const SizedBox(height: 12),
              if (financeProvider.transactions.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Text('Belum ada transaksi bulan ini.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color: textColor.withValues(alpha: 0.7))),
                    ),
                  ),
                )
              else
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: financeProvider.transactions.length,
                    separatorBuilder: (context, index) => Divider(
                        color: borderColor.withValues(alpha: 0.3),
                        height: 1,
                        thickness: 1),
                    itemBuilder: (context, index) {
                      final trx = financeProvider.transactions[index];
                      return _buildTransactionItem(context, trx, textColor,
                          borderColor, currencyFormatter);
                    },
                  ),
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryItem(BuildContext context, String label, double amount,
      Color color, NumberFormat formatter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 11)),
        const SizedBox(height: 4),
        Text(formatter.format(amount),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: color, fontSize: 14)),
      ],
    );
  }

  // METHOD INI YANG MEMAKAI TIPE DATA 'Transaction'
  Widget _buildTransactionItem(BuildContext context, Transaction trx,
      Color textColor, Color borderColor, NumberFormat formatter) {
    final isIncome = trx.type == 'Pemasukan';
    final isTransfer = trx.type == 'Transfer';
    final amountColor = isTransfer
        ? textColor
        : isIncome
            ? AppTheme.incomeGreen
            : AppTheme.expenseRed;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trx.note,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                    '${isTransfer ? '${trx.walletType} ke ${trx.transferToWallet}' : trx.category} / ${DateFormat('d MMM').format(trx.date)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: textColor.withValues(alpha: 0.7), fontSize: 12)),
              ],
            ),
          ),
          Text(
              '${isTransfer ? '' : isIncome ? '+' : '-'}${formatter.format(trx.amount)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: amountColor,
                    fontSize: 14,
                  )),
          const SizedBox(width: 8),
          if (!isTransfer)
            IconButton(
              icon: Icon(Icons.edit_outlined, size: 20, color: textColor),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              tooltip: 'Ubah',
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            AddTransactionScreen(transaction: trx)));
              },
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 20, color: AppTheme.expenseRed),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            tooltip: 'Hapus',
            onPressed: () => _showDeleteDialog(context, trx),
          ),
        ],
      ),
    );
  }

  // METHOD INI JUGA MEMAKAI TIPE DATA 'Transaction'
  void _showDeleteDialog(BuildContext context, Transaction trx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.inkSky
                : AppTheme.inkNavy,
            width: 1.5,
          ),
        ),
        title: Text('Hapus catatan ini?',
            style: Theme.of(context).textTheme.titleLarge),
        content: Text(
          '${trx.note} akan dihapus dan tidak bisa dikembalikan.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        actions: [
          OutlinedButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('BATAL')),
          ElevatedButton(
            onPressed: () {
              context.read<FinanceProvider>().deleteTransaction(trx.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.expenseRed,
                foregroundColor: Colors.white),
            child: const Text('HAPUS'),
          ),
        ],
      ),
    );
  }
}
