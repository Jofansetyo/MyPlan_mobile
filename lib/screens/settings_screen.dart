import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';
import '../providers/finance_provider.dart';
import '../widgets/paper_background.dart';
import '../utils/currency_formatter.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final financeProvider = context.watch<FinanceProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.darkText : AppTheme.inkNavy;
    final borderColor = isDark ? AppTheme.inkSky : AppTheme.inkNavy;
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return PaperBackground(
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: textColor),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('Pengaturan',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontSize: 24)),
          ),
          body: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ====== KARTU PROFIL ======
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: AppTheme.inkSky,
                              backgroundImage: appProvider.avatarPath != null
                                  ? FileImage(File(appProvider.avatarPath!))
                                  : null,
                              child: appProvider.avatarPath == null
                                  ? Text(
                                      appProvider.userName.isNotEmpty
                                          ? appProvider.userName[0]
                                              .toUpperCase()
                                          : 'P',
                                      style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(appProvider.userName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(fontSize: 18)),
                                  const SizedBox(height: 2),
                                  Text(
                                      '${appProvider.age} tahun • ${appProvider.occupation}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                              color: textColor.withValues(
                                                  alpha: 0.7),
                                              fontSize: 12)),
                                  Text(appProvider.city,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                              color: textColor.withValues(
                                                  alpha: 0.7),
                                              fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const EditProfileScreen()));
                            },
                            child: const Text('UBAH PROFIL'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ====== BATAS PENGELUARAN (BARU) ======
                Text('BATAS PENGELUARAN',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: textColor)),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.savings_outlined,
                            color: AppTheme.inkSky, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Batas Bulanan',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          color: textColor.withValues(
                                              alpha: 0.7))),
                              const SizedBox(height: 2),
                              Text(
                                currencyFormatter
                                    .format(financeProvider.budgetLimit),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                        fontSize: 18,
                                        color: textColor,
                                        fontFamily: 'KodeMono'),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.edit_outlined, color: textColor),
                          onPressed: () => _showBudgetDialog(
                              context, financeProvider, currencyFormatter),
                          tooltip: 'Ubah',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ====== SALDO AWAL ======
                Text('SALDO AWAL DOMPET',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: textColor)),
                const SizedBox(height: 4),
                Text(
                  'Saldo sebelum mulai mencatat di aplikasi ini.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: textColor.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      _walletBalanceRow(
                        context,
                        financeProvider,
                        currencyFormatter,
                        textColor,
                        wallet: 'Cash',
                        icon: Icons.payments_outlined,
                        amount: financeProvider.initialBalanceCash,
                      ),
                      Divider(
                          color: borderColor.withValues(alpha: 0.3), height: 1),
                      _walletBalanceRow(
                        context,
                        financeProvider,
                        currencyFormatter,
                        textColor,
                        wallet: 'E-Wallet',
                        icon: Icons.account_balance_wallet_outlined,
                        amount: financeProvider.initialBalanceEWallet,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ====== TEMA ======
                Text('TAMPILAN / MODE',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: textColor)),
                const SizedBox(height: 12),
                Row(children: [
                  _buildThemeBtn(context, appProvider, 'SIANG', ThemeMode.light,
                      Icons.light_mode),
                  const SizedBox(width: 8),
                  _buildThemeBtn(context, appProvider, 'MALAM', ThemeMode.dark,
                      Icons.dark_mode),
                  const SizedBox(width: 8),
                  _buildThemeBtn(context, appProvider, 'SISTEM',
                      ThemeMode.system, Icons.settings_suggest),
                ]),
                const SizedBox(height: 24),

                // ====== LATAR BELAKANG ======
                Text('TAMPILAN / LATAR BELAKANG',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: textColor)),
                const SizedBox(height: 12),
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor, width: 1.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildBackgroundPreview(context, appProvider, isDark),
                ),
                const SizedBox(height: 12),
                Text('Warna Solid',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: textColor.withValues(alpha: 0.7))),
                const SizedBox(height: 8),
                Row(children: [
                  _buildColorBox(context, appProvider, const Color(0xFFE4E4E4)),
                  const SizedBox(width: 12),
                  _buildColorBox(context, appProvider, const Color(0xFFC4D8E4)),
                  const SizedBox(width: 12),
                  _buildColorBox(context, appProvider, const Color(0xFF559FD1)),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(context),
                      icon: const Icon(Icons.image_outlined, size: 18),
                      label: const Text('GAMBAR'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickVideo(context),
                      icon: const Icon(Icons.videocam_outlined, size: 18),
                      label: const Text('VIDEO MP4'),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => appProvider.resetBg(),
                    child: const Text('BAWAAN'),
                  ),
                ),
                const SizedBox(height: 24),

                // ====== NOTIFIKASI ======
                Text('NOTIFIKASI',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: textColor)),
                const SizedBox(height: 12),
                Card(
                  child: Column(children: [
                    SwitchListTile(
                      title: Text('Pengingat deadline',
                          style: Theme.of(context).textTheme.bodyLarge),
                      value: appProvider.deadlineReminder,
                      thumbColor: WidgetStateProperty.resolveWith<Color?>(
                        (states) => states.contains(WidgetState.selected)
                            ? AppTheme.inkSky
                            : null,
                      ),
                      trackColor: WidgetStateProperty.resolveWith<Color?>(
                        (states) => states.contains(WidgetState.selected)
                            ? AppTheme.inkSky.withValues(alpha: 0.5)
                            : null,
                      ),
                      onChanged: (v) => appProvider.toggleDeadlineReminder(v),
                    ),
                    Divider(
                        color: borderColor.withValues(alpha: 0.3), height: 1),
                    SwitchListTile(
                      title: Text('Peringatan batas uang',
                          style: Theme.of(context).textTheme.bodyLarge),
                      value: appProvider.spendingWarning,
                      thumbColor: WidgetStateProperty.resolveWith<Color?>(
                        (states) => states.contains(WidgetState.selected)
                            ? AppTheme.inkSky
                            : null,
                      ),
                      trackColor: WidgetStateProperty.resolveWith<Color?>(
                        (states) => states.contains(WidgetState.selected)
                            ? AppTheme.inkSky.withValues(alpha: 0.5)
                            : null,
                      ),
                      onChanged: (v) => appProvider.toggleSpendingWarning(v),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBudgetDialog(
      BuildContext context, FinanceProvider fp, NumberFormat formatter) {
    final controller = TextEditingController(
        text: NumberFormat('#,###', 'id_ID').format(fp.budgetLimit.toInt()));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.darkText : AppTheme.inkNavy;

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
        title: Text('Batas Pengeluaran',
            style: Theme.of(context).textTheme.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Atur batas pengeluaran bulanan:',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              style: TextStyle(
                  fontFamily: 'KodeMono',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor),
              decoration: InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: TextStyle(
                    fontFamily: 'KodeMono', fontSize: 18, color: textColor),
                hintText: '1.000.000',
                filled: true,
                fillColor: isDark ? AppTheme.darkBg : AppTheme.paperBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                      color: isDark ? AppTheme.inkSky : AppTheme.inkNavy,
                      width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                      color: isDark ? AppTheme.inkSky : AppTheme.inkNavy,
                      width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Contoh: ketik 1500000 → Rp 1.500.000',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 11, color: textColor.withValues(alpha: 0.6))),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('BATAL'),
          ),
          ElevatedButton(
            onPressed: () {
              final raw = controller.text.replaceAll(RegExp(r'[^0-9]'), '');
              final value = double.tryParse(raw) ?? 0;
              if (value > 0) {
                fp.setBudgetLimit(value);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Batas pengeluaran diubah ke ${formatter.format(value)}'),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Masukkan angka yang valid'),
                    backgroundColor: AppTheme.expenseRed,
                  ),
                );
              }
            },
            child: const Text('SIMPAN'),
          ),
        ],
      ),
    );
  }

  Widget _walletBalanceRow(
    BuildContext context,
    FinanceProvider fp,
    NumberFormat formatter,
    Color textColor, {
    required String wallet,
    required IconData icon,
    required double amount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.inkSky, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(wallet,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: textColor.withValues(alpha: 0.7))),
                const SizedBox(height: 2),
                Text(
                  formatter.format(amount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 16, color: textColor, fontFamily: 'KodeMono'),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, color: textColor),
            onPressed: () =>
                _showInitialBalanceDialog(context, fp, formatter, wallet),
            tooltip: 'Ubah',
          ),
        ],
      ),
    );
  }

  void _showInitialBalanceDialog(
    BuildContext context,
    FinanceProvider fp,
    NumberFormat formatter,
    String wallet,
  ) {
    final currentAmount =
        wallet == 'Cash' ? fp.initialBalanceCash : fp.initialBalanceEWallet;
    final controller = TextEditingController(
      text: currentAmount > 0 ? currentAmount.toInt().toString() : '',
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.darkText : AppTheme.inkNavy;

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
        title: Text('Saldo Awal $wallet',
            style: Theme.of(context).textTheme.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jumlah uang di $wallet sebelum mulai mencatat.',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              style: TextStyle(
                  fontFamily: 'KodeMono',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor),
              decoration: InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: TextStyle(
                    fontFamily: 'KodeMono', fontSize: 18, color: textColor),
                hintText: '0',
                filled: true,
                fillColor: isDark ? AppTheme.darkBg : AppTheme.paperBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                      color: isDark ? AppTheme.inkSky : AppTheme.inkNavy,
                      width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                      color: isDark ? AppTheme.inkSky : AppTheme.inkNavy,
                      width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('BATAL'),
          ),
          ElevatedButton(
            onPressed: () {
              final raw = controller.text.replaceAll(RegExp(r'[^0-9]'), '');
              final value = double.tryParse(raw) ?? 0;
              fp.setInitialBalance(wallet, value);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Saldo awal $wallet diubah ke ${formatter.format(value)}'),
                ),
              );
            },
            child: const Text('SIMPAN'),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundPreview(
      BuildContext context, AppProvider p, bool isDark) {
    if (p.bgType == 'image' && p.bgImagePath != null) {
      final file = File(p.bgImagePath!);
      return Image.file(
        file,
        key: ValueKey(p.bgImagePath),
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, error, __) {
          return Container(
            color: isDark ? AppTheme.darkBg : p.bgColor,
            child: Center(
              child: Text('Gagal memuat',
                  style: TextStyle(
                      color: isDark ? AppTheme.darkText : AppTheme.inkNavy)),
            ),
          );
        },
      );
    } else if (p.bgType == 'video' && p.bgVideoPath != null) {
      return Container(
        color: isDark ? AppTheme.darkBg : p.bgColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_circle_outline,
                  color: isDark ? AppTheme.darkText : AppTheme.inkNavy,
                  size: 40),
              Text('Video MP4 aktif',
                  style: TextStyle(
                      color: isDark ? AppTheme.darkText : AppTheme.inkNavy)),
            ],
          ),
        ),
      );
    }
    return Container(color: isDark ? AppTheme.darkBg : p.bgColor);
  }

  Widget _buildColorBox(BuildContext context, AppProvider p, Color color) {
    final isSelected =
        p.bgType == 'color' && p.bgColor.toARGB32() == color.toARGB32();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: InkWell(
        onTap: () => p.setBgColor(color),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? (isDark ? AppTheme.inkSky : AppTheme.inkNavy)
                  : Colors.grey.withValues(alpha: 0.4),
              width: isSelected ? 3 : 1.5,
            ),
          ),
          child: isSelected
              ? Icon(Icons.check,
                  color: color == Colors.white ? Colors.black : Colors.white)
              : null,
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;

      final dir = await getApplicationDocumentsDirectory();
      final ext = file.path.split('.').last;
      final newPath =
          '${dir.path}/bg_${DateTime.now().millisecondsSinceEpoch}.$ext';

      await File(file.path).copy(newPath);

      if (!context.mounted) return;
      context.read<AppProvider>().setBgImage(newPath);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Background berhasil diubah!')),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
        );
      }
    }
  }

  Future<void> _pickVideo(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickVideo(source: ImageSource.gallery);
      if (file == null) return;

      final dir = await getApplicationDocumentsDirectory();
      final ext = file.path.split('.').last;
      final newPath =
          '${dir.path}/bgv_${DateTime.now().millisecondsSinceEpoch}.$ext';

      await File(file.path).copy(newPath);

      if (!context.mounted) return;
      context.read<AppProvider>().setBgVideo(newPath);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Background video berhasil diubah!')),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
        );
      }
    }
  }

  Widget _buildThemeBtn(BuildContext context, AppProvider p, String label,
      ThemeMode mode, IconData icon) {
    final isSelected = p.themeMode == mode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.darkText : AppTheme.inkNavy;
    return Expanded(
      child: InkWell(
        onTap: () => p.setThemeMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppTheme.inkSky : AppTheme.inkNavy)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: isSelected
                    ? (isDark ? AppTheme.inkSky : AppTheme.inkNavy)
                    : (isDark ? AppTheme.darkPanel : AppTheme.paleSky),
                width: 1.5),
          ),
          child: Column(children: [
            Icon(icon,
                color: isSelected
                    ? (isDark ? AppTheme.darkBg : AppTheme.paperBg)
                    : textColor,
                size: 20),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontFamily: 'KodeMono',
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isSelected
                        ? (isDark ? AppTheme.darkBg : AppTheme.paperBg)
                        : textColor)),
          ]),
        ),
      ),
    );
  }
}
