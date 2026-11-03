import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../providers/finance_provider.dart';
import '../models/transaction_model.dart';
import '../widgets/paper_background.dart';
import 'add_transaction_screen.dart';
import 'transfer_balance_screen.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const List<Color> _chartColors = [
    Color(0xFF559FD1),
    Color(0xFF2E7D4F),
    Color(0xFFB7791F),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ============ BUDGET DIALOG ============
  Future<void> _showCategoryBudgetDialog(
    FinanceProvider fp, {
    String? initialCategory,
  }) async {
    var selectedCategory =
        initialCategory ?? FinanceProvider.budgetCategories.first;
    final controller = TextEditingController(
      text: fp.categoryBudget(selectedCategory) > 0
          ? fp.categoryBudget(selectedCategory).toInt().toString()
          : '',
    );
    final formKey = GlobalKey<FormState>();
    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setDialog) => AlertDialog(
            title: const Text('Anggaran Kategori'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: FinanceProvider.budgetCategories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setDialog(() {
                        selectedCategory = v;
                        final b = fp.categoryBudget(v);
                        controller.text = b > 0 ? b.toInt().toString() : '';
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Batas per bulan',
                      prefixText: 'Rp ',
                      helperText: 'Isi 0 untuk menghapus batas.',
                    ),
                    validator: (v) {
                      final a = double.tryParse(v ?? '');
                      if (a == null || !a.isFinite) {
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
                onPressed: () => Navigator.pop(ctx),
                child: const Text('BATAL'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  final amount = double.tryParse(controller.text);
                  if (amount == null || !amount.isFinite) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Masukkan jumlah yang valid.'),
                      ),
                    );
                    return;
                  }
                  fp.setCategoryBudget(
                    selectedCategory,
                    amount,
                  );
                  Navigator.pop(ctx);
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

  // ============ DELETE DIALOG ============
  void _showDeleteDialog(BuildContext context, Transaction trx) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDark ? AppTheme.inkSky : AppTheme.inkNavy,
            width: 1.5,
          ),
        ),
        title: Text('Hapus catatan ini?',
            style: Theme.of(context).textTheme.titleLarge),
        content: Text('${trx.note} akan dihapus dan tidak bisa dikembalikan.',
            style: Theme.of(context).textTheme.bodyLarge),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('BATAL'),
          ),
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

  // ============ BUILD ============
  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FinanceProvider>();
    final fmt =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.darkText : AppTheme.inkNavy;
    final borderColor = isDark ? AppTheme.inkSky : AppTheme.inkNavy;
    final monthName =
        DateFormat('MMMM', 'id_ID').format(fp.currentMonth).toUpperCase();
    final yearName = DateFormat('yyyy').format(fp.currentMonth);

    return PaperBackground(
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton.small(
                heroTag: 'fab_transfer',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TransferBalanceScreen()),
                ),
                tooltip: 'Pindah Saldo',
                child: const Icon(Icons.swap_horiz),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'fab_add_trx',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddTransactionScreen()),
                ),
                tooltip: 'Tambah Transaksi',
                child: const Icon(Icons.add),
              ),
            ],
          ),
          body: NestedScrollView(
            headerSliverBuilder: (context, _) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('KEUANGAN / $monthName',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                  color: textColor.withValues(alpha: 0.7),
                                  letterSpacing: 1.2)),
                      const SizedBox(height: 8),
                      Text('Catatan Uang',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontSize: 28)),
                      const SizedBox(height: 16),
                      // Month navigation
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _navBtn(context, Icons.chevron_left, textColor,
                              borderColor, isDark, () => fp.previousMonth()),
                          Column(children: [
                            Text(monthName,
                                style: Theme.of(context).textTheme.titleMedium),
                            Text(yearName,
                                style: Theme.of(context).textTheme.bodyMedium),
                          ]),
                          _navBtn(context, Icons.chevron_right, textColor,
                              borderColor, isDark, () => fp.nextMonth()),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelStyle: const TextStyle(
                        fontFamily: 'KodeMono',
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                    unselectedLabelStyle:
                        const TextStyle(fontFamily: 'KodeMono', fontSize: 13),
                    labelColor: textColor,
                    unselectedLabelColor: textColor.withValues(alpha: 0.5),
                    indicatorColor: isDark ? AppTheme.inkSky : AppTheme.inkNavy,
                    tabs: const [
                      Tab(text: 'RINGKASAN'),
                      Tab(text: 'ANGGARAN'),
                    ],
                  ),
                  isDark ? AppTheme.darkPanel : AppTheme.panelBg,
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _RingkasanTab(
                  fp: fp,
                  fmt: fmt,
                  textColor: textColor,
                  borderColor: borderColor,
                  isDark: isDark,
                  chartColors: _chartColors,
                  onDelete: (trx) => _showDeleteDialog(context, trx),
                ),
                _AnggaranTab(
                  fp: fp,
                  fmt: fmt,
                  textColor: textColor,
                  borderColor: borderColor,
                  isDark: isDark,
                  chartColors: _chartColors,
                  onSetBudget: (cat) =>
                      _showCategoryBudgetDialog(fp, initialCategory: cat),
                  onAddBudget: () => _showCategoryBudgetDialog(fp),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navBtn(
    BuildContext context,
    IconData icon,
    Color textColor,
    Color borderColor,
    bool isDark,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(8),
          color: isDark ? AppTheme.darkPanel : AppTheme.paleSky,
        ),
        child: Icon(icon, color: textColor),
      ),
    );
  }
}

