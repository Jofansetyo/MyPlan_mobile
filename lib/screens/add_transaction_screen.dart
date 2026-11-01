import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../models/transaction_model.dart';
import '../providers/finance_provider.dart';
import '../widgets/paper_background.dart';
import '../utils/currency_formatter.dart';

class AddTransactionScreen extends StatefulWidget {
  // PARAMETER OPSIONAL: Jika null = Tambah, Jika ada isi = Edit
  final Transaction? transaction;

  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isIncome = false;
  String _selectedCategory = 'Makan';
  DateTime _selectedDate = DateTime.now();

  final List<String> _categories = [
    'Makan',
    'Transportasi',
    'Belanja',
    'Hiburan',
    'Kesehatan',
    'Tagihan',
    'Gaji',
    'Lainnya'
  ];

  // Getter untuk cek mode
  bool get isEditMode => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    // Jika mode Edit, isi form dengan data yang ada
    if (widget.transaction != null) {
      final t = widget.transaction!;
      _isIncome = t.type == 'Pemasukan';
      _amountController.text = NumberFormat('#,###', 'id_ID').format(t.amount.toInt());
      _noteController.text = t.note == '-' ? '' : t.note;
      _selectedCategory =
          _categories.contains(t.category) ? t.category : 'Lainnya';
      _selectedDate = t.date;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).brightness == Brightness.dark
                ? const ColorScheme.dark(primary: AppTheme.inkSky)
                : const ColorScheme.light(primary: AppTheme.inkNavy),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _saveTransaction() {
    if (_formKey.currentState!.validate()) {
      final amountString =
          _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final amount = double.tryParse(amountString) ?? 0;

      final trx = Transaction(
        id: widget.transaction?.id ??
            const Uuid().v4(), // Pakai ID lama jika edit
        type: _isIncome ? 'Pemasukan' : 'Pengeluaran',
        amount: amount,
        category: _selectedCategory,
        date: _selectedDate,
        note: _noteController.text.isEmpty ? '-' : _noteController.text,
      );

      final provider = context.read<FinanceProvider>();

      if (isEditMode) {
        provider.updateTransaction(trx); // Mode Edit
      } else {
        provider.addTransaction(trx); // Mode Tambah
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? AppTheme.darkText : AppTheme.inkNavy;
    final borderColor = isDarkMode ? AppTheme.inkSky : AppTheme.inkNavy;

    final inputDeco = InputDecoration(
      filled: true,
      fillColor: isDarkMode ? AppTheme.darkPanel : AppTheme.panelBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor, width: 1.5)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor, width: 1.5)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor, width: 2.0)),
    );

    return PaperBackground(
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isEditMode ? 'KEUANGAN / UBAH' : 'KEUANGAN / BARU',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: textColor.withValues(alpha: 0.7))),
                  const SizedBox(height: 8),
                  Text(isEditMode ? 'Ubah Transaksi' : 'Tambah Transaksi',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontSize: 28)),
                  const SizedBox(height: 24),

                  // TOGGLE PENGELUARAN / PEMASUKAN
                  Row(children: [
                    Expanded(
                        child: _buildToggle(
                            'PENGELUARAN',
                            !_isIncome,
                            () => setState(() => _isIncome = false),
                            isDarkMode)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildToggle(
                            'PEMASUKAN',
                            _isIncome,
                            () => setState(() => _isIncome = true),
                            isDarkMode)),
                  ]),
                  const SizedBox(height: 24),

                  Text('JUMLAH (RP)',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                    style: TextStyle(
                        fontFamily: 'KodeMono',
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: textColor),
                    decoration: inputDeco.copyWith(
                      hintText: '0',
                      prefixText: 'Rp ',
                      prefixStyle: TextStyle(
                          fontFamily: 'KodeMono',
                          color: textColor,
                          fontSize: 20),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 20),

                  Text('KATEGORI',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: inputDeco,
                    style: TextStyle(
                        fontFamily: 'FiraSans', fontSize: 16, color: textColor),
                    dropdownColor:
                        isDarkMode ? AppTheme.darkPanel : AppTheme.panelBg,
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v!),
                  ),
                  const SizedBox(height: 20),

                  Text('TANGGAL',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: inputDeco.copyWith(
                          suffixIcon: Icon(Icons.calendar_today_outlined,
                              color: textColor)),
                      child: Text(
                          DateFormat('dd/MM/yyyy').format(_selectedDate),
                          style: TextStyle(
                              fontFamily: 'KodeMono', color: textColor)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text('CATATAN',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  TextFormField(
                      controller: _noteController,
                      style: TextStyle(color: textColor),
                      decoration:
                          inputDeco.copyWith(hintText: 'Misal: Makan siang')),
                  const SizedBox(height: 32),

                  Row(children: [
                    Expanded(
                        child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('BATAL'))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: ElevatedButton(
                            onPressed: _saveTransaction,
                            child: const Text('SIMPAN'))),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggle(
      String label, bool isSelected, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppTheme.inkSky : AppTheme.inkNavy)
              : (isDark ? AppTheme.darkPanel : AppTheme.paleSky),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: AppTheme.inkNavy.withValues(alpha: 0.3), width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
                fontFamily: 'KodeMono',
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isSelected
                    ? (isDark ? AppTheme.darkBg : AppTheme.paperBg)
                    : (isDark ? AppTheme.darkText : AppTheme.inkNavy))),
      ),
    );
  }
}
