import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class PaperBackground extends StatelessWidget {
  final Widget child;
  const PaperBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget background;

    if (appProvider.bgType == 'video' && appProvider.bgVideoPath != null) {
      background = _VideoBackground(
        key: ValueKey(appProvider.bgVideoPath),
        videoPath: appProvider.bgVideoPath!,
        fallbackColor: isDark ? AppTheme.darkBg : AppTheme.paperBg,
      );
    } else if (appProvider.bgType == 'image' &&
        appProvider.bgImagePath != null) {
      final imageFile = File(appProvider.bgImagePath!);

      background = Image.file(
        imageFile,
        key: ValueKey(appProvider.bgImagePath),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stack) {
          return Container(
            color: isDark ? AppTheme.darkBg : AppTheme.paperBg,
          );
        },
      );
    } else {
      background = Container(
        color: isDark ? AppTheme.darkBg : appProvider.bgColor,
      );
    }

    return Stack(
      children: [
        Positioned.fill(child: background),
        // Overlay tipis (dikurangi dari 0.45 → 0.30 agar gambar lebih jelas)
        if (appProvider.bgType != 'color')
          Positioned.fill(
            child: Container(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.50)
                  : Colors.white.withValues(alpha: 0.30),
            ),
          ),
        Positioned.fill(child: child),
      ],
    );
  }
}

// Widget internal untuk video background
class _VideoBackground extends StatefulWidget {
  final String videoPath;
  final Color fallbackColor;
  const _VideoBackground({
    super.key,
    required this.videoPath,
    required this.fallbackColor,
  });

  @override
  State<_VideoBackground> createState() => _VideoBackgroundState();
}

class _VideoBackgroundState extends State<_VideoBackground> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final controller = VideoPlayerController.file(File(widget.videoPath));
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (mounted) setState(() => _controller = controller);
    } catch (e) {
      // video gagal dimuat, fallback ke warna solid
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Container(color: widget.fallbackColor);
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }
}
