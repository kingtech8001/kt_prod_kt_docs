import 'package:kt_prod_kt_docs/app/data/models/profile_model.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/app/data/services/demo_data_service.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseProvider _provider;

  AuthRepository(this._provider);

  User? get currentUser => _provider.currentUser;

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    AppLogger.debug('AUTH_REPO', 'Attempting signInWithEmail for: $email');
    try {
      final response = await _provider.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      AppLogger.info(
        'AUTH_REPO',
        'signInWithEmail success for user ID: ${response.user?.id}, Session: ${response.session != null}',
      );
      return response;
    } on AuthException catch (ae, st) {
      AppLogger.error(
        'AUTH_REPO',
        'AuthException during signInWithEmail: ${ae.message} (statusCode: ${ae.statusCode})',
        error: ae,
        stackTrace: st,
        contextData: {'email': email},
      );
      rethrow;
    } catch (e, st) {
      AppLogger.error(
        'AUTH_REPO',
        'Unexpected exception during signInWithEmail: $e',
        error: e,
        stackTrace: st,
        contextData: {'email': email},
      );
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (DemoDataService.isDemoMode) {
      AppLogger.info('AUTH_REPO', '[DEMO] Exiting demo session.');
      return;
    }
    AppLogger.debug('AUTH_REPO', 'Signing out currentUser: ${currentUser?.id}');
    try {
      await _provider.client.auth.signOut();
      AppLogger.info('AUTH_REPO', 'User signed out successfully.');
    } catch (e, st) {
      AppLogger.error('AUTH_REPO', 'Error during signOut: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

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
    AppLogger.debug('AUTH_REPO', 'Fetching profile for user: ${user?.id} (${user?.email})');
    if (user == null) {
      AppLogger.warning('AUTH_REPO', 'Cannot get profile because currentUser is null');
      return null;
    }

    try {
      final response = await _provider.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        AppLogger.warning(
          'AUTH_REPO',
          'Profile not found in "profiles" table for user ${user.id}. Creating fallback profile...',
        );
        final newProfile = {
          'id': user.id,
          'full_name': user.userMetadata?['full_name'] ??
              user.email?.split('@').first ??
              'User',
          'email': user.email ?? '',
          'role': 'admin',
        };
        final created = await _provider.client
            .from('profiles')
            .insert(newProfile)
            .select()
            .single();
        AppLogger.info('AUTH_REPO', 'Fallback profile created successfully:', created);
        return ProfileModel.fromJson(created);
      }

      AppLogger.info('AUTH_REPO', 'Loaded profile for: ${response["full_name"]} (${response["role"]})');
      return ProfileModel.fromJson(response);
    } on PostgrestException catch (pe, st) {
      AppLogger.error(
        'AUTH_REPO',
        'PostgrestException during getCurrentProfile: ${pe.message} (code: ${pe.code}, details: ${pe.details}, hint: ${pe.hint})',
        error: pe,
        stackTrace: st,
        contextData: {'userId': user.id},
      );
      return ProfileModel(
        id: user.id,
        fullName: user.userMetadata?['full_name'] ?? user.email?.split('@').first ?? 'User',
        email: user.email ?? '',
        role: 'admin',
        createdAt: DateTime.now(),
      );
    } catch (e, st) {
      AppLogger.error('AUTH_REPO', 'Error in getCurrentProfile: $e', error: e, stackTrace: st);
      return null;
    }
  }

  Future<void> updateProfile({
    required String fullName,
    String? department,
    String? phoneNumber,
  }) async {
    if (DemoDataService.isDemoMode) {
      AppLogger.info('AUTH_REPO', '[DEMO] Simulated profile update: $fullName');
      return;
    }
    final user = _provider.currentUser;
    if (user == null) return;
    AppLogger.debug('AUTH_REPO', 'Updating profile for user ${user.id}');

    try {
      await _provider.client.from('profiles').update({
        'full_name': fullName,
        'department': department,
        'phone_number': phoneNumber,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
      AppLogger.info('AUTH_REPO', 'Profile updated successfully.');
    } catch (e, st) {
      AppLogger.error('AUTH_REPO', 'Error in updateProfile: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> updateStaffProfile({
    required String id,
    required String fullName,
    String? department,
    String? phoneNumber,
    required bool isActive,
  }) async {
    if (DemoDataService.isDemoMode) {
      AppLogger.info('AUTH_REPO', '[DEMO] Simulated staff profile update: $id');
      return;
    }
    AppLogger.debug('AUTH_REPO', 'Updating staff profile for user $id');
    try {
      await _provider.client.from('profiles').update({
        'full_name': fullName,
        'department': department,
        'phone_number': phoneNumber,
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
      AppLogger.info('AUTH_REPO', 'Staff profile updated successfully.');
    } catch (e, st) {
      AppLogger.error('AUTH_REPO', 'Error in updateStaffProfile: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  // Admin User & Role Creation Methods
  Future<void> adminCreateStaffUser({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? department,
    String? phoneNumber,
  }) async {
    if (DemoDataService.isDemoMode) {
      AppLogger.info('AUTH_REPO', '[DEMO] Simulated adminCreateStaffUser: $email');
      return;
    }
    AppLogger.debug('AUTH_REPO', 'adminCreateStaffUser for: $email ($role)');
    try {
      await _provider.client.rpc('admin_create_staff_user', params: {
        'p_email': email,
        'p_password': password,
        'p_full_name': fullName,
        'p_role': role,
        'p_department': department,
        'p_phone_number': phoneNumber,
      });
      AppLogger.info('AUTH_REPO', 'Staff profile for role "$role" ($email) created successfully.');
    } catch (e, st) {
      AppLogger.error('AUTH_REPO', 'Error in adminCreateStaffUser: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<List<ProfileModel>> adminGetAllStaffUsers() async {
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
      ];
    }
    AppLogger.debug('AUTH_REPO', 'adminGetAllStaffUsers...');
    try {
      final response = await _provider.client.rpc('admin_get_all_users');
      final list = (response as List)
          .map((json) => ProfileModel.fromJson(json as Map<String, dynamic>))
          .toList();
      AppLogger.info('AUTH_REPO', 'Fetched ${list.length} staff profiles.');
      return list;
    } catch (e, st) {
      AppLogger.error('AUTH_REPO', 'Error in adminGetAllStaffUsers: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> adminUpdateUserRole({
    required String targetUserId,
    required String role,
    required bool isActive,
  }) async {
    if (DemoDataService.isDemoMode) {
      AppLogger.info('AUTH_REPO', '[DEMO] Simulated adminUpdateUserRole: $targetUserId -> $role');
      return;
    }
    AppLogger.debug('AUTH_REPO', 'adminUpdateUserRole for $targetUserId -> $role (active: $isActive)');
    try {
      await _provider.client.rpc('admin_update_user_role', params: {
        'p_target_user_id': targetUserId,
        'p_role': role,
        'p_is_active': isActive,
      });
      AppLogger.info('AUTH_REPO', 'Updated user role for $targetUserId successfully.');
    } catch (e, st) {
      AppLogger.error('AUTH_REPO', 'Error in adminUpdateUserRole: $e', error: e, stackTrace: st);
      rethrow;
    }
  }
}
