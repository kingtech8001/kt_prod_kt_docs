import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class PdfViewerDialog extends StatelessWidget {
  final String title;
  final String signedPdfUrl;
  final VoidCallback? onDownload;

  const PdfViewerDialog({
    super.key,
    required this.title,
    required this.signedPdfUrl,
    this.onDownload,
  });

  static void show({
    required String title,
    required String signedPdfUrl,
    VoidCallback? onDownload,
  }) {
    Get.dialog(
      PdfViewerDialog(
        title: title,
        signedPdfUrl: signedPdfUrl,
        onDownload: onDownload,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.75,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: AppColors.error, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Open in Browser Viewer'),
                      onPressed: () async {
                        final uri = Uri.parse(signedPdfUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    if (onDownload != null)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Download'),
                        onPressed: onDownload,
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 32),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.picture_as_pdf, size: 64, color: AppColors.primary),
                      const SizedBox(height: 16),
                      const Text(
                        'PDF Document Ready for Preview & Download',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Click below to open high-resolution vector PDF in an interactive browser tab.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.open_in_browser),
                        label: const Text('Open PDF Interactive Viewer'),
                        onPressed: () async {
                          final uri = Uri.parse(signedPdfUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
