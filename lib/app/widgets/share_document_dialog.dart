import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';

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
    );
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: shareUrl));
    _copied.value = true;
    Get.snackbar(
      'Link Copied',
      'Secure document share link copied to clipboard',
      backgroundColor: AppColors.success,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(20),
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.share_outlined, color: AppColors.primary, size: 24),
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
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Share access to "$documentTitle". Anyone with this signed link can view the document for the designated expiration time.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
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
                  Obx(() => ElevatedButton.icon(
                        onPressed: _copyToClipboard,
                        icon: Icon(_copied.value ? Icons.check : Icons.copy, size: 16),
                        label: Text(_copied.value ? 'Copied' : 'Copy Link'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Get.back(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