// ============ TAB BAR DELEGATE ============
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color bgColor;
  _TabBarDelegate(this.tabBar, this.bgColor);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: bgColor, child: tabBar);
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) =>
      oldDelegate.tabBar != tabBar || oldDelegate.bgColor != bgColor;
}

// ============ RINGKASAN TAB ============
class _RingkasanTab extends StatelessWidget {
  final FinanceProvider fp;
  final NumberFormat fmt;
  final Color textColor;
  final Color borderColor;
  final bool isDark;
  final List<Color> chartColors;
  final void Function(Transaction) onDelete;

  const _RingkasanTab({
    required this.fp,
    required this.fmt,
    required this.textColor,
    required this.borderColor,
    required this.isDark,
    required this.chartColors,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isWarning = fp.spendingPercentage > 0.75;
    final expenses = fp.expensesByCategory;

    // Build chart data: top 5 + Lainnya
    final sorted = expenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();
    final rest = sorted.skip(5).fold(0.0, (sum, e) => sum + e.value);
    final chartEntries = [
      ...top,
      if (rest > 0) MapEntry('Lainnya', rest),
    ];
    final total = expenses.values.fold(0.0, (s, v) => s + v);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _summaryItem(context, 'MASUK', fp.totalIncome,
                          AppTheme.incomeGreen, fmt),
                      _summaryItem(context, 'KELUAR', fp.totalExpense,
                          AppTheme.expenseRed, fmt),
                      _summaryItem(
                          context, 'SISA', fp.remainingBalance, textColor, fmt),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: borderColor, thickness: 1),
                  const SizedBox(height: 12),
                  Text(fp.autoSummary,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontSize: 14)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Pie chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PENGELUARAN PER KATEGORI',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 16),
                  if (chartEntries.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Belum ada pengeluaran bulan ini.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color: textColor.withValues(alpha: 0.6)),
                        ),
                      ),
                    )
                  else ...[
                    SizedBox(
                      height: 180,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: List.generate(
                            chartEntries.length,
                            (i) {
                              final entry = chartEntries[i];
                              final pct =
                                  total > 0 ? (entry.value / total * 100) : 0.0;
                              return PieChartSectionData(
                                color: chartColors[i % chartColors.length],
                                value: entry.value,
                                title: '${pct.toStringAsFixed(0)}%',
                                radius: 60,
                                titleStyle: const TextStyle(
                                  fontFamily: 'KodeMono',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: List.generate(chartEntries.length, (i) {
                        final entry = chartEntries[i];
                        final color = chartColors[i % chartColors.length];
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(3)),
                            ),
                            const SizedBox(width: 6),
                            Text(entry.key,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: textColor)),
                          ],
                        );
                      }),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Budget progress
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('BATAS PENGELUARAN',
                          style: Theme.of(context).textTheme.labelLarge),
                      Text(
                        '${(fp.spendingPercentage * 100).toInt()}%',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                                color: isWarning
                                    ? AppTheme.expenseRed
                                    : textColor),
                      ),
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
                        value: fp.spendingPercentage.clamp(0.0, 1.0),
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            isWarning ? AppTheme.expenseRed : AppTheme.inkSky),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isWarning
                        ? 'Peringatan: sisa batas ${fmt.format(fp.budgetLimit - fp.totalExpense)}'
                        : 'Sisa batas aman: ${fmt.format(fp.budgetLimit - fp.totalExpense)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isWarning ? AppTheme.expenseRed : textColor,
                          fontWeight:
                              isWarning ? FontWeight.bold : FontWeight.normal,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Transaction list
          Text('RIWAYAT TRANSAKSI',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(letterSpacing: 1.2)),
          const SizedBox(height: 12),
          if (fp.transactions.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text('Belum ada transaksi bulan ini.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: textColor.withValues(alpha: 0.7))),
                ),
              ),
            )
          else
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: fp.transactions.length,
                separatorBuilder: (_, __) => Divider(
                    color: borderColor.withValues(alpha: 0.3),
                    height: 1,
                    thickness: 1),
                itemBuilder: (context, index) {
                  final trx = fp.transactions[index];
                  return _buildTransactionItem(
                      context, trx, textColor, borderColor, fmt);
                },
              ),
            ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      color: textColor.withValues(alpha: 0.7), fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${isTransfer ? '' : isIncome ? '+' : '-'}${formatter.format(trx.amount)}',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: amountColor, fontSize: 14),
          ),
          const SizedBox(width: 4),
          if (!isTransfer)
            IconButton(
              icon: Icon(Icons.edit_outlined, size: 20, color: textColor),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              tooltip: 'Ubah',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AddTransactionScreen(transaction: trx)),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 20, color: AppTheme.expenseRed),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            tooltip: 'Hapus',
            onPressed: () => onDelete(trx),
          ),
        ],
      ),
    );
  }
}

