import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/staff_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/models/profile_model.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/auth_repository.dart';
import 'package:kt_prod_kt_docs/app/data/services/auth_service.dart';
import 'package:kt_prod_kt_docs/app/widgets/detail_skeleton.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Provider extends SupabaseProvider {
  _Provider(this.client);
  @override
  final SupabaseClient client;
}

void main() {
  test('editing requires an active authorized profile', () {
    final service = AuthService(AuthRepository(SupabaseProvider()));
    expect(service.canEdit, isFalse);
    expect(service.isAdmin, isFalse);
    for (final role in ['viewer', 'user', 'editor', 'admin']) {
      for (final active in [false, true]) {
        service.currentProfile.value = ProfileModel(
          id: 'test',
          email: 'test@example.com',
          fullName: 'Test',
          role: role,
          isActive: active,
          createdAt: DateTime(2026),
        );
        expect(
          service.canEdit,
          active && (role == 'editor' || role == 'admin'),
        );
        expect(service.isAdmin, active && role == 'admin');
      }
    }
  });

  test('staff filtering and page bounds are sent to server', () async {
    final client = SupabaseClient(
      'https://test.invalid',
      'key',
      httpClient: MockClient((request) async {
        expect(request.url.queryParameters['offset'], '25');
        expect(request.url.queryParameters['limit'], '25');
        expect(request.url.queryParameters['role'], 'eq.editor');
        expect(request.url.queryParameters['or'], contains('Mihir'));
        return http.Response(
          jsonEncode([]),
          200,
          request: request,
          headers: {
            'content-type': 'application/json',
            'content-range': '*/40',
          },
        );
      }),
    );
    addTearDown(client.dispose);
    final result = await StaffDataset(
      _Provider(client),
    ).getStaffPage(page: 2, pageSize: 25, search: 'Mihir', role: 'editor');
    expect(result.total, 40);
  });

  for (final width in [320.0, 768.0, 1024.0, 1440.0]) {
    testWidgets('detail skeleton fits viewport $width', (tester) async {
      tester.view.physicalSize = Size(width, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: DetailSkeleton())),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
