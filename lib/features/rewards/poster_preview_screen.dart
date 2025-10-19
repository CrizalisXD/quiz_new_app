import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

class PosterPreviewScreen extends StatefulWidget {
  final String assetPath;
  const PosterPreviewScreen({super.key, required this.assetPath});

  static Route route(String assetPath) => PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black54,
        pageBuilder: (_, __, ___) => PosterPreviewScreen(assetPath: assetPath),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      );

  @override
  State<PosterPreviewScreen> createState() => _PosterPreviewScreenState();
}

class _PosterPreviewScreenState extends State<PosterPreviewScreen> {
  double? _ratio; // width / height

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ratio == null) {
      final provider = AssetImage(widget.assetPath);
      final stream = provider.resolve(createLocalImageConfiguration(context));
      ImageStreamListener? listener;
      listener = ImageStreamListener((info, _) {
        final w = info.image.width.toDouble();
        final h = info.image.height.toDouble();
        setState(() => _ratio = (h == 0 ? 16 / 9 : w / h));
        stream.removeListener(listener!);
      }, onError: (e, st) {
        setState(() => _ratio = 16 / 9);
        stream.removeListener(listener!);
      });
      stream.addListener(listener);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxW = 360.0;
    final maxH = 640.0;
    final margin = 16.0;
    final hasRatio = _ratio != null;

    // Рассчитаем желаемые размеры под изображение без лишних пустот
    double dialogW = MediaQuery.of(context).size.width - margin * 2;
    dialogW = dialogW.clamp(240.0, maxW);
    double dialogH;
    if (hasRatio) {
      final imageH = dialogW / _ratio!; // h = w / (w/h)
      // Toolbar высотой ~56
      dialogH = (56 + imageH).clamp(200.0, maxH);
    } else {
      dialogH = 240.0; // временно пока грузится размер
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          width: dialogW,
          height: dialogH,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(blurRadius: 20, color: Colors.black26)],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Toolbar
              Row(
                children: [
                  IconButton(
                    tooltip: 'Поделиться',
                    onPressed: () => Share.shareXFiles([XFile(widget.assetPath)]),
                    icon: const Icon(Icons.share_outlined),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Закрыть',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Expanded(
                child: hasRatio
                    ? InteractiveViewer(
                        minScale: 0.9,
                        maxScale: 4,
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: _ratio!,
                            child: Image.asset(
                              widget.assetPath,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Center(child: Text('Не удалось открыть постер')),
                            ),
                          ),
                        ),
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}