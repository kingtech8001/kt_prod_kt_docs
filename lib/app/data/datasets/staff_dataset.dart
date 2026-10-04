import 'package:kt_prod_kt_docs/app/data/models/profile_model.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/app/data/services/demo_data_service.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Dataset responsible for Staff & Role Management operations.
/// Strictly conforms to the 3-tier architecture: View -> Controller -> Dataset -> Supabase.
class StaffDataset {
  final SupabaseProvider _provider;

  StaffDataset(this._provider);

  SupabaseClient get _client => _provider.client;

  /// Fetches profile for the currently authenticated session.
  Future<ProfileModel?> getCurrentProfile() async {
    if (DemoDataService.isDemoMode) {
      return ProfileModel(
        id: 'demo-admin-id',
        fullName: 'Demo Administrator (Mihir)',
        email: 'demo@kingtechnology.com',
        role: 'admin',
        department: 'Technology (Demo)',
        phoneNumber: '+91 98765 43210',
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
      );
    }
    final user = _provider.currentUser;
    if (user == null) return null;

    AppLogger.debug('STAFF_DATASET', 'Fetching current profile for ${user.id}');
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) return null;
      return ProfileModel.fromJson(response);
    } catch (e, st) {
      AppLogger.error(
        'STAFF_DATASET',
        'Error fetching current profile: $e',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Fetches all staff users via RPC `admin_get_all_users` with table query fallback.
  Future<List<ProfileModel>> getAllStaffUsers() async {
    if (DemoDataService.isDemoMode) {
      return [
        ProfileModel(
          id: 'staff-demo-1',
          fullName: 'Mihir Gandhi',
          email: 'mihir@kingtechnology.com',
          role: 'admin',
          department: 'Technology & Management',
          phoneNumber: '+91 98765 43210',
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 365)),
        ),
        ProfileModel(
          id: 'staff-demo-2',
          fullName: 'Darshit Gandhi',
          email: 'darshit@kingtechnology.com',
          role: 'editor',
          department: 'Operations',
          phoneNumber: '+91 98765 12345',
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 200)),
        ),
        ProfileModel(
          id: 'staff-demo-3',
          fullName: 'Pooja Patel',
          email: 'pooja@kingtechnology.com',
          role: 'viewer',
          department: 'Finance & Accounts',
          phoneNumber: '+91 91234 56789',
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 90)),
        ),
      ];
    }
    AppLogger.debug('STAFF_DATASET', 'Fetching all staff users via RPC admin_get_all_users...');
    try {
      final response = await _client.rpc('admin_get_all_users');
      final list = (response as List)
          .map((json) => ProfileModel.fromJson(json as Map<String, dynamic>))
          .toList();
      AppLogger.info('STAFF_DATASET', 'RPC fetched ${list.length} staff profiles.');
      return list;
    } catch (rpcErr) {
      AppLogger.warning(
        'STAFF_DATASET',
        'RPC admin_get_all_users fallback to direct query: $rpcErr',
      );
    }

    // Direct table fallback
    try {
      final response = await _client
          .from('profiles')
          .select()
          .order('created_at', ascending: false);

      final list = (response as List)
          .map((json) => ProfileModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e, st) {
      AppLogger.error(
        'STAFF_DATASET',
        'Error in getAllStaffUsers fallback: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Provisions a new staff account via RPC `admin_create_staff_user`.
  Future<void> createStaffUser({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? department,
    String? phoneNumber,
  }) async {
    if (DemoDataService.isDemoMode) {
      AppLogger.info('STAFF_DATASET', '[DEMO] Simulated creating staff user: $email');
      return;
    }
    AppLogger.debug(
      'STAFF_DATASET',
      'Calling RPC admin_create_staff_user for: $email ($role)',
    );

    try {
      await _client.rpc('admin_create_staff_user', params: {
        'p_email': email,
        'p_password': password,
        'p_full_name': fullName,
        'p_role': role,
        'p_department': department,
        'p_phone_number': phoneNumber,
      });

      AppLogger.info(
        'STAFF_DATASET',
        'Staff user for "$role" ($email) provisioned successfully.',
      );
    } catch (e, st) {
      AppLogger.error(
        'STAFF_DATASET',
        'Error in admin_create_staff_user: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Updates user role or active status via RPC `admin_update_user_role`.
  Future<void> updateUserRole({
    required String targetUserId,
    required String role,
    required bool isActive,
  }) async {
    if (DemoDataService.isDemoMode) {
      AppLogger.info('STAFF_DATASET', '[DEMO] Simulated updating user role: $targetUserId -> $role');
      return;
    }
    final currentUserId = _provider.currentUser?.id;
    if (currentUserId != null && currentUserId == targetUserId) {
      AppLogger.warning(
        'STAFF_DATASET',
        'Self-role modification blocked for user: $targetUserId',
      );
      throw Exception('You cannot modify your own role or account status.');
    }

    AppLogger.debug(
      'STAFF_DATASET',
      'Calling RPC admin_update_user_role for $targetUserId -> $role (active: $isActive)',
    );

    try {
      try {
        await _client.rpc('admin_update_user_role', params: {
          'p_target_user_id': targetUserId,
          'p_role': role,
          'p_is_active': isActive,
        });
      } catch (rpcErr) {
        AppLogger.warning(
          'STAFF_DATASET',
          'RPC admin_update_user_role fallback to direct update: $rpcErr',
        );
        await _client.from('profiles').update({
          'role': role,
          'is_active': isActive,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', targetUserId);
      }

      AppLogger.info(
        'STAFF_DATASET',
        'Staff role/status for $targetUserId updated successfully.',
      );
    } catch (e, st) {
      AppLogger.error(
        'STAFF_DATASET',
        'Error in updateUserRole: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