// ============ ANGGARAN TAB ============
class _AnggaranTab extends StatelessWidget {
  final FinanceProvider fp;
  final NumberFormat fmt;
  final Color textColor;
  final Color borderColor;
  final bool isDark;
  final List<Color> chartColors;
  final void Function(String category) onSetBudget;
  final VoidCallback onAddBudget;

  const _AnggaranTab({
    required this.fp,
    required this.fmt,
    required this.textColor,
    required this.borderColor,
    required this.isDark,
    required this.chartColors,
    required this.onSetBudget,
    required this.onAddBudget,
  });

  @override
  Widget build(BuildContext context) {
    final budgets = fp.categoryBudgets;
    final expenses = fp.expensesByCategory;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ANGGARAN KATEGORI',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMMM yyyy', 'id_ID')
                        .format(fp.currentMonth)
                        .toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: textColor.withValues(alpha: 0.6),
                        ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: onAddBudget,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('ATUR'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (budgets.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Belum ada anggaran.',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Atur batas bulanan per kategori agar bisa memantau pengeluaran lebih baik.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: textColor.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: budgets.entries.toList().asMap().entries.map((e) {
                    final i = e.key;
                    final entry = e.value;
                    final spent = expenses[entry.key] ?? 0;
                    final ratio = entry.value > 0 ? (spent / entry.value) : 0.0;
                    final isOver = ratio >= 1;
                    final isNear = ratio >= 0.8;
                    final progressColor = isOver
                        ? AppTheme.expenseRed
                        : isNear
                            ? AppTheme.priorityMed
                            : AppTheme.inkSky;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: chartColors[i % chartColors.length],
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(entry.key,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(color: textColor)),
                              ),
                              TextButton(
                                onPressed: () => onSetBudget(entry.key),
                                style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(40, 32)),
                                child: const Text('UBAH'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${fmt.format(spent)} / ${fmt.format(entry.value)}'
                            ' â€¢ ${(ratio * 100).toInt()}%'
                            '${isOver ? ' â€¢ MELEBIHI BATAS' : isNear ? ' â€¢ HAMPIR BATAS' : ''}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: isOver
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
                              backgroundColor:
                                  borderColor.withValues(alpha: 0.15),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          const SizedBox(height: 20),
          Text('SEMUA KATEGORI',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text(
            'Tekan ATUR untuk menambah batas pada kategori di bawah.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: textColor.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children:
                  FinanceProvider.budgetCategories.asMap().entries.map((e) {
                final category = e.value;
                final hasBudget = fp.categoryBudget(category) > 0;
                return Column(
                  children: [
                    if (e.key > 0)
                      Divider(
                          color: borderColor.withValues(alpha: 0.3), height: 1),
                    ListTile(
                      title: Text(category,
                          style: Theme.of(context).textTheme.bodyLarge),
                      subtitle: hasBudget
                          ? Text(
                              'Batas: ${fmt.format(fp.categoryBudget(category))}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: textColor.withValues(alpha: 0.6)),
                            )
                          : Text('Belum ada batas',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: textColor.withValues(alpha: 0.4))),
                      trailing: TextButton(
                        onPressed: () => onSetBudget(category),
                        child: Text(hasBudget ? 'UBAH' : 'ATUR'),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
