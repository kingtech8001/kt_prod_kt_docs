import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/personal_docs_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Provider extends SupabaseProvider {
  _Provider(this.client);
  @override
  final SupabaseClient client;
}

void main() {
  for (final missing in [false, true]) {
    test(
      'saves and reloads personal details (missing metadata: $missing)',
      () async {
        Map<String, dynamic> metadata = {};
        Map<String, dynamic> document = {};
        final client = SupabaseClient(
          'https://test.invalid',
          'key',
          httpClient: MockClient((request) async {
            Object response;
            if (request.method == 'GET') {
              response = {
                'extra_attributes': {
                  'storage_provider': 'supabase',
                  'renewal_count': 2,
                },
              };
            } else if (request.url.path.endsWith(
              '/personal_document_metadata',
            )) {
              metadata = jsonDecode(request.body) as Map<String, dynamic>;
              expect(
                metadata.keys,
                everyElement(
                  isIn([
                    'document_id',
                    'person_name',
                    'doc_type_name',
                    'id_number',
                    'issuing_authority',
                    'issue_date',
                    'expiry_date',
                    'notes',
                  ]),
                ),
              );
              response = request.method == 'POST'
                  ? {'document_id': 'doc'}
                  : (missing
                        ? []
                        : [
                            {'document_id': 'doc'},
                          ]);
            } else {
              document = jsonDecode(request.body) as Map<String, dynamic>;
              response = {'id': 'doc'};
            }
            return http.Response(
              jsonEncode(response),
              200,
              request: request,
              headers: {'content-type': 'application/json'},
            );
          }),
        );
        addTearDown(client.dispose);
        await PersonalDocsDataset(
          _Provider(client),
        ).updatePersonalDocumentMetadata(
          documentId: 'doc',
          title: 'PAN updated',
          description: 'Updated notes',
          personName: 'Updated person',
          relationship: 'Self',
          docTypeName: 'PAN Card',
          idNumber: 'TEST123',
          issuingAuthority: 'Authority',
          issueDate: DateTime(2026, 1, 2),
          expiryDate: null,
          insuranceCompany: 'Insurer',
          policyType: 'Health',
          sumInsured: 100000,
          premiumAmount: 5000,
          tpaName: 'TPA',
          notes: 'Policy notes',
        );
        final reloaded = DocumentModel.fromJson({
          'id': 'doc',
          ...document,
          'personal_document_metadata': metadata,
        });
        expect(reloaded.personalMetadata!.personName, 'Updated person');
        expect(reloaded.personalMetadata!.relationship, 'Self');
        expect(reloaded.personalMetadata!.idNumber, 'TEST123');
        expect(reloaded.personalMetadata!.issuingAuthority, 'Authority');
        expect(reloaded.personalMetadata!.expiryDate, isNull);
        expect(reloaded.personalMetadata!.insuranceCompany, 'Insurer');
        expect(reloaded.personalMetadata!.premiumAmount, 5000);
        expect(reloaded.personalMetadata!.renewalCount, 2);
        expect(
          (document['extra_attributes'] as Map)['storage_provider'],
          'supabase',
        );
        expect(reloaded.subCategory, 'PAN Card');
      },
    );
  }
}
