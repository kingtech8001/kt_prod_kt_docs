import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/widgets/pdf_preview.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:http/http.dart' as http;

class PdfViewerDialog extends StatefulWidget {
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
      barrierDismissible: false,
    );
  }

  @override
  State<PdfViewerDialog> createState() => _PdfViewerDialogState();
}

class _PdfViewerDialogState extends State<PdfViewerDialog> {
  late final Future<Uint8List> _pdfBytes;

  void _debug(String message) {
    debugPrint('[PDF_VIEWER] $message');
  }

  @override
  void initState() {
    super.initState();
    _debug('Opening preview: title="${widget.title}", host=${Uri.parse(widget.signedPdfUrl).host}');
    _pdfBytes = _loadPdfBytes();
  }

  Future<Uint8List> _loadPdfBytes() async {
    final previewUri = Uri.parse(widget.signedPdfUrl);
    _debug('Request started.');
    try {
      final response = await http
          .get(previewUri)
          .timeout(const Duration(seconds: 30));
      _debug(
        'Response received: HTTP ${response.statusCode}, contentType=${response.headers['content-type']}, bytes=${response.bodyBytes.length}.',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Unable to load PDF preview (HTTP ${response.statusCode}).',
        );
      }
      if (response.bodyBytes.isEmpty) {
        throw Exception('The PDF preview returned an empty file.');
      }

      try {
        final document = PdfDocument(inputBytes: response.bodyBytes);
        document.dispose();
        _debug('PDF validation succeeded. Rendering original bytes without rewriting.');
        return response.bodyBytes;
      } catch (error) {
        _debug('PDF validation failed: $error');
        throw Exception(
          'This PDF is invalid or was damaged during an earlier upload. Please upload the original PDF again.',
        );
      }
    } catch (error) {
      _debug('Preview load failed: $error');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: size.width * 0.9,
        height: size.height * 0.88,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (widget.onDownload != null)
                    IconButton(
                      icon: const Icon(Icons.download_outlined),
                      tooltip: 'Download',
                      onPressed: widget.onDownload,
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Close preview',
                    onPressed: Get.back,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<Uint8List>(
                future: _pdfBytes,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    _debug('Rendering ${snapshot.data!.length} PDF bytes.');
                    _debug('Rendering with the platform PDF previewer.');
                    return PdfPreview(
                      bytes: snapshot.data!,
                      sourceUrl: widget.signedPdfUrl,
                      onDocumentLoaded: () {
                        _debug('Renderer loaded document successfully.');
                      },
                      onDocumentLoadFailed: (error) {
                        _debug('Renderer failed: $error');
                      },
                    );
                  }
                  if (snapshot.hasError) {
                    _debug('Rendering error state: ${snapshot.error}');
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
