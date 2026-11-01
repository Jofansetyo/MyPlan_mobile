import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';
import '../widgets/paper_background.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _occupationCtrl;
  late TextEditingController _cityCtrl;
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    final p = context.read<AppProvider>();
    _nameCtrl = TextEditingController(text: p.userName);
    _ageCtrl = TextEditingController(text: p.age == '-' ? '' : p.age);
    _occupationCtrl =
        TextEditingController(text: p.occupation == '-' ? '' : p.occupation);
    _cityCtrl = TextEditingController(text: p.city == '-' ? '' : p.city);
    _avatarPath = p.avatarPath;
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final newPath =
        '${dir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.${file.path.split('.').last}';
    await File(file.path).copy(newPath);

    setState(() => _avatarPath = newPath);
  }

  void _save() {
    context.read<AppProvider>().updateProfile(
          name: _nameCtrl.text.isEmpty ? 'Pengguna' : _nameCtrl.text,
          age: _ageCtrl.text.isEmpty ? '-' : _ageCtrl.text,
          occupation: _occupationCtrl.text.isEmpty ? '-' : _occupationCtrl.text,
          city: _cityCtrl.text.isEmpty ? '-' : _cityCtrl.text,
          avatarPath: _avatarPath,
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.darkText : AppTheme.inkNavy;
    final borderColor = isDark ? AppTheme.inkSky : AppTheme.inkNavy;

    final inputDeco = InputDecoration(
      filled: true,
      fillColor: isDark ? AppTheme.darkPanel : AppTheme.panelBg,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PENGATURAN / PROFIL',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: textColor.withValues(alpha: 0.7))),
                const SizedBox(height: 8),
                Text('Ubah Profil',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontSize: 28)),
                const SizedBox(height: 24),

                // AVATAR
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.inkSky,
                      backgroundImage: _avatarPath != null
                          ? FileImage(File(_avatarPath!))
                          : null,
                      child: _avatarPath == null
                          ? Text(
                              _nameCtrl.text.isNotEmpty
                                  ? _nameCtrl.text[0].toUpperCase()
                                  : 'P',
                              style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: _pickAvatar,
                      child: const Text('UBAH FOTO'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Text('NAMA', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                TextField(
                    controller: _nameCtrl,
                    style: TextStyle(color: textColor),
                    decoration: inputDeco.copyWith(hintText: 'Nama Anda')),

                const SizedBox(height: 16),
                Text('UMUR', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                TextField(
                    controller: _ageCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: textColor),
                    decoration: inputDeco.copyWith(hintText: 'Contoh: 22')),

                const SizedBox(height: 16),
                Text('PEKERJAAN',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                TextField(
                    controller: _occupationCtrl,
                    style: TextStyle(color: textColor),
                    decoration: inputDeco.copyWith(
                        hintText: 'Contoh: Desainer, Pelajar, Wirausaha')),

                const SizedBox(height: 16),
                Text('KOTA', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                TextField(
                    controller: _cityCtrl,
                    style: TextStyle(color: textColor),
                    decoration:
                        inputDeco.copyWith(hintText: 'Contoh: Jakarta')),

                const SizedBox(height: 32),

                Row(
                  children: [
                    Expanded(
                        child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('BATAL'))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: ElevatedButton(
                            onPressed: _save, child: const Text('SIMPAN'))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
