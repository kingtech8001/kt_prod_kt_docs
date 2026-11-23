import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/widgets/pdf_viewer_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kt_prod_kt_docs/app/controllers/image_preview_controller.dart';
import 'package:kt_prod_kt_docs/app/controllers/pdf_preview_controller.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/document_preview_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/utility_bills_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _PreviewDataset extends DocumentPreviewDataset {
  _PreviewDataset() : super(SupabaseProvider());
  bool fail = true;
  @override
  Future<Uint8List> fetchBytes(String url) async {
    if (fail) throw StateError('Simulated network failure');
    return Uint8List.fromList([1, 2, 3]);
  }
}

class _Provider extends SupabaseProvider {
  _Provider(this.client);
  @override
  final SupabaseClient client;
}

void main() {
  testWidgets('PDF preview error fits a mobile viewport and closes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);
    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: SizedBox())),
    );
    PdfViewerDialog.showBytes(
      title: 'Invalid document',
      bytes: Uint8List.fromList([1, 2, 3]),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('valid PDF'), findsOneWidget);
    expect(tester.takeException(), isNull);
    Get.back();
    await tester.pumpAndSettle();
    expect(find.byType(PdfViewerDialog), findsNothing);
  });
  test('image preview shows inline failure and recovers on retry', () async {
    final dataset = _PreviewDataset();
    final controller = ImagePreviewController(
      dataset,
      title: 'Test',
      imageUrl: 'https://test.invalid/image',
    );
    await controller.loadImageBytesViaApi();
    expect(controller.isLoading.value, isFalse);
    expect(controller.errorMessage.value, isNotEmpty);
    dataset.fail = false;
    await controller.loadImageBytesViaApi();
    expect(controller.errorMessage.value, isEmpty);
    expect(controller.loadedBytes.value, [1, 2, 3]);
    controller.rotateClockwise();
    expect(controller.quarterTurns.value, 1);
    controller.rotateCounterClockwise();
    expect(controller.quarterTurns.value, 0);
  });

  test('invalid PDF input produces inline error without network access', () {
    final controller = PdfPreviewController(
      _PreviewDataset(),
      title: 'Test',
      pdfBytes: Uint8List.fromList([1, 2, 3]),
    );
    controller.onInit();
    expect(controller.isLoading.value, isFalse);
    expect(controller.errorMessage.value, contains('valid PDF'));
    expect(controller.pdfBytes.value, isNull);
  });

  test('Google Drive PDF resolves embedded preview URL', () async {
    final controller = PdfPreviewController(
      _PreviewDataset(),
      title: 'Test',
      filePath: 'gdrive://test-id',
    );
    await controller.loadPdfBytesViaApi();
    expect(
      controller.webPreviewUrl.value,
      'https://drive.google.com/file/d/test-id/preview',
    );
    expect(controller.errorMessage.value, isEmpty);
  });

  test('utility history requests a bounded, stable second page', () async {
    final client = SupabaseClient(
      'https://test.invalid',
      'key',
      httpClient: MockClient((request) async {
        expect(request.url.queryParameters['offset'], '25');
        expect(request.url.queryParameters['limit'], '25');
        expect(
          request.url.queryParameters['utility_metadata.consumer_number'],
          'eq.test-consumer',
        );
        expect(request.url.queryParameters['order'], contains('id.asc'));
        return http.Response(
          jsonEncode([]),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.dispose);
    final result = await UtilityBillsDataset(
      _Provider(client),
    ).getUtilityConnectionHistory('test-consumer', page: 2);
    expect(result, isEmpty);
  });
}
