import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/controllers/pdf_preview_controller.dart';
import 'package:kt_prod_kt_docs/app/controllers/image_preview_controller.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/document_preview_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';

class PreviewBinding extends Bindings {
  PreviewBinding({
    required this.tag,
    required this.pdf,
    required this.title,
    this.url,
    this.bytes,
    this.fileName,
    this.filePath,
    this.onDownload,
  });
  final String tag;
  final bool pdf;
  final String title;
  final String? url, fileName, filePath;
  final Uint8List? bytes;
  final VoidCallback? onDownload;
  static int _sequence = 0;
  static String nextTag() => 'preview-${++_sequence}';

  @override
  void dependencies() {
    if (!Get.isRegistered<SupabaseProvider>()) {
      Get.lazyPut<SupabaseProvider>(() => SupabaseProvider(), fenix: true);
    }
    if (!Get.isRegistered<DocumentPreviewDataset>()) {
      Get.lazyPut<DocumentPreviewDataset>(
        () => DocumentPreviewDataset(Get.find<SupabaseProvider>()),
        fenix: true,
      );
    }
    if (pdf) {
      Get.lazyPut<PdfPreviewController>(
        () => PdfPreviewController(
          Get.find<DocumentPreviewDataset>(),
          title: title,
          signedPdfUrl: url,
          pdfBytes: bytes,
          fileName: fileName,
          filePath: filePath,
          onDownload: onDownload,
        ),
        tag: tag,
      );
    } else {
      Get.lazyPut<ImagePreviewController>(
        () => ImagePreviewController(
          Get.find<DocumentPreviewDataset>(),
          title: title,
          imageUrl: url,
          imageBytes: bytes,
          fileName: fileName,
          filePath: filePath,
          onDownload: onDownload,
        ),
        tag: tag,
      );
    }
  }
}
