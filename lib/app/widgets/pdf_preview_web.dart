import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

class PdfPreview extends StatelessWidget {
  final Uint8List bytes;
  final String sourceUrl;
  final VoidCallback onDocumentLoaded;
  final ValueChanged<String> onDocumentLoadFailed;

  const PdfPreview({
    super.key,
    required this.bytes,
    required this.sourceUrl,
    required this.onDocumentLoaded,
    required this.onDocumentLoadFailed,
  });

  static final Set<String> _registeredViewTypes = <String>{};

  String get _viewType => 'kt-docs-browser-pdf-${sourceUrl.hashCode}';

  void _registerView() {
    if (_registeredViewTypes.contains(_viewType)) return;

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = sourceUrl
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..setAttribute('title', 'KT Docs PDF preview');
      iframe.onLoad.listen((_) => onDocumentLoaded());
      iframe.onError.listen((_) => onDocumentLoadFailed('Browser PDF iframe failed to load.'));
      return iframe;
    });
    _registeredViewTypes.add(_viewType);
  }

  @override
  Widget build(BuildContext context) {
    _registerView();
    return HtmlElementView(viewType: _viewType);
  }
}
