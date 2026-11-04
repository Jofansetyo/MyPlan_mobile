import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../theme/app_theme.dart';
import '../providers/task_provider.dart';
import '../providers/finance_provider.dart';
import '../widgets/paper_background.dart';
import '../models/transaction_model.dart';
import '../models/task_model.dart';

// Class bantuan untuk menggabungkan data
class HistoryItem {
  final dynamic data;
  final DateTime date;
  final String type; // 'Tugas' atau 'Transaksi'

  HistoryItem({required this.data, required this.date, required this.type});
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'Semua'; // Semua, Tugas, Transaksi

  Future<void> _downloadPdf(
      List<HistoryItem> items, NumberFormat currencyFormatter) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Text('Riwayat Aktivitas',
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.Text(
                'Dicetak: ${DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.SizedBox(height: 8),
            ...items.map((item) {
              if (item.type == 'Tugas') {
                final task = item.data as Task;
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 60,
                        child: pw.Text(
                          DateFormat('d MMM').format(item.date),
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Container(
                        width: 70,
                        child: pw.Text('TUGAS',
                            style: pw.TextStyle(
                                fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(task.name,
                                style: pw.TextStyle(
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold)),
                            pw.Text(
                                '${task.course ?? 'Tanpa Mata Kuliah'} • ${task.status}',
                                style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                final trx = item.data as Transaction;
                final isIncome = trx.type == 'Pemasukan';
                final isTransfer = trx.type == 'Transfer';
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 60,
                        child: pw.Text(
                          DateFormat('d MMM').format(item.date),
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Container(
                        width: 70,
                        child: pw.Text('TRANSAKSI',
                            style: pw.TextStyle(
                                fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(trx.note,
                                style: pw.TextStyle(
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold)),
                            pw.Text(
                                isTransfer
                                    ? '${trx.walletType} ke ${trx.transferToWallet}'
                                    : '${trx.category} • ${trx.walletType}',
                                style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
                      pw.Text(
                        '${isTransfer ? '' : isIncome ? '+' : '-'}${currencyFormatter.format(trx.amount)}',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: isTransfer
                              ? PdfColors.blueGrey700
                              : isIncome
                                  ? PdfColors.green700
                                  : PdfColors.red700,
                        ),
                      ),
                    ],
                  ),
                );
              }
            }),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name:
          'riwayat_aktivitas_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  void _showDeleteHistoryDialog(HistoryItem item) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus riwayat ini?'),
        content: const Text('Data yang dihapus tidak dapat dikembalikan.'),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('BATAL'),
          ),
          ElevatedButton(
            onPressed: () {
              if (item.type == 'Tugas') {
                context.read<TaskProvider>().deleteTask(item.data.id);
              } else {
                context
                    .read<FinanceProvider>()
                    .deleteTransaction(item.data.id);
              }
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.expenseRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('HAPUS'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final financeProvider = context.watch<FinanceProvider>();
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? AppTheme.darkText : AppTheme.inkNavy;
    final borderColor = isDarkMode ? AppTheme.inkSky : AppTheme.inkNavy;

    // 1. Gabungkan Data
    List<HistoryItem> combinedHistory = [];

    for (var task in taskProvider.tasks) {
      combinedHistory
          .add(HistoryItem(data: task, date: task.deadline, type: 'Tugas'));
    }
    for (var trx in financeProvider.allTransactions) {
      combinedHistory
          .add(HistoryItem(data: trx, date: trx.date, type: 'Transaksi'));
    }

    // 2. Urutkan dari yang terbaru
    combinedHistory.sort((a, b) => b.date.compareTo(a.date));

    // 3. Filter berdasarkan Chip
    if (_selectedFilter == 'Tugas') {
      combinedHistory =
          combinedHistory.where((item) => item.type == 'Tugas').toList();
    } else if (_selectedFilter == 'Transaksi') {
      combinedHistory =
          combinedHistory.where((item) => item.type == 'Transaksi').toList();
    }

    // 4. Filter berdasarkan Search Query
    if (_searchQuery.isNotEmpty) {
      combinedHistory = combinedHistory.where((item) {
        if (item.type == 'Tugas') {
          return item.data.name
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              (item.data.course ?? '')
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase());
        } else {
          return item.data.note
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              item.data.category
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase());
        }
      }).toList();
    }

    return PaperBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Text(
                'RIWAYAT / SEMUA',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: textColor.withValues(alpha: 0.7),
                      letterSpacing: 1.2,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Riwayat Aktivitas',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontSize: 28),
                  ),
                  IconButton(
                    tooltip: 'Download PDF',
                    icon: Icon(Icons.picture_as_pdf_outlined, color: textColor),
                    onPressed: () =>
                        _downloadPdf(combinedHistory, currencyFormatter),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // SEARCH BAR
              TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Cari tugas atau transaksi...',
                  hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
                  prefixIcon: Icon(Icons.search, color: textColor),
                  filled: true,
                  fillColor: isDarkMode ? AppTheme.darkPanel : AppTheme.panelBg,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderColor, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderColor, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // FILTER CHIPS
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Semua', 'Tugas', 'Transaksi'].map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(filter,
                            style: TextStyle(
                              fontFamily: 'KodeMono',
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? (isDarkMode
                                      ? AppTheme.darkBg
                                      : AppTheme.paperBg)
                                  : textColor,
                            )),
                        selected: isSelected,
                        selectedColor: borderColor,
                        backgroundColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: borderColor, width: 1.5),
                        ),
                        onSelected: (selected) {
                          setState(() => _selectedFilter = filter);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // LIST RIWAYAT
              Expanded(
                child: combinedHistory.isEmpty
                    ? Center(
                        child: Text('Tidak ada riwayat ditemukan.',
                            style: TextStyle(color: textColor)))
                    : ListView.separated(
                        itemCount: combinedHistory.length,
                        separatorBuilder: (context, index) => Divider(
                          color: borderColor.withValues(alpha: 0.3),
                          height: 24,
                          thickness: 1,
                        ),
                        itemBuilder: (context, index) {
                          final item = combinedHistory[index];

                          if (item.type == 'Tugas') {
                            // Tampilan Item Tugas
                            return Row(
                              children: [
                                Icon(Icons.check_box_outlined,
                                    color: textColor, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item.data.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium),
                                      const SizedBox(height: 4),
                                      Text('Tugas / ${item.data.status}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                  color: textColor.withValues(
                                                      alpha: 0.6))),
                                    ],
                                  ),
                                ),
                                Text(DateFormat('d MMM').format(item.date),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(fontSize: 12)),
                                IconButton(
                                  tooltip: 'Hapus riwayat',
                                  icon: const Icon(Icons.delete_outline),
                                  color: AppTheme.expenseRed,
                                  onPressed: () =>
                                      _showDeleteHistoryDialog(item),
                                ),
                              ],
                            );
                          } else {
                            // Tampilan Item Transaksi
                            final transaction = item.data as Transaction;
                            final isIncome = transaction.type == 'Pemasukan';
                            final isTransfer = transaction.type == 'Transfer';
                            return Row(
                              children: [
                                Icon(
                                    isTransfer
                                        ? Icons.swap_horiz
                                        : Icons.payments_outlined,
                                    color: isTransfer
                                        ? textColor
                                        : isIncome
                                            ? AppTheme.incomeGreen
                                            : AppTheme.expenseRed,
                                    size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(transaction.note,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium),
                                      const SizedBox(height: 4),
                                      Text(
                                          '${isTransfer ? '${transaction.walletType} ke ${transaction.transferToWallet}' : transaction.category} / ${DateFormat('d MMM').format(item.date)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                  color: textColor.withValues(
                                                      alpha: 0.6))),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Hapus riwayat',
                                  icon: const Icon(Icons.delete_outline),
                                  color: AppTheme.expenseRed,
                                  onPressed: () =>
                                      _showDeleteHistoryDialog(item),
                                ),
                                Text(
                                  '${isTransfer ? '' : isIncome ? '+' : '-'}${currencyFormatter.format(transaction.amount)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                          color: isTransfer
                                              ? textColor
                                              : isIncome
                                                  ? AppTheme.incomeGreen
                                                  : AppTheme.expenseRed),
                                ),
                              ],
                            );
                          }
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
