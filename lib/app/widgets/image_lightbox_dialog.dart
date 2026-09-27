import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/widgets/app_shimmer.dart';
import 'package:kt_prod_kt_docs/core/utils/app_dialog.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/utils/file_api_helper.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';

/// GetX-compliant interactive Image Lightbox Dialog loading bytes via API.
/// Provides zoom, rotation, realistic skeleton loading, inline retry, and direct downloads.
class ImageLightboxDialog extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final Uint8List? imageBytes;
  final String? fileName;
  final VoidCallback? onDownload;

  ImageLightboxDialog({
    super.key,
    required this.title,
    this.imageUrl,
    this.imageBytes,
    this.fileName,
    this.onDownload,
  }) {
    if (imageBytes != null && imageBytes!.isNotEmpty) {
      _loadedBytes.value = imageBytes;
      _isLoading.value = false;
    } else if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      _loadImageBytesViaApi();
    } else {
      _errorMessage.value = 'No image URL or binary data was provided.';
      _isLoading.value = false;
    }
  }

  final RxBool _isLoading = true.obs;
  final RxString _errorMessage = ''.obs;
  final Rxn<Uint8List> _loadedBytes = Rxn<Uint8List>();
  final RxInt _quarterTurns = 0.obs;

  static void show({
    required String title,
    String? imageUrl,
    Uint8List? imageBytes,
    String? fileName,
    VoidCallback? onDownload,
  }) {
    AppDialog.show(
      ImageLightboxDialog(
        title: title,
        imageUrl: imageUrl,
        imageBytes: imageBytes,
        fileName: fileName,
        onDownload: onDownload,
      ),
      barrierColor: Colors.black87,
    );
  }

  Future<void> _loadImageBytesViaApi() async {
    _isLoading.value = true;
    _errorMessage.value = '';

    AppLogger.debug('IMAGE_LIGHTBOX', 'Loading image bytes via API: title="$title", url=$imageUrl');

    try {
      final bytes = await FileApiHelper.fetchBytes(imageUrl!);
      _loadedBytes.value = bytes;
      _isLoading.value = false;
      AppLogger.info('IMAGE_LIGHTBOX', 'Image bytes successfully loaded via API (${bytes.length} bytes).');
    } catch (error, st) {
      AppLogger.error('IMAGE_LIGHTBOX', 'Failed to load image via API: $error', error: error, stackTrace: st);
      _errorMessage.value = error.toString().replaceFirst('Exception: ', '');
      _isLoading.value = false;
    }
  }

  void _rotateClockwise() {
    _quarterTurns.value = (_quarterTurns.value + 1) % 4;
  }

  void _rotateCounterClockwise() {
    _quarterTurns.value = (_quarterTurns.value - 1 + 4) % 4;
  }

  void _handleDownload() {
    if (_loadedBytes.value != null) {
      final resolvedName = fileName != null && fileName!.isNotEmpty
          ? fileName!
          : '$title.jpg';
      FileApiHelper.downloadFileFromBytes(
        bytes: _loadedBytes.value!,
        fileName: resolvedName,
        mimeType: 'image/jpeg',
      );
    } else if (onDownload != null) {
      onDownload!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dialogWidth = (size.width * 0.90).clamp(320.0, 1140.0);
    final dialogHeight = (size.height * 0.88).clamp(420.0, 920.0);

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
              if (_isLoading.value) {
                return const AppShimmer(child: DocumentPreviewSkeleton());
              }

              if (_errorMessage.value.isNotEmpty) {
                return _buildErrorView();
              }

              if (_loadedBytes.value != null) {
                return RotatedBox(
                  quarterTurns: _quarterTurns.value,
                  child: PhotoView(
                    imageProvider: MemoryImage(_loadedBytes.value!),
                    backgroundDecoration: const BoxDecoration(
                      color: Color(0xFF0B1120),
                    ),
                    minScale: PhotoViewComputedScale.contained * 0.8,
                    maxScale: PhotoViewComputedScale.covered * 3.5,
                    loadingBuilder: (context, event) => const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
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
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                      ),
                      child: const Icon(Icons.image, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: AppConstants.paddingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (fileName != null && fileName!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              fileName!,
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
                      onPressed: _rotateCounterClockwise,
                    ),
                    IconButton(
                      icon: const Icon(Icons.rotate_right, color: Colors.white),
                      tooltip: 'Rotate Right',
                      onPressed: _rotateClockwise,
                    ),
                    IconButton(
                      icon: const Icon(Icons.download_outlined, color: Colors.white),
                      tooltip: 'Download Image',
                      onPressed: _handleDownload,
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
                _errorMessage.value,
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
                    onPressed: _loadImageBytesViaApi,
                  ),
                  if (imageUrl != null && imageUrl!.isNotEmpty)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Open External URL'),
                      onPressed: () async {
                        final uri = Uri.parse(imageUrl!);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    ),
                  TextButton(
                    onPressed: Get.back,
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
