import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/staff_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/models/profile_model.dart';
import 'package:kt_prod_kt_docs/app/widgets/create_staff_dialog.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/utils/app_snackbar.dart';

class UsersController extends GetxController {
  final StaffDataset _dataset;

  UsersController(this._dataset);

  final isLoading = true.obs;
  final currentProfile = Rxn<ProfileModel>();
  final allUsers = <ProfileModel>[].obs;

  // Filter & Search
  final searchQuery = ''.obs;
  final selectedRoleFilter = 'all'.obs; // 'all', 'editor', 'viewer', 'user', 'admin'

  // Metrics
  final totalUsersCount = 0.obs;
  final editorCount = 0.obs;
  final viewerCount = 0.obs;
  final standardUserCount = 0.obs;

  bool get isCurrentUserAdmin =>
      currentProfile.value?.role == 'admin' ||
      currentProfile.value?.role == 'super_admin';

  @override
  void onInit() {
    super.onInit();
    loadUsers();
  }

  Future<void> loadUsers() async {
    AppLogger.debug('USERS_CTRL', 'Loading staff users and roles...');
    isLoading.value = true;
    try {
      final p = await _dataset.getCurrentProfile();
      currentProfile.value = p;

      final users = await _dataset.getAllStaffUsers();
      allUsers.assignAll(users);

      _computeRoleMetrics(users);
      AppLogger.info('USERS_CTRL', 'Loaded ${users.length} staff profiles.');
    } catch (e, st) {
      AppLogger.error(
        'USERS_CTRL',
        'Error loading staff users: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Error Loading Staff Users', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void _computeRoleMetrics(List<ProfileModel> users) {
    int total = users.length;
    int editors = 0;
    int viewers = 0;
    int stdUsers = 0;

    for (var u in users) {
      if (u.role == 'editor') editors++;
      if (u.role == 'viewer') viewers++;
      if (u.role == 'user') stdUsers++;
    }

    totalUsersCount.value = total;
    editorCount.value = editors;
    viewerCount.value = viewers;
    standardUserCount.value = stdUsers;
  }

  List<ProfileModel> get filteredUsers {
    var list = allUsers.toList();

    if (selectedRoleFilter.value != 'all') {
      list = list
          .where(
            (u) =>
                u.role.toLowerCase() ==
                selectedRoleFilter.value.toLowerCase(),
          )
          .toList();
    }

    if (searchQuery.value.trim().isNotEmpty) {
      final q = searchQuery.value.trim().toLowerCase();
      list = list.where((u) {
        return u.fullName.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q) ||
            (u.department ?? '').toLowerCase().contains(q);
      }).toList();
    }

    return list;
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
  }

  void onRoleFilterSelected(String role) {
    selectedRoleFilter.value = role;
  }

  /// Opens the CreateStaffDialog which handles in-context validation and submission errors.
  Future<void> openCreateProfileDialog() async {
    final success = await CreateStaffDialog.show(
      onSubmit: ({
        required email,
        required password,
        required fullName,
        required role,
        department,
        phoneNumber,
      }) async {
        await _dataset.createStaffUser(
          email: email,
          password: password,
          fullName: fullName,
          role: role,
          department: department,
          phoneNumber: phoneNumber,
        );
      },
    );

    if (success == true) {
      AppSnackbar.showSuccess(
        'Profile Created',
        'Staff profile created successfully.',
      );
      loadUsers();
    }
  }

  Future<void> updateUserRole(ProfileModel targetUser, String newRole) async {
    if (targetUser.id == currentProfile.value?.id) {
      AppSnackbar.showWarning(
        'Action Restricted',
        'You cannot change your own role.',
      );
      return;
    }

    AppLogger.debug(
      'USERS_CTRL',
      'Changing role for ${targetUser.fullName} to $newRole',
    );
    try {
      await _dataset.updateUserRole(
        targetUserId: targetUser.id,
        role: newRole,
        isActive: targetUser.isActive,
      );

      AppSnackbar.showSuccess(
        'Role Updated',
        '${targetUser.fullName} role changed to ${newRole.toUpperCase()}',
      );

      loadUsers();
    } catch (e, st) {
      AppLogger.error(
        'USERS_CTRL',
        'Failed to update role: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Role Update Failed', e.toString());
    }
  }

  Future<void> toggleUserStatus(ProfileModel targetUser) async {
    if (targetUser.id == currentProfile.value?.id) {
      AppSnackbar.showWarning(
        'Action Restricted',
        'You cannot change your own account status.',
      );
      return;
    }

    try {
      final newStatus = !targetUser.isActive;
      await _dataset.updateUserRole(
        targetUserId: targetUser.id,
        role: targetUser.role,
        isActive: newStatus,
      );

      AppSnackbar.showSuccess(
        'Status Changed',
        '${targetUser.fullName} is now ${newStatus ? "ACTIVE" : "INACTIVE"}',
      );

      loadUsers();
    } catch (e, st) {
      AppLogger.error(
        'USERS_CTRL',
        'Failed to toggle status: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Status Update Failed', e.toString());
    }
  }
}
