import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfPreview extends StatelessWidget {
  final Uint8List? bytes;
  final String sourceUrl;
  final VoidCallback onDocumentLoaded;
  final ValueChanged<String> onDocumentLoadFailed;

  const PdfPreview({
    super.key,
    this.bytes,
    required this.sourceUrl,
    required this.onDocumentLoaded,
    required this.onDocumentLoadFailed,
  });

  @override
  Widget build(BuildContext context) {
    if (bytes != null && bytes!.isNotEmpty) {
      return SfPdfViewer.memory(
        bytes!,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        enableDoubleTapZooming: true,
        onDocumentLoaded: (_) => onDocumentLoaded(),
        onDocumentLoadFailed: (details) {
          onDocumentLoadFailed('${details.error}: ${details.description}');
        },
      );
    }
    return SfPdfViewer.network(
      sourceUrl,
      canShowScrollHead: true,
      canShowScrollStatus: true,
      enableDoubleTapZooming: true,
      onDocumentLoaded: (_) => onDocumentLoaded(),
      onDocumentLoadFailed: (details) {
        onDocumentLoadFailed('${details.error}: ${details.description}');
      },
    );
  }
}
