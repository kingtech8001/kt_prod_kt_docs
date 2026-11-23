import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/widgets/app_shimmer.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';
import 'package:photo_view/photo_view.dart';

import 'package:kt_prod_kt_docs/app/controllers/image_preview_controller.dart';
import 'package:kt_prod_kt_docs/app/bindings/preview_binding.dart';

class ImageLightboxDialog extends GetView<ImagePreviewController> {
  const ImageLightboxDialog._({required this.tag});
  @override
  final String tag;
  static void show({
    required String title,
    String? imageUrl,
    Uint8List? imageBytes,
    String? fileName,
    String? filePath,
    VoidCallback? onDownload,
  }) {
    final tag = PreviewBinding.nextTag();
    PreviewBinding(
      tag: tag,
      pdf: false,
      title: title,
      url: imageUrl,
      bytes: imageBytes,
      fileName: fileName,
      filePath: filePath,
      onDownload: onDownload,
    ).dependencies();
    Get.find<ImagePreviewController>(
      tag: tag,
    ).present(ImageLightboxDialog._(tag: tag), tag);
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
      backgroundColor: Colors.transparent,
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
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF0B1120),
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Image Viewer / Shimmer Skeleton / Error View
            Obx(() {
              if (controller.isLoading.value) {
                return const AppShimmer(child: DocumentPreviewSkeleton());
              }

              if (controller.errorMessage.value.isNotEmpty) {
                return _buildErrorView();
              }

              if (controller.loadedBytes.value != null) {
                return RotatedBox(
                  quarterTurns: controller.quarterTurns.value,
                  child: PhotoView(
                    imageProvider: MemoryImage(controller.loadedBytes.value!),
                    backgroundDecoration: const BoxDecoration(
                      color: Color(0xFF0B1120),
                    ),
                    minScale: PhotoViewComputedScale.contained * 0.8,
                    maxScale: PhotoViewComputedScale.covered * 3.5,
                    loadingBuilder: (context, event) =>
                        const AppShimmer(child: DocumentPreviewSkeleton()),
                  ),
                );
              }

              return const SizedBox.shrink();
            }),

            // 2. Top Floating Controls Bar
            Positioned(
              top: AppConstants.paddingMedium,
              left: AppConstants.paddingMedium,
              right: AppConstants.paddingMedium,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMedium,
                  vertical: AppConstants.paddingSmall,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusSmall,
                        ),
                      ),
                      child: const Icon(
                        Icons.image,
                        color: Colors.white,
                        size: 18,
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
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (controller.fileName != null &&
                              controller.fileName!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              controller.fileName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.rotate_left, color: Colors.white),
                      tooltip: 'Rotate Left',
                      onPressed: controller.rotateCounterClockwise,
                    ),
                    IconButton(
                      icon: const Icon(Icons.rotate_right, color: Colors.white),
                      tooltip: 'Rotate Right',
                      onPressed: controller.rotateClockwise,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.download_outlined,
                        color: Colors.white,
                      ),
                      tooltip: 'Download Image',
                      onPressed: controller.handleDownload,
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
                'Unable to Load Image via API',
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
                    label: const Text('Retry Loading'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: controller.loadImageBytesViaApi,
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
