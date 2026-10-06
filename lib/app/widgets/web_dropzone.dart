import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:kt_prod_kt_docs/core/utils/file_compressor.dart';
import 'package:kt_prod_kt_docs/core/utils/platform_file_compat.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';

import 'package:get/get.dart';

/// A concrete [PlatformFile] implementation wrapping drag-and-dropped files.
base class DroppedPlatformFile extends PlatformFile {
  @override
  final String name;
  final Uint8List _bytes;
  final int _size;
  final Uri _uri;

  DroppedPlatformFile({
    required this.name,
    required Uint8List bytes,
    int? size,
    Uri? uri,
  })  : _bytes = bytes,
        _size = size ?? bytes.lengthInBytes,
        _uri = uri ?? Uri.dataFromBytes(bytes);

  @override
  Uri get uri => _uri;

  @override
  XFile get xFile => XFile.fromData(_bytes, name: name);

  @override
  int? lengthSync() => _size;

  @override
  Future<int?> length() async => _size;

  @override
  Future<Uint8List> readAsBytes() async => _bytes;

  @override
  Stream<Uint8List> readAsByteStream() => Stream.value(_bytes);
}

class WebDropzone extends StatelessWidget {
  final ValueChanged<PlatformFile> onFileSelected;
  final PlatformFile? currentFile;

  WebDropzone({
    super.key,
    required this.onFileSelected,
    this.currentFile,
  });

  final RxBool _isDragging = false.obs;

  Future<void> _pickFile() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'docx', 'xlsx'],
    );

    if (files.isNotEmpty) {
      final picked = files.first;
      // Pre-cache bytes for synchronous access in upload controller & preview
      await picked.loadBytes();
      onFileSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (detail) async {
        if (detail.files.isNotEmpty) {
          final file = detail.files.first;
          final bytes = await file.readAsBytes();
          final platformFile = DroppedPlatformFile(
            name: file.name,
            size: bytes.lengthInBytes,
            bytes: bytes,
            uri: file.path.isNotEmpty ? Uri.tryParse(file.path) : null,
          );
          platformFile.bytes = bytes;
          onFileSelected(platformFile);
        }
      },
      onDragEntered: (_) => _isDragging.value = true,
      onDragExited: (_) => _isDragging.value = false,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _pickFile,
          child: Obx(
            () => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              decoration: BoxDecoration(
                color: _isDragging.value
                    ? AppColors.primarySurface
                    : (currentFile != null
                        ? AppColors.successLight.withValues(alpha: 0.3)
                        : AppColors.background),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isDragging.value
                      ? AppColors.primary
                      : (currentFile != null
                          ? AppColors.success
                          : AppColors.border),
                  width: _isDragging.value || currentFile != null ? 2 : 1.5,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: currentFile != null
                            ? AppColors.success.withValues(alpha: 0.12)
                            : AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        currentFile != null
                            ? Icons.check_circle_outline
                            : Icons.cloud_upload_outlined,
                        size: 36,
                        color: currentFile != null
                            ? AppColors.success
                            : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (currentFile != null) ...[
                      Text(
                        currentFile!.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${CompressionResult.formatFileSize(currentFile!.lengthSync() ?? 0)} • Ready to upload',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Click to replace with a different file',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Drag & Drop your document here, or browse',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Supports PDF, JPG, PNG, WEBP, DOCX up to 50MB',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
