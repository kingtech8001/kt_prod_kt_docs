import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';

class ImageLightboxDialog extends StatefulWidget {
  final String title;
  final String? imageUrl;
  final Uint8List? imageBytes;
  final VoidCallback? onDownload;

  const ImageLightboxDialog({
    super.key,
    required this.title,
    this.imageUrl,
    this.imageBytes,
    this.onDownload,
  });

  static void show({
    required String title,
    String? imageUrl,
    Uint8List? imageBytes,
    VoidCallback? onDownload,
  }) {
    Get.dialog(
      ImageLightboxDialog(
        title: title,
        imageUrl: imageUrl,
        imageBytes: imageBytes,
        onDownload: onDownload,
      ),
      barrierColor: Colors.black87,
    );
  }

  @override
  State<ImageLightboxDialog> createState() => _ImageLightboxDialogState();
}

class _ImageLightboxDialogState extends State<ImageLightboxDialog> {
  int _quarterTurns = 0;

  void _rotateClockwise() {
    setState(() {
      _quarterTurns = (_quarterTurns + 1) % 4;
    });
  }

  void _rotateCounterClockwise() {
    setState(() {
      _quarterTurns = (_quarterTurns - 1 + 4) % 4;
    });
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider imageProvider;
    if (widget.imageBytes != null) {
      imageProvider = MemoryImage(widget.imageBytes!);
    } else if (widget.imageUrl != null) {
      imageProvider = NetworkImage(widget.imageUrl!);
    } else {
      return const SizedBox.shrink();
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Main Image View
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              height: MediaQuery.of(context).size.height * 0.85,
              child: RotatedBox(
                quarterTurns: _quarterTurns,
                child: PhotoView(
                  imageProvider: imageProvider,
                  backgroundDecoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                  ),
                  minScale: PhotoViewComputedScale.contained * 0.8,
                  maxScale: PhotoViewComputedScale.covered * 3.0,
                  loadingBuilder: (context, event) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),

          // Top Action Controls Bar
          Positioned(
            top: 20,
            left: 30,
            right: 30,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.rotate_left, color: Colors.white),
                    tooltip: 'Rotate Left',
                    onPressed: _rotateCounterClockwise,
                  ),
                  IconButton(
                    icon: const Icon(Icons.rotate_right, color: Colors.white),
                    tooltip: 'Rotate Right',
                    onPressed: _rotateClockwise,
                  ),
                  if (widget.onDownload != null)
                    IconButton(
                      icon: const Icon(Icons.download, color: Colors.white),
                      tooltip: 'Download File',
                      onPressed: widget.onDownload,
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'Close (Esc)',
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
