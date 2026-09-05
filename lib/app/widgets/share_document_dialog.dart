import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';

/// GetX-compliant interactive Share Document Dialog.
/// Uses responsive BoxConstraints, in-context copy confirmation without floating snackbars.
class ShareDocumentDialog extends StatelessWidget {
  final String documentTitle;
  final String shareUrl;

  ShareDocumentDialog({
    super.key,
    required this.documentTitle,
    required this.shareUrl,
  });

  final RxBool _copied = false.obs;

  static void show({
    required String documentTitle,
    required String shareUrl,
  }) {
    Get.dialog(
      ShareDocumentDialog(
        documentTitle: documentTitle,
        shareUrl: shareUrl,
      ),
      barrierDismissible: true,
    );
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: shareUrl));
    _copied.value = true;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      ),
      backgroundColor: AppColors.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.share_outlined,
                          color: AppColors.primary, size: 24),
                      SizedBox(width: 10),
                      Text(
                        'Share Document',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: AppColors.textSecondary,
                    splashRadius: 18,
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Text(
                'Share access to "$documentTitle". Anyone with this signed link can view the document for the designated expiration time.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              // Inline Copied Alert (Rule 3.B: In-context feedback inside modal)
              Obx(() {
                if (!_copied.value) return const SizedBox.shrink();
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                    border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded,
                          color: AppColors.successDark, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Secure share link copied to clipboard!',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.successDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // URL Display and Copy Button
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusSmall),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        shareUrl,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Obx(
                      () => ElevatedButton.icon(
                        onPressed: _copyToClipboard,
                        icon: Icon(
                            _copied.value ? Icons.check : Icons.copy,
                            size: 16),
                        label: Text(_copied.value ? 'Copied' : 'Copy Link'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _copied.value
                              ? AppColors.success
                              : AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
