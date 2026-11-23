import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/document_preview_dataset.dart';
import 'package:kt_prod_kt_docs/core/utils/app_dialog.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfPreviewController extends GetxController {
  PdfPreviewController(
    this._dataset, {
    required this.title,
    this.signedPdfUrl,
    Uint8List? pdfBytes,
    this.fileName,
    this.filePath,
    this.onDownload,
  }) : initialBytes = pdfBytes;
  final DocumentPreviewDataset _dataset;
  final String title;
  final String? signedPdfUrl;
  final Uint8List? initialBytes;
  final String? fileName;
  final String? filePath;
  final VoidCallback? onDownload;

  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final Rxn<Uint8List> pdfBytes = Rxn<Uint8List>();
  final RxString webPreviewUrl = ''.obs;

  @override
  void onInit() {
    super.onInit();

    if (initialBytes != null && initialBytes!.isNotEmpty) {
      initFromBytes(initialBytes!);
    } else if ((signedPdfUrl != null && signedPdfUrl!.trim().isNotEmpty) ||
        (filePath != null && filePath!.trim().isNotEmpty)) {
      loadPdfBytesViaApi();
    } else {
      errorMessage.value = 'No PDF URL or binary stream was provided.';
      isLoading.value = false;
    }
  }

  Future<void> present(Widget dialog, String tag) async {
    try {
      await AppDialog.show(dialog, barrierDismissible: false);
    } catch (error, stackTrace) {
      AppLogger.error(
        'PREVIEW_CONTROLLER',
        'Could not show preview.',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      Get.delete<PdfPreviewController>(tag: tag);
    }
  }

  static bool hasPdfHeader(Uint8List bytes) {
    if (bytes.length < 5) return false;
    final limit = bytes.length < 1024 ? bytes.length : 1024;
    for (int i = 0; i <= limit - 5; i++) {
      if (bytes[i] == 0x25 && // %
          bytes[i + 1] == 0x50 && // P
          bytes[i + 2] == 0x44 && // D
          bytes[i + 3] == 0x46 && // F
          bytes[i + 4] == 0x2D) {
        // -
        return true;
      }
    }
    return false;
  }

  void initFromBytes(Uint8List bytes) {
    if (hasPdfHeader(bytes)) {
      try {
        final document = PdfDocument(inputBytes: bytes);
        document.dispose();
        AppLogger.info(
          'PDF_VIEWER',
          'In-memory PDF validated successfully (${bytes.length} bytes).',
        );
      } catch (err) {
        AppLogger.warning(
          'PDF_VIEWER',
          'In-memory PDF parser notice: $err (rendering natively).',
        );
      }
      pdfBytes.value = bytes;
      isLoading.value = false;
    } else {
      errorMessage.value =
          'The provided file does not have a valid PDF format.';
      isLoading.value = false;
    }
  }

  Future<void> loadPdfBytesViaApi() async {
    isLoading.value = true;
    errorMessage.value = '';

    AppLogger.debug(
      'PDF_VIEWER',
      'Fetching PDF bytes via API: title="$title", url=$signedPdfUrl, path=$filePath',
    );

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
        var resolvedGUrl =
            candidateUrl.isNotEmpty &&
                (candidateUrl.contains('drive.google.com') ||
                    candidateUrl.startsWith('gdrive://'))
            ? candidateUrl
            : candidatePath;
        if (resolvedGUrl.startsWith('gdrive://')) {
          resolvedGUrl =
              'https://drive.google.com/file/d/${resolvedGUrl.replaceFirst("gdrive://", "")}/preview';
        }
        if (resolvedGUrl.contains('/view')) {
          resolvedGUrl = resolvedGUrl.replaceAll('/view', '/preview');
        }
        webPreviewUrl.value = resolvedGUrl;
        isLoading.value = false;
        return;
      }

      Uint8List? bytes;

      // 2. Try fetching from signedPdfUrl if it's a valid HTTP URL
      if (candidateUrl.startsWith('http://') ||
          candidateUrl.startsWith('https://')) {
        try {
          final fetched = await _dataset.fetchBytes(candidateUrl);
          if (fetched.isNotEmpty && hasPdfHeader(fetched)) {
            bytes = fetched;
          }
        } catch (fetchErr) {
          AppLogger.warning(
            'PDF_VIEWER',
            'Direct signed URL fetch warning: $fetchErr. Trying storage fallback.',
          );
        }
      }

      // 3. Fallback: retrieve directly from Supabase Storage bucket
      if (bytes == null) {
        final storagePath =
            candidatePath.isNotEmpty && !candidatePath.startsWith('http')
            ? candidatePath
            : (candidateUrl.isNotEmpty && !candidateUrl.startsWith('http')
                  ? candidateUrl
                  : null);

        if (storagePath != null) {
          final cleanPath = storagePath.startsWith('/')
              ? storagePath.substring(1)
              : storagePath;

          // Attempt 3a: Direct Supabase binary download using authenticated client
          try {
            AppLogger.info(
              'PDF_VIEWER',
              'Downloading PDF directly from Supabase storage: "$cleanPath"',
            );
            final downloaded = await _dataset.download(cleanPath);
            if (downloaded.isNotEmpty && hasPdfHeader(downloaded)) {
              bytes = downloaded;
            }
          } catch (storageErr) {
            AppLogger.warning(
              'PDF_VIEWER',
              'Direct Supabase storage download notice: $storageErr',
            );
          }

          // Attempt 3b: Create fresh signed URL from Supabase storage
          if (bytes == null) {
            try {
              AppLogger.info(
                'PDF_VIEWER',
                'Creating fresh signed URL for: "$cleanPath"',
              );
              final freshSignedUrl = await _dataset.createSignedUrl(cleanPath);
              final fetched = await _dataset.fetchBytes(freshSignedUrl);
              if (fetched.isNotEmpty && hasPdfHeader(fetched)) {
                bytes = fetched;
              }
            } catch (signedErr) {
              AppLogger.warning(
                'PDF_VIEWER',
                'Fresh signed URL fetch notice: $signedErr',
              );
            }
          }
        }
      }

      if (bytes == null || bytes.isEmpty) {
        throw Exception(
          'Unable to retrieve PDF data. Please check network connection or verify document storage.',
        );
      }

      // 4. Validate PDF header
      if (!hasPdfHeader(bytes)) {
        final previewStr = String.fromCharCodes(bytes.take(30)).toLowerCase();
        if (previewStr.contains('<html') ||
            previewStr.contains('<!doctype') ||
            previewStr.contains('{"')) {
          throw Exception(
            'The storage service returned an HTML or error response instead of the PDF binary.',
          );
        }
        throw Exception(
          'This file is damaged or not a valid PDF document. Please upload the original PDF again.',
        );
      }

      // 5. AST validation check (non-blocking)
      try {
        final document = PdfDocument(inputBytes: bytes);
        document.dispose();
        AppLogger.info(
          'PDF_VIEWER',
          'PDF structure validated successfully (${bytes.length} bytes).',
        );
      } catch (parserErr) {
        // Digitally signed invoices, Acrobat encryption flags, or XRef streams often throw in Syncfusion,
        // but render natively without issue in the browser viewer.
        AppLogger.warning(
          'PDF_VIEWER',
          'Syncfusion AST notice: $parserErr (proceeding with native PDF viewer).',
        );
      }

      pdfBytes.value = bytes;
      isLoading.value = false;
    } catch (error, st) {
      AppLogger.error(
        'PDF_VIEWER',
        'Failed to load PDF via API: $error',
        error: error,
        stackTrace: st,
      );
      errorMessage.value = error.toString().replaceFirst('Exception: ', '');
      isLoading.value = false;
    }
  }

  Future<void> handleDownload() async {
    try {
      final name = fileName?.isNotEmpty == true ? fileName! : '$title.pdf';
      final data = pdfBytes.value;
      if (data != null && data.isNotEmpty) {
        await _dataset.downloadBytes(data, name, 'application/pdf');
      } else if (onDownload != null) {
        onDownload!();
      } else if (signedPdfUrl != null) {
        await _dataset.downloadUrl(signedPdfUrl!, name, 'application/pdf');
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'PREVIEW_CONTROLLER',
        'Download failed.',
        error: error,
        stackTrace: stackTrace,
      );
      errorMessage.value = error.toString();
    }
  }
}
