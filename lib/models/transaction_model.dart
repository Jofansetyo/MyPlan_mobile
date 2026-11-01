class Transaction {
  final String id;
  final String type; // 'Pemasukan' atau 'Pengeluaran'
  final double amount;
  final String category;
  final DateTime date;
  final String note;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.date,
    required this.note,
  });
}
