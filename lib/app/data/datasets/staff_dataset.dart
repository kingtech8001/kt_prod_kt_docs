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

  Future<Map<String, int>> getRoleCounts() async {
    try {
      if (DemoDataService.isDemoMode) {
        final users = _demoStaffUsers();
        return {
          'all': users.length,
          for (final role in ['editor', 'viewer', 'user'])
            role: users.where((user) => user.role == role).length,
        };
      }
      final counts = await Future.wait([
        _client.from('profiles').count(CountOption.exact),
        for (final role in ['editor', 'viewer', 'user'])
          _client.from('profiles').count(CountOption.exact).eq('role', role),
      ]);
      return {
        'all': counts[0],
        'editor': counts[1],
        'viewer': counts[2],
        'user': counts[3],
      };
    } catch (error, stackTrace) {
      AppLogger.error(
        'STAFF_DATASET',
        'Failed to count staff roles.',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<({List<ProfileModel> users, int total})> getStaffPage({
    required int page,
    required int pageSize,
    String search = '',
    String role = 'all',
  }) async {
    try {
      if (page < 1 || pageSize < 1 || pageSize > 100) {
        throw ArgumentError('Invalid staff page bounds');
      }
      if (DemoDataService.isDemoMode) {
        final all = _demoStaffUsers();
        final query = search.trim().toLowerCase();
        final filtered = all
            .where(
              (user) =>
                  (role == 'all' || user.role == role) &&
                  (query.isEmpty ||
                      user.fullName.toLowerCase().contains(query) ||
                      user.email.toLowerCase().contains(query) ||
                      (user.department ?? '').toLowerCase().contains(query)),
            )
            .toList();
        return (
          users: filtered.skip((page - 1) * pageSize).take(pageSize).toList(),
          total: filtered.length,
        );
      }
      var query = _client.from('profiles').select();
      if (role != 'all') query = query.eq('role', role);
      // Quote the filter value so punctuation cannot add PostgREST operators.
      final term = search
          .trim()
          .replaceAll('\\', '\\\\')
          .replaceAll('"', '\\"');
      if (term.isNotEmpty) {
        query = query.or(
          'full_name.ilike."%$term%",email.ilike."%$term%",department.ilike."%$term%"',
        );
      }
      final result = await query
          .order('created_at', ascending: false)
          .order('id')
          .range((page - 1) * pageSize, page * pageSize - 1)
          .count(CountOption.exact);
      return (
        users: result.data.map(ProfileModel.fromJson).toList(),
        total: result.count,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'STAFF_DATASET',
        'Failed to fetch staff page.',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

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

  /// Small in-memory fixture; production staff access always uses getStaffPage.
  List<ProfileModel> _demoStaffUsers() {
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
      AppLogger.info(
        'STAFF_DATASET',
        '[DEMO] Simulated creating staff user: $email',
      );
      return;
    }
    AppLogger.debug(
      'STAFF_DATASET',
      'Calling RPC admin_create_staff_user for: $email ($role)',
    );

    try {
      await _client.rpc(
        'admin_create_staff_user',
        params: {
          'p_email': email,
          'p_password': password,
          'p_full_name': fullName,
          'p_role': role,
          'p_department': department,
          'p_phone_number': phoneNumber,
        },
      );

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
      AppLogger.info(
        'STAFF_DATASET',
        '[DEMO] Simulated updating user role: $targetUserId -> $role',
      );
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
        await _client.rpc(
          'admin_update_user_role',
          params: {
            'p_target_user_id': targetUserId,
            'p_role': role,
            'p_is_active': isActive,
          },
        );
      } catch (rpcErr) {
        AppLogger.warning(
          'STAFF_DATASET',
          'RPC admin_update_user_role fallback to direct update: $rpcErr',
        );
        await _client
            .from('profiles')
            .update({
              'role': role,
              'is_active': isActive,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', targetUserId);
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
