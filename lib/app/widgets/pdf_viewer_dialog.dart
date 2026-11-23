import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/widgets/app_shimmer.dart';
import 'package:kt_prod_kt_docs/app/widgets/pdf_preview.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';

import 'package:kt_prod_kt_docs/app/controllers/pdf_preview_controller.dart';
import 'package:kt_prod_kt_docs/app/bindings/preview_binding.dart';

class PdfViewerDialog extends GetView<PdfPreviewController> {
  const PdfViewerDialog._({required this.tag});
  @override
  final String tag;
  static void show({
    required String title,
    String? signedPdfUrl,
    Uint8List? pdfBytes,
    String? fileName,
    String? filePath,
    VoidCallback? onDownload,
  }) {
    final tag = PreviewBinding.nextTag();
    PreviewBinding(
      tag: tag,
      pdf: true,
      title: title,
      url: signedPdfUrl,
      bytes: pdfBytes,
      fileName: fileName,
      filePath: filePath,
      onDownload: onDownload,
    ).dependencies();
    Get.find<PdfPreviewController>(
      tag: tag,
    ).present(PdfViewerDialog._(tag: tag), tag);
  }

  static void showBytes({
    required String title,
    required Uint8List bytes,
    String? fileName,
    VoidCallback? onDownload,
  }) {
    show(
      title: title,
      pdfBytes: bytes,
      fileName: fileName,
      onDownload: onDownload,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dialogWidth = (size.width - AppConstants.paddingMedium * 2).clamp(
      0.0,
      1140.0,
    );
    final dialogHeight = (size.height - AppConstants.paddingLarge * 2).clamp(
      0.0,
      920.0,
    );

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: AppConstants.paddingLarge,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      ),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        ),
        child: Column(
          children: [
            // 1. Top Header Toolbar
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppConstants.paddingSmall),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusSmall,
                      ),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf,
                      color: AppColors.error,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (controller.fileName != null &&
                            controller.fileName!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            controller.fileName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingSmall),
                  IconButton(
                    icon: const Icon(
                      Icons.download_outlined,
                      color: AppColors.primary,
                    ),
                    tooltip: 'Download PDF',
                    onPressed: controller.handleDownload,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                    ),
                    tooltip: 'Close preview',
                    onPressed: Get.back,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // 2. Main Viewer / Skeleton / Error Body
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const AppShimmer(child: DocumentPreviewSkeleton());
                }

                if (controller.errorMessage.value.isNotEmpty) {
                  return _buildErrorView();
                }

                if (controller.pdfBytes.value != null ||
                    controller.webPreviewUrl.value.isNotEmpty) {
                  return ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(AppConstants.radiusMedium),
                      bottomRight: Radius.circular(AppConstants.radiusMedium),
                    ),
                    child: PdfPreview(
                      bytes: controller.pdfBytes.value,
                      sourceUrl: controller.webPreviewUrl.value.isNotEmpty
                          ? controller.webPreviewUrl.value
                          : (controller.signedPdfUrl ?? ''),
                      onDocumentLoaded: () {
                        AppLogger.info(
                          'PDF_VIEWER',
                          'PDF document rendered successfully.',
                        );
                      },
                      onDocumentLoadFailed: (error) {
                        AppLogger.warning(
                          'PDF_VIEWER',
                          'PDF renderer warning: $error',
                        );
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingExtraLarge),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: AppConstants.paddingMedium),
              const Text(
                'Unable to Load PDF via API',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              Text(
                controller.errorMessage.value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppConstants.paddingLarge),
              Wrap(
                spacing: AppConstants.paddingSmall,
                runSpacing: AppConstants.paddingSmall,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: controller.loadPdfBytesViaApi,
                  ),
                  if (controller.pdfBytes.value != null ||
                      controller.onDownload != null ||
                      (controller.signedPdfUrl != null &&
                          controller.signedPdfUrl!.startsWith('http')))
                    OutlinedButton.icon(
                      icon: const Icon(Icons.download_outlined, size: 16),
                      label: const Text('Download'),
                      onPressed: controller.handleDownload,
                    ),
                  TextButton(onPressed: Get.back, child: const Text('Dismiss')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
