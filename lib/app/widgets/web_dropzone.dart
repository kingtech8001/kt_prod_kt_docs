import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';

class WebDropzone extends StatefulWidget {
  final ValueChanged<PlatformFile> onFileSelected;
  final PlatformFile? currentFile;

  const WebDropzone({
    super.key,
    required this.onFileSelected,
    this.currentFile,
  });

  @override
  State<WebDropzone> createState() => _WebDropzoneState();
}

class _WebDropzoneState extends State<WebDropzone> {
  bool _isDragging = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'docx', 'xlsx'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      widget.onFileSelected(result.files.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (detail) async {
        if (detail.files.isNotEmpty) {
          final file = detail.files.first;
          final bytes = await file.readAsBytes();
          final platformFile = PlatformFile(
            name: file.name,
            size: bytes.lengthInBytes,
            bytes: bytes,
          );
          widget.onFileSelected(platformFile);
        }
      },
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _pickFile,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            decoration: BoxDecoration(
              color: _isDragging
                  ? AppColors.primarySurface
                  : (widget.currentFile != null
                      ? AppColors.successLight.withValues(alpha: 0.3)
                      : AppColors.background),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isDragging
                    ? AppColors.primary
                    : (widget.currentFile != null
                        ? AppColors.success
                        : AppColors.border),
                width: _isDragging || widget.currentFile != null ? 2 : 1.5,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.currentFile != null
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.currentFile != null
                          ? Icons.check_circle_outline
                          : Icons.cloud_upload_outlined,
                      size: 36,
                      color: widget.currentFile != null
                          ? AppColors.success
                          : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (widget.currentFile != null) ...[
                    Text(
                      widget.currentFile!.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(widget.currentFile!.size / 1024).toStringAsFixed(1)} KB • Ready to upload',
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
    );
  }
}
