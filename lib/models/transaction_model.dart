class Transaction {
  final String id;
  final String type; // 'Pemasukan', 'Pengeluaran', atau 'Transfer'
  final double amount;
  final String category;
  final DateTime date;
  final String note;
  final String walletType; // 'Cash' atau 'E-Wallet'
  final String? transferToWallet;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.date,
    required this.note,
    this.walletType = 'Cash',
    this.transferToWallet,
  });
}
