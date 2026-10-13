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
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// GetX-compliant interactive PDF Viewer Dialog loading binary bytes via API.
/// Zero setState, realistic skeleton loader mirroring dialog geometry, inline error retry.
class PdfViewerDialog extends StatelessWidget {
  final String title;
  final String? signedPdfUrl;
  final Uint8List? pdfBytes;
  final String? fileName;
  final String? filePath;
  final VoidCallback? onDownload;

  PdfViewerDialog({
    super.key,
    required this.title,
    this.signedPdfUrl,
    this.pdfBytes,
    this.fileName,
    this.filePath,
    this.onDownload,
  }) {
    if (pdfBytes != null && pdfBytes!.isNotEmpty) {
      _initFromBytes(pdfBytes!);
    } else if ((signedPdfUrl != null && signedPdfUrl!.trim().isNotEmpty) ||
        (filePath != null && filePath!.trim().isNotEmpty)) {
      _loadPdfBytesViaApi();
    } else {
      _errorMessage.value = 'No PDF URL or binary stream was provided.';
      _isLoading.value = false;
    }
  }

  final RxBool _isLoading = true.obs;
  final RxString _errorMessage = ''.obs;
  final Rxn<Uint8List> _pdfBytes = Rxn<Uint8List>();
  final RxString _webPreviewUrl = ''.obs;

