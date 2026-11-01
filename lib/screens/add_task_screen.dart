import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../widgets/paper_background.dart';

class AddTaskScreen extends StatefulWidget {
  final Task? task; // Jika null, mode Tambah. Jika ada, mode Edit.

  const AddTaskScreen({super.key, this.task});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _courseController = TextEditingController();

  DateTime _assignedDate = DateTime.now();
  DateTime _deadlineDate = DateTime.now().add(const Duration(days: 7));

  String _selectedPriority = 'Rendah';
  String _selectedStatus = 'Belum';
  bool _reminder = true;

  final List<String> _statuses = ['Belum', 'Proses', 'Selesai'];

  @override
  void initState() {
    super.initState();
    // Jika mode Edit, isi form dengan data yang ada
    if (widget.task != null) {
      _nameController.text = widget.task!.name;
      _courseController.text = widget.task!.course ?? '';
      _assignedDate = widget.task!.assignedDate;
      _deadlineDate = widget.task!.deadline;
      _selectedPriority = widget.task!.priority;
      _selectedStatus = widget.task!.status;
      _reminder = widget.task!.reminder;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isAssignedDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isAssignedDate ? _assignedDate : _deadlineDate,
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
    if (picked != null) {
      setState(() {
        if (isAssignedDate) {
          _assignedDate = picked;
        } else {
          _deadlineDate = picked;
        }
      });
    }
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      if (_deadlineDate.isBefore(_assignedDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deadline tidak boleh sebelum tanggal diberikan!'),
            backgroundColor: AppTheme.expenseRed,
          ),
        );
        return;
      }

      final taskProvider = context.read<TaskProvider>();

      final newTask = Task(
        id: widget.task?.id ?? const Uuid().v4(),
        name: _nameController.text,
        course: _courseController.text.isEmpty ? null : _courseController.text,
        assignedDate: _assignedDate,
        deadline: _deadlineDate,
        priority: _selectedPriority,
        status: _selectedStatus,
        reminder: _reminder,
      );

      if (widget.task == null) {
        taskProvider.addTask(newTask); // Mode Tambah
      } else {
        taskProvider.updateTask(newTask); // Mode Edit
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? AppTheme.darkText : AppTheme.inkNavy;
    final borderColor = isDarkMode ? AppTheme.inkSky : AppTheme.inkNavy;
    final isEditMode = widget.task != null;

    // Gaya Input Textfield
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: isDarkMode ? AppTheme.darkPanel : AppTheme.panelBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        borderSide: BorderSide(color: borderColor, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.expenseRed, width: 1.5),
      ),
      hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
      labelStyle: TextStyle(color: textColor.withValues(alpha: 0.7)),
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
                  // KICKER & TITLE
                  Text(
                    isEditMode ? 'TUGAS / UBAH' : 'TUGAS / BARU',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: textColor.withValues(alpha: 0.7),
                          letterSpacing: 1.2,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isEditMode ? 'Ubah Tugas' : 'Tambah Tugas',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 24),

                  // INPUT NAMA TUGAS
                  Text('NAMA TUGAS',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: textColor),
                    decoration: inputDecoration.copyWith(
                        hintText: 'Misal: Laporan Akhir'),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Nama tugas wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // INPUT MATA KULIAH (OPSIONAL)
                  Text('MATA KULIAH (OPSIONAL)',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _courseController,
                    style: TextStyle(color: textColor),
                    decoration: inputDecoration.copyWith(
                        hintText: 'Misal: Pemrograman Bergerak'),
                  ),
                  const SizedBox(height: 20),

                  // INPUT TANGGAL (DIBERIKAN & DEADLINE)
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DIBERIKAN',
                                style: Theme.of(context).textTheme.labelLarge),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => _pickDate(true),
                              child: InputDecorator(
                                decoration: inputDecoration.copyWith(
                                  suffixIcon: Icon(
                                      Icons.calendar_today_outlined,
                                      color: textColor,
                                      size: 20),
                                ),
                                child: Text(
                                  DateFormat('dd/MM/yyyy')
                                      .format(_assignedDate),
                                  style: TextStyle(
                                      fontFamily: 'KodeMono',
                                      fontSize: 14,
                                      color: textColor),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DEADLINE',
                                style: Theme.of(context).textTheme.labelLarge),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => _pickDate(false),
                              child: InputDecorator(
                                decoration: inputDecoration.copyWith(
                                  suffixIcon: Icon(
                                      Icons.calendar_today_outlined,
                                      color: textColor,
                                      size: 20),
                                ),
                                child: Text(
                                  DateFormat('dd/MM/yyyy')
                                      .format(_deadlineDate),
                                  style: TextStyle(
                                      fontFamily: 'KodeMono',
                                      fontSize: 14,
                                      color: textColor),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // PRIORITAS
                  Text('PRIORITAS',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildPriorityButton(
                          'Rendah', AppTheme.priorityLow, isDarkMode),
                      const SizedBox(width: 8),
                      _buildPriorityButton(
                          'Sedang', AppTheme.priorityMed, isDarkMode),
                      const SizedBox(width: 8),
                      _buildPriorityButton(
                          'Tinggi', AppTheme.priorityHigh, isDarkMode),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // STATUS
                  Text('STATUS', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedStatus,
                    decoration: inputDecoration,
                    style: TextStyle(
                        fontFamily: 'FiraSans', fontSize: 16, color: textColor),
                    dropdownColor:
                        isDarkMode ? AppTheme.darkPanel : AppTheme.panelBg,
                    icon: Icon(Icons.arrow_drop_down, color: textColor),
                    items: _statuses.map((String status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedStatus = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // REMINDER TOGGLE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ingatkan sebelum deadline',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      // Checkbox kustom (kotak) sesuai desain screenprint
                      InkWell(
                        onTap: () => setState(() => _reminder = !_reminder),
                        child: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _reminder
                                  ? AppTheme.inkSky
                                  : (isDarkMode
                                      ? AppTheme.darkPanel
                                      : AppTheme.panelBg),
                              border: Border.all(
                                  color: isDarkMode
                                      ? AppTheme.inkSky
                                      : AppTheme.inkNavy,
                                  width: 2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: _reminder
                                ? const Icon(Icons.check,
                                    size: 18, color: Colors.white)
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // TOMBOL AKSI
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('BATAL'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveTask,
                          child: const Text('SIMPAN'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget bantuan untuk Tombol Prioritas
  Widget _buildPriorityButton(String label, Color color, bool isDarkMode) {
    final isSelected = _selectedPriority == label;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedPriority = label),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            // Jika dipilih: background navy/dark, border warna prioritas
            // Jika tidak: background transparan/pale, border abu-abu
            color: isSelected
                ? (isDarkMode ? AppTheme.inkSky : AppTheme.inkNavy)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? color
                  : (isDarkMode ? AppTheme.darkPanel : AppTheme.paleSky),
              width: isSelected ? 3 : 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'KodeMono',
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isSelected
                  ? (isDarkMode ? AppTheme.darkBg : AppTheme.paperBg)
                  : (isDarkMode ? AppTheme.darkText : AppTheme.inkNavy),
            ),
          ),
        ),
      ),
    );
  }
}
