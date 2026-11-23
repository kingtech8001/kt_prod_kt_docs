import 'package:get/get.dart';
import 'dart:async';
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
  final currentPage = 1.obs;
  final pageSize = 25.obs;
  final totalCount = 0.obs;
  final isLoadingMore = false.obs;
  int _requestId = 0;
  Timer? _searchTimer;

  @override
  void onClose() {
    _searchTimer?.cancel();
    _requestId++;
    super.onClose();
  }

  bool get hasMore => currentPage.value * pageSize.value < totalCount.value;
  int get totalPages =>
      (totalCount.value / pageSize.value).ceil().clamp(1, 1000000);
  String get pageLabel =>
      '${currentPage.value} / $totalPages (${totalCount.value})';

  Future<void> changePage(int page, {bool append = false}) async {
    if (page < 1 || page > totalPages || isLoadingMore.value) return;
    currentPage.value = page;
    await loadUsers(append: append);
  }

  Future<void> changePageSize(int size) async {
    pageSize.value = size;
    currentPage.value = 1;
    await loadUsers();
  }

  // Filter & Search
  final searchQuery = ''.obs;
  final selectedRoleFilter =
      'all'.obs; // 'all', 'editor', 'viewer', 'user', 'admin'

  // Metrics
  final totalUsersCount = 0.obs;
  final editorCount = 0.obs;
  final viewerCount = 0.obs;
  final standardUserCount = 0.obs;

  bool get isCurrentUserAdmin =>
      currentProfile.value?.isActive == true &&
      (currentProfile.value?.role == 'admin' ||
          currentProfile.value?.role == 'super_admin');

  @override
  void onInit() {
    super.onInit();
    loadUsers();
  }

  Future<void> loadUsers({bool append = false}) async {
    final requestId = ++_requestId;
    AppLogger.debug('USERS_CTRL', 'Loading staff users and roles...');
    if (append) {
      isLoadingMore.value = true;
    } else {
      isLoading.value = true;
    }
    try {
      final p = await _dataset.getCurrentProfile();
      currentProfile.value = p;

      final result = await _dataset.getStaffPage(
        page: currentPage.value,
        pageSize: pageSize.value,
        search: searchQuery.value,
        role: selectedRoleFilter.value,
      );
      final counts = await _dataset.getRoleCounts();
      if (requestId != _requestId) return;
      if (append) {
        allUsers.addAll(result.users);
      } else {
        allUsers.assignAll(result.users);
      }
      totalCount.value = result.total;
      totalUsersCount.value = counts['all'] ?? 0;
      editorCount.value = counts['editor'] ?? 0;
      viewerCount.value = counts['viewer'] ?? 0;
      standardUserCount.value = counts['user'] ?? 0;
    } catch (e, st) {
      AppLogger.error(
        'USERS_CTRL',
        'Error loading staff users: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Error Loading Staff Users', e.toString());
    } finally {
      if (requestId == _requestId) {
        isLoading.value = false;
        isLoadingMore.value = false;
      }
    }
  }

  List<ProfileModel> get filteredUsers => allUsers.toList();

  void onSearchChanged(String query) {
    searchQuery.value = query;
    currentPage.value = 1;
    _requestId++;
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 300), loadUsers);
  }

  void onRoleFilterSelected(String role) {
    _searchTimer?.cancel();
    selectedRoleFilter.value = role;
    currentPage.value = 1;
    loadUsers();
  }

  /// Opens the CreateStaffDialog which handles in-context validation and submission errors.
  Future<void> openCreateProfileDialog() async {
    if (!isCurrentUserAdmin) return;
    final success = await CreateStaffDialog.show(
      onSubmit:
          ({
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
    if (!isCurrentUserAdmin) return;
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
    if (!isCurrentUserAdmin) return;
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