  static void show({
    required String title,
    String? signedPdfUrl,
    Uint8List? pdfBytes,
    String? fileName,
    String? filePath,
    VoidCallback? onDownload,
  }) {
    AppDialog.show(
      PdfViewerDialog(
        title: title,
        signedPdfUrl: signedPdfUrl,
        pdfBytes: pdfBytes,
        fileName: fileName,
        filePath: filePath,
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

  static bool hasPdfHeader(Uint8List bytes) {
    if (bytes.length < 5) return false;
    final limit = bytes.length < 1024 ? bytes.length : 1024;
    for (int i = 0; i <= limit - 5; i++) {
      if (bytes[i] == 0x25 && // %
          bytes[i + 1] == 0x50 && // P
          bytes[i + 2] == 0x44 && // D
          bytes[i + 3] == 0x46 && // F
          bytes[i + 4] == 0x2D) { // -
        return true;
      }
    }
    return false;
  }

  void _initFromBytes(Uint8List bytes) {
    if (hasPdfHeader(bytes)) {
      try {
        final document = PdfDocument(inputBytes: bytes);
        document.dispose();
        AppLogger.info('PDF_VIEWER', 'In-memory PDF validated successfully (${bytes.length} bytes).');
      } catch (err) {
        AppLogger.warning('PDF_VIEWER', 'In-memory PDF parser notice: $err (rendering natively).');
      }
      _pdfBytes.value = bytes;
      _isLoading.value = false;
    } else {
      _errorMessage.value = 'The provided file does not have a valid PDF format.';
      _isLoading.value = false;
    }
  }

  Future<void> _loadPdfBytesViaApi() async {
    _isLoading.value = true;
    _errorMessage.value = '';

    AppLogger.debug('PDF_VIEWER', 'Fetching PDF bytes via API: title="$title", url=$signedPdfUrl, path=$filePath');

    try {
      final candidateUrl = signedPdfUrl?.trim() ?? '';
      final candidatePath = filePath?.trim() ?? '';

      // 1. Google Drive attachment previews
      if (candidateUrl.startsWith('gdrive://') ||
          candidateUrl.contains('drive.google.com') ||
          candidateUrl.contains('docs.google.com') ||
          candidatePath.startsWith('gdrive://') ||
          candidatePath.contains('drive.google.com') ||
          candidatePath.contains('docs.google.com')) {
        var resolvedGUrl = candidateUrl.isNotEmpty &&
                (candidateUrl.contains('drive.google.com') || candidateUrl.startsWith('gdrive://'))
            ? candidateUrl
            : candidatePath;
        if (resolvedGUrl.startsWith('gdrive://')) {
          resolvedGUrl = 'https://drive.google.com/file/d/${resolvedGUrl.replaceFirst("gdrive://", "")}/preview';
        }
        if (resolvedGUrl.contains('/view')) {
          resolvedGUrl = resolvedGUrl.replaceAll('/view', '/preview');
        }
        _webPreviewUrl.value = resolvedGUrl;
        _isLoading.value = false;
        return;
      }

      Uint8List? bytes;

      // 2. Try fetching from signedPdfUrl if it's a valid HTTP URL
      if (candidateUrl.startsWith('http://') || candidateUrl.startsWith('https://')) {
        try {
          final fetched = await FileApiHelper.fetchBytes(candidateUrl);
          if (fetched.isNotEmpty && hasPdfHeader(fetched)) {
            bytes = fetched;
          }
        } catch (fetchErr) {
          AppLogger.warning('PDF_VIEWER', 'Direct signed URL fetch warning: $fetchErr. Trying storage fallback.');
        }
      }

      // 3. Fallback: retrieve directly from Supabase Storage bucket
      if (bytes == null) {
        final storagePath = candidatePath.isNotEmpty && !candidatePath.startsWith('http')
            ? candidatePath
            : (candidateUrl.isNotEmpty && !candidateUrl.startsWith('http') ? candidateUrl : null);

        if (storagePath != null) {
          final cleanPath = storagePath.startsWith('/') ? storagePath.substring(1) : storagePath;

          // Attempt 3a: Direct Supabase binary download using authenticated client
          try {
            AppLogger.info('PDF_VIEWER', 'Downloading PDF directly from Supabase storage: "$cleanPath"');
            final downloaded = await Supabase.instance.client.storage
                .from(AppConstants.storageBucket)
                .download(cleanPath);
            if (downloaded.isNotEmpty && hasPdfHeader(downloaded)) {
              bytes = downloaded;
            }
          } catch (storageErr) {
            AppLogger.warning('PDF_VIEWER', 'Direct Supabase storage download notice: $storageErr');
          }

          // Attempt 3b: Create fresh signed URL from Supabase storage
          if (bytes == null) {
            try {
              AppLogger.info('PDF_VIEWER', 'Creating fresh signed URL for: "$cleanPath"');
              final freshSignedUrl = await Supabase.instance.client.storage
                  .from(AppConstants.storageBucket)
                  .createSignedUrl(cleanPath, 3600);
              final fetched = await FileApiHelper.fetchBytes(freshSignedUrl);
              if (fetched.isNotEmpty && hasPdfHeader(fetched)) {
                bytes = fetched;
              }
            } catch (signedErr) {
              AppLogger.warning('PDF_VIEWER', 'Fresh signed URL fetch notice: $signedErr');
            }
          }
        }
      }

      if (bytes == null || bytes.isEmpty) {
        throw Exception('Unable to retrieve PDF data. Please check network connection or verify document storage.');
      }

      // 4. Validate PDF header
      if (!hasPdfHeader(bytes)) {
        final previewStr = String.fromCharCodes(bytes.take(30)).toLowerCase();
        if (previewStr.contains('<html') || previewStr.contains('<!doctype') || previewStr.contains('{"')) {
          throw Exception('The storage service returned an HTML or error response instead of the PDF binary.');
        }
        throw Exception('This file is damaged or not a valid PDF document. Please upload the original PDF again.');
      }

      // 5. AST validation check (non-blocking)
      try {
        final document = PdfDocument(inputBytes: bytes);
        document.dispose();
        AppLogger.info('PDF_VIEWER', 'PDF structure validated successfully (${bytes.length} bytes).');
      } catch (parserErr) {
        // Digitally signed invoices, Acrobat encryption flags, or XRef streams often throw in Syncfusion,
        // but render natively without issue in the browser viewer.
        AppLogger.warning('PDF_VIEWER', 'Syncfusion AST notice: $parserErr (proceeding with native PDF viewer).');
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
    final resolvedName = fileName != null && fileName!.toLowerCase().endsWith('.pdf')
        ? fileName!
        : '$title.pdf';

    if (_pdfBytes.value != null && _pdfBytes.value!.isNotEmpty) {
      FileApiHelper.downloadFileFromBytes(
        bytes: _pdfBytes.value!,
        fileName: resolvedName,
        mimeType: 'application/pdf',
      );
      return;
    }

    if (onDownload != null) {
      onDownload!();
      return;
    }

    if (signedPdfUrl != null && (signedPdfUrl!.startsWith('http://') || signedPdfUrl!.startsWith('https://'))) {
      FileApiHelper.downloadFileFromUrl(
        url: signedPdfUrl!,
        fileName: resolvedName,
        mimeType: 'application/pdf',
      );
      return;
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

                if (_pdfBytes.value != null || _webPreviewUrl.value.isNotEmpty) {
                  return ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(AppConstants.radiusMedium),
                      bottomRight: Radius.circular(AppConstants.radiusMedium),
                    ),
                    child: PdfPreview(
                      bytes: _pdfBytes.value,
                      sourceUrl: _webPreviewUrl.value.isNotEmpty
                          ? _webPreviewUrl.value
                          : (signedPdfUrl ?? ''),
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
                  if (_pdfBytes.value != null ||
                      onDownload != null ||
                      (signedPdfUrl != null && signedPdfUrl!.startsWith('http')))
                    OutlinedButton.icon(
                      icon: const Icon(Icons.download_outlined, size: 16),
                      label: const Text('Download'),
                      onPressed: _handleDownload,
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
