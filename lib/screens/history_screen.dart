import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/task_provider.dart';
import '../providers/finance_provider.dart';
import '../widgets/paper_background.dart';

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
    for (var trx in financeProvider.transactions) {
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
          padding: const EdgeInsets.all(24.0),
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
              Text(
                'Riwayat Aktivitas',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontSize: 28),
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
                              ],
                            );
                          } else {
                            // Tampilan Item Transaksi
                            final isIncome = item.data.type == 'Pemasukan';
                            return Row(
                              children: [
                                Icon(Icons.payments_outlined,
                                    color: isIncome
                                        ? AppTheme.incomeGreen
                                        : AppTheme.expenseRed,
                                    size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item.data.note,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium),
                                      const SizedBox(height: 4),
                                      Text(
                                          '${item.data.category} / ${DateFormat('d MMM').format(item.date)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                  color: textColor.withValues(
                                                      alpha: 0.6))),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${isIncome ? '+' : '-'}${currencyFormatter.format(item.data.amount)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                          color: isIncome
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
