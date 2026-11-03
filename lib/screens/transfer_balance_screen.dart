import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/transaction_model.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/paper_background.dart';

class TransferBalanceScreen extends StatefulWidget {
  const TransferBalanceScreen({super.key});

  @override
  State<TransferBalanceScreen> createState() => _TransferBalanceScreenState();
}

class _TransferBalanceScreenState extends State<TransferBalanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String _sourceWallet = 'Cash';

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<FinanceProvider>();
    final amount = double.parse(_amountController.text);
    final destinationWallet = _sourceWallet == 'Cash' ? 'E-Wallet' : 'Cash';

    try {
      provider.transferBalance(
        Transaction(
          id: const Uuid().v4(),
          type: 'Transfer',
          amount: amount,
          category: 'Transfer',
          date: DateTime.now(),
          note: 'Transfer $_sourceWallet ke $destinationWallet',
          walletType: _sourceWallet,
          transferToWallet: destinationWallet,
        ),
      );
      Navigator.pop(context);
    } on ArgumentError catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message?.toString() ?? 'Transfer gagal.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final financeProvider = context.watch<FinanceProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.darkText : AppTheme.inkNavy;
    final borderColor = isDark ? AppTheme.inkSky : AppTheme.inkNavy;
    final amountAvailable = _sourceWallet == 'Cash'
        ? financeProvider.balanceCash
        : financeProvider.balanceEWallet;
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return PaperBackground(
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Pindah Saldo'),
            backgroundColor: Colors.transparent,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DARI DOMPET',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _walletButton('Cash', isDark, borderColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _walletButton('E-Wallet', isDark, borderColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Saldo tersedia: ${formatter.format(amountAvailable)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: textColor.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 20),
                  Text('JUMLAH (RP)',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      hintText: '0',
                      filled: true,
                      fillColor: isDark ? AppTheme.darkPanel : AppTheme.panelBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderColor, width: 1.5),
                      ),
                    ),
                    validator: (value) {
                      final amount = double.tryParse(value ?? '');
                      if (amount == null || amount <= 0) {
                        return 'Masukkan jumlah transfer yang valid.';
                      }
                      if (amount > amountAvailable) {
                        return 'Jumlah melebihi saldo yang tersedia.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ke: ${_sourceWallet == 'Cash' ? 'E-Wallet' : 'Cash'}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text('PINDAHKAN SALDO'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _walletButton(String wallet, bool isDark, Color borderColor) {
    final isSelected = _sourceWallet == wallet;
    return InkWell(
      onTap: () => setState(() => _sourceWallet = wallet),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppTheme.inkSky : AppTheme.inkNavy)
              : (isDark ? AppTheme.darkPanel : AppTheme.paleSky),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Text(
          wallet.toUpperCase(),
          style: TextStyle(
            fontFamily: 'KodeMono',
            fontWeight: FontWeight.bold,
            color: isSelected
                ? (isDark ? AppTheme.darkBg : AppTheme.paperBg)
                : (isDark ? AppTheme.darkText : AppTheme.inkNavy),
          ),
        ),
      ),
    );
  }
}
