import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

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

  static final Set<String> _registeredViewTypes = <String>{};

  String get _viewType {
    if (bytes != null && bytes!.isNotEmpty) {
      return 'kt-docs-browser-pdf-${bytes!.lengthInBytes}-${bytes.hashCode}';
    }
    return 'kt-docs-browser-url-${sourceUrl.hashCode}';
  }

  void _registerView() {
    if (_registeredViewTypes.contains(_viewType)) return;

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      String resolvedSrc;
      if (bytes != null && bytes!.isNotEmpty) {
        final blob = web.Blob(
          [bytes!.toJS].toJS,
          web.BlobPropertyBag(type: 'application/pdf'),
        );
        resolvedSrc = web.URL.createObjectURL(blob);
      } else {
        var cleanUrl = sourceUrl.trim();
        if (cleanUrl.contains('drive.google.com') && cleanUrl.contains('/view')) {
          cleanUrl = cleanUrl.replaceAll('/view', '/preview');
        }
        resolvedSrc = cleanUrl;
      }

      final iframe = web.document.createElement('iframe') as web.HTMLIFrameElement
        ..src = resolvedSrc
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..setAttribute('title', 'KT Docs PDF preview');
      iframe.onload = (web.Event _) {
        onDocumentLoaded();
      }.toJS;
      iframe.onerror = (web.Event _) {
        onDocumentLoadFailed('Browser preview iframe failed to load.');
      }.toJS;
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
