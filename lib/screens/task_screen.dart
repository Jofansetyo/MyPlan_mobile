import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/task_provider.dart';
import '../models/task_model.dart';
import '../widgets/paper_background.dart';
import 'add_task_screen.dart'; // Tambahan Import untuk Form Tugas

class TaskScreen extends StatelessWidget {
  const TaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? AppTheme.darkText : AppTheme.inkNavy;
    final borderColor = isDarkMode ? AppTheme.inkSky : AppTheme.inkNavy;

    return PaperBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Text(
                'TUGAS / ${DateFormat('MMM', 'id_ID').format(DateTime.now()).toUpperCase()}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: textColor.withValues(alpha: 0.7),
                      letterSpacing: 1.2,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Daftar Tugas',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 24),

              // LIST TUGAS
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: taskProvider.tasks.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final task = taskProvider.tasks[index];
                  return _buildTaskCard(
                      context, task, isDarkMode, borderColor, textColor);
                },
              ),

              const SizedBox(height: 24),

              // TOMBOL TAMBAH TUGAS
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // PERBAIKAN: Navigasi ke AddTaskScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddTaskScreen(),
                      ),
                    );
                  },
                  child: const Text('+ TAMBAH TUGAS'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET KARTU TUGAS
  Widget _buildTaskCard(
    BuildContext context,
    Task task,
    bool isDarkMode,
    Color borderColor,
    Color textColor,
  ) {
    // Tentukan warna prioritas
    Color priorityColor;
    switch (task.priority) {
      case 'Tinggi':
        priorityColor = AppTheme.priorityHigh;
        break;
      case 'Sedang':
        priorityColor = AppTheme.priorityMed;
        break;
      default:
        priorityColor = AppTheme.priorityLow;
    }

    // Hitung sisa hari
    final daysLeft = task.deadline.difference(DateTime.now()).inDays;
    final isOverdue = daysLeft < 0;
    final daysLeftText = isOverdue ? 'TERLAMBAT' : 'SISA $daysLeft HARI';

    return Card(
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: priorityColor, width: 8),
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul & Mata Kuliah
            Text(
              task.name,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              task.course ?? 'Tanpa Mata Kuliah',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textColor.withValues(alpha: 0.8),
                  ),
            ),
            const SizedBox(height: 8),
            // Tanggal
            Text(
              'Diberi ${DateFormat('d MMM').format(task.assignedDate)} / Deadline ${DateFormat('d MMM').format(task.deadline)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textColor.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
            ),
            const SizedBox(height: 16),

            // Chip Sisa Hari & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: isOverdue ? AppTheme.expenseRed : borderColor),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    daysLeftText,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: 11,
                          color: isOverdue ? AppTheme.expenseRed : textColor,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppTheme.darkBg : AppTheme.paleSky,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Text(
                    task.status.toUpperCase(),
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: 12),

            // Tandai tugas selesai atau kembalikan ke status belum.
            Row(
              children: [
                Checkbox(
                  value: task.status == 'Selesai',
                  onChanged: (completed) {
                    if (completed != null) {
                      context
                          .read<TaskProvider>()
                          .toggleTaskCompletion(task, completed);
                    }
                  },
                  activeColor: AppTheme.inkSky,
                ),
                Expanded(
                  child: Text(
                    task.status == 'Selesai'
                        ? 'TUGAS SELESAI'
                        : 'TANDAI SELESAI',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Tombol Aksi (Ubah & Hapus)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // PERBAIKAN: Navigasi ke AddTaskScreen dengan mode Edit
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddTaskScreen(task: task),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('UBAH'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showDeleteDialog(context, task),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: AppTheme.expenseRed,
                      side: const BorderSide(
                          color: AppTheme.expenseRed, width: 1.5),
                      backgroundColor: Colors.transparent,
                    ),
                    child: const Text('HAPUS'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // DIALOG KONFIRMASI HAPUS
  void _showDeleteDialog(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.inkSky
                    : AppTheme.inkNavy,
                width: 1.5),
          ),
          title: Text(
            'Hapus tugas ini?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: Text(
            '${task.name} akan dihapus dan tidak bisa dikembalikan.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('BATAL'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<TaskProvider>().deleteTask(task.id);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.expenseRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('HAPUS'),
            ),
          ],
        );
      },
    );
  }
}
