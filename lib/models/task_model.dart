class Task {
  final String id;
  final String name;
  final String? course;
  final DateTime assignedDate;
  final DateTime deadline;
  final String priority; // 'Rendah', 'Sedang', 'Tinggi'
  final String status; // 'Belum', 'Proses', 'Selesai'
  final bool reminder;

  Task({
    required this.id,
    required this.name,
    this.course,
    required this.assignedDate,
    required this.deadline,
    required this.priority,
    required this.status,
    required this.reminder,
  });
}
