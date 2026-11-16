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
  final bool isScanning;
  final double scanProgress;

  WebDropzone({
    super.key,
    required this.onFileSelected,
    this.currentFile,
    this.isScanning = false,
    this.scanProgress = 0.0,
  });

  final RxBool _isDragging = false.obs;
  final RxBool _isLoadingFile = false.obs;

  Future<void> _pickFile() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'docx', 'xlsx'],
      );

      if (files.isNotEmpty) {
        _isLoadingFile.value = true;
        final picked = files.first;
        // Pre-cache bytes for synchronous access in upload controller & preview
        await picked.loadBytes();
        onFileSelected(picked);
      }
    } finally {
      _isLoadingFile.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (detail) async {
        if (detail.files.isNotEmpty) {
          _isLoadingFile.value = true;
          try {
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
          } finally {
            _isLoadingFile.value = false;
          }
        }
      },
      onDragEntered: (_) => _isDragging.value = true,
      onDragExited: (_) => _isDragging.value = false,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _pickFile,
          child: Obx(
            () {
              final isDrag = _isDragging.value;
              final isLoading = _isLoadingFile.value;
              final hasFile = currentFile != null;
              final scanning = isScanning;

              Color bgColor;
              Color borderColor;
              double borderWidth;

              if (isDrag) {
                bgColor = AppColors.primarySurface;
                borderColor = AppColors.primary;
                borderWidth = 2.0;
              } else if (isLoading || scanning) {
                bgColor = AppColors.primarySurface;
                borderColor = AppColors.primary;
                borderWidth = 2.0;
              } else if (hasFile) {
                bgColor = AppColors.successLight.withValues(alpha: 0.3);
                borderColor = AppColors.success;
                borderWidth = 2.0;
              } else {
                bgColor = AppColors.background;
                borderColor = AppColors.border;
                borderWidth = 1.5;
              }

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: borderColor,
                    width: borderWidth,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLoading) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Loading selected file...',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Preparing file for instant scanning & upload',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ] else if (scanning && hasFile) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 44,
                                height: 44,
                                child: CircularProgressIndicator(
                                  value: scanProgress > 0 ? scanProgress : null,
                                  strokeWidth: 3.5,
                                  color: AppColors.primary,
                                  backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                                ),
                              ),
                              Text(
                                '${(scanProgress * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          currentFile!.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${CompressionResult.formatFileSize(currentFile!.lengthSync() ?? 0)} • Analyzing document...',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Extracting text, numbers & dates in background',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ] else if (hasFile) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            size: 36,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          currentFile!.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${CompressionResult.formatFileSize(currentFile!.lengthSync() ?? 0)} • Ready to upload',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
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
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cloud_upload_outlined,
                            size: 36,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
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
              );
            },
          ),
        ),
      ),
    );
  }
}
