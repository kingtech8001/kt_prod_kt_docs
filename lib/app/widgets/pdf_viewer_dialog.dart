import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/widgets/app_shimmer.dart';
import 'package:kt_prod_kt_docs/core/utils/app_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/pdf_preview.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/utils/file_api_helper.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:url_launcher/url_launcher.dart';

/// GetX-compliant interactive PDF Viewer Dialog loading binary bytes via API.
/// Zero setState, realistic skeleton loader mirroring dialog geometry, inline error retry.
class PdfViewerDialog extends StatelessWidget {
  final String title;
  final String? signedPdfUrl;
  final Uint8List? pdfBytes;
  final String? fileName;
  final VoidCallback? onDownload;

  PdfViewerDialog({
    super.key,
    required this.title,
    this.signedPdfUrl,
    this.pdfBytes,
    this.fileName,
    this.onDownload,
  }) {
    if (pdfBytes != null && pdfBytes!.isNotEmpty) {
      _initFromBytes(pdfBytes!);
    } else if (signedPdfUrl != null && signedPdfUrl!.trim().isNotEmpty) {
      _loadPdfBytesViaApi();
    } else {
      _errorMessage.value = 'No PDF URL or binary stream was provided.';
      _isLoading.value = false;
    }
  }

  final RxBool _isLoading = true.obs;
  final RxString _errorMessage = ''.obs;
  final Rxn<Uint8List> _pdfBytes = Rxn<Uint8List>();

  static void show({
    required String title,
    String? signedPdfUrl,
    Uint8List? pdfBytes,
    String? fileName,
    VoidCallback? onDownload,
  }) {
    AppDialog.show(
      PdfViewerDialog(
        title: title,
        signedPdfUrl: signedPdfUrl,
        pdfBytes: pdfBytes,
        fileName: fileName,
        onDownload: onDownload,
      ),
      barrierDismissible: false,
    );
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

  void _initFromBytes(Uint8List bytes) {
    try {
      final document = PdfDocument(inputBytes: bytes);
      document.dispose();
      AppLogger.info('PDF_VIEWER', 'In-memory PDF validated successfully (${bytes.length} bytes).');
      _pdfBytes.value = bytes;
      _isLoading.value = false;
    } catch (err) {
      _errorMessage.value = 'This PDF is damaged or invalid. Please re-upload.';
      _isLoading.value = false;
    }
  }

  Future<void> _loadPdfBytesViaApi() async {
    _isLoading.value = true;
    _errorMessage.value = '';

    AppLogger.debug('PDF_VIEWER', 'Fetching PDF bytes via API: title="$title", url=$signedPdfUrl');

    try {
      if (signedPdfUrl == null || signedPdfUrl!.trim().isEmpty) {
        throw Exception('No PDF URL or binary stream was provided.');
      }
      final bytes = await FileApiHelper.fetchBytes(signedPdfUrl!);

      // Validate PDF structure
      try {
        final document = PdfDocument(inputBytes: bytes);
        document.dispose();
        AppLogger.info('PDF_VIEWER', 'PDF structure validated successfully (${bytes.length} bytes).');
      } catch (err) {
        throw Exception(
          'This PDF is damaged or invalid. Please upload the original PDF document again.',
        );
      }

      _pdfBytes.value = bytes;
      _isLoading.value = false;
    } catch (error, st) {
      AppLogger.error('PDF_VIEWER', 'Failed to load PDF via API: $error', error: error, stackTrace: st);
      _errorMessage.value = error.toString().replaceFirst('Exception: ', '');
      _isLoading.value = false;
    }
  }

  void _handleDownload() {
    if (_pdfBytes.value != null) {
      final resolvedName = fileName != null && fileName!.toLowerCase().endsWith('.pdf')
          ? fileName!
          : '$title.pdf';
      FileApiHelper.downloadFileFromBytes(
        bytes: _pdfBytes.value!,
        fileName: resolvedName,
        mimeType: 'application/pdf',
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
                      borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                    ),
                    child: const Icon(Icons.picture_as_pdf, color: AppColors.error, size: 20),
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
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (fileName != null && fileName!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            fileName!,
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
                    icon: const Icon(Icons.download_outlined, color: AppColors.primary),
                    tooltip: 'Download PDF',
                    onPressed: _handleDownload,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
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
                if (_isLoading.value) {
                  return const AppShimmer(child: DocumentPreviewSkeleton());
                }

                if (_errorMessage.value.isNotEmpty) {
                  return _buildErrorView();
                }

                if (_pdfBytes.value != null) {
                  return ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(AppConstants.radiusMedium),
                      bottomRight: Radius.circular(AppConstants.radiusMedium),
                    ),
                    child: PdfPreview(
                      bytes: _pdfBytes.value!,
                      sourceUrl: signedPdfUrl ?? '',
                      onDocumentLoaded: () {
                        AppLogger.info('PDF_VIEWER', 'PDF document rendered successfully.');
                      },
                      onDocumentLoadFailed: (error) {
                        AppLogger.warning('PDF_VIEWER', 'PDF renderer warning: $error');
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
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _loadPdfBytesViaApi,
                  ),
                  if (signedPdfUrl != null && signedPdfUrl!.isNotEmpty)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Open External URL'),
                      onPressed: () async {
                        final uri = Uri.parse(signedPdfUrl!);
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
