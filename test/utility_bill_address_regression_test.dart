import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/utility_bills_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _TestProvider extends SupabaseProvider {
  _TestProvider(this.client);

  @override
  final SupabaseClient client;
}

void main() {
  for (final locality in <String?>[null, '', '   ', 'Kalawad Road']) {
    test(
      'next bill persists address with locality ${jsonEncode(locality)}',
      () async {
        Map<String, dynamic>? savedAddress;
        final transport = MockClient((request) async {
          final path = request.url.path;
          Object response;
          if (path.endsWith('/document_categories')) {
            response = {'id': 'category-utility'};
          } else if (path.startsWith('/storage/v1/object/')) {
            response = {'Key': 'utility_bills/bill.pdf'};
          } else if (path.endsWith('/documents')) {
            response = {'id': 'new-bill'};
          } else if (path.endsWith('/utility_metadata')) {
            response = <Object>[];
          } else if (path.endsWith('/document_addresses')) {
            savedAddress = jsonDecode(request.body) as Map<String, dynamic>;
            response = <Object>[];
          } else {
            fail('Unexpected request: ${request.method} $path');
          }
          return http.Response(
            jsonEncode(response),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        });
        final client = SupabaseClient(
          'https://test.invalid',
          'test-key',
          httpClient: transport,
        );
        addTearDown(client.dispose);
        final dataset = UtilityBillsDataset(_TestProvider(client));

        final document = await dataset.logNextUtilityBill(
          consumerNumber: '61647126444',
          providerName: 'PGVCL',
          utilityType: 'Electricity / Light',
          premiseName: 'RK Iconic',
          flatHouseNo: 'B-1118',
          areaLocality: locality,
          city: 'Rajkot',
          title: 'Next bill',
          billAmount: 111111,
          billDate: DateTime(2026, 11, 17),
          paymentStatus: 'paid',
          fileBytes: Uint8List.fromList([37, 80, 68, 70]),
          fileName: 'bill.pdf',
        );

        expect(savedAddress, isNotNull);
        expect(
          savedAddress!['area_locality'],
          locality == 'Kalawad Road' ? locality : 'RK Iconic',
        );
        expect(savedAddress!['city'], 'Rajkot');
        expect(savedAddress!['flat_house_no'], 'B-1118');
        expect(savedAddress!['document_id'], document.id);
        expect(document.address!.areaLocality, savedAddress!['area_locality']);
      },
    );
  }
}
