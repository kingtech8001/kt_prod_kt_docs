import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/profile_model.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/auth_repository.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';

class UsersController extends GetxController {
  final AuthRepository _authRepository;

  UsersController(this._authRepository);

  final isLoading = true.obs;
  final currentProfile = Rxn<ProfileModel>();
  final allUsers = <ProfileModel>[].obs;

  // Filter & Search
  final searchQuery = ''.obs;
  final selectedRoleFilter = 'all'.obs; // 'all', 'editor', 'viewer', 'user', 'admin'

  // Form Fields for "Create Profile for Role"
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final departmentController = TextEditingController();
  final phoneController = TextEditingController();
  final selectedRole = 'editor'.obs; // 'editor', 'viewer', 'user', 'admin'

  // Metrics
  final totalUsersCount = 0.obs;
  final editorCount = 0.obs;
  final viewerCount = 0.obs;
  final standardUserCount = 0.obs;

  bool get isCurrentUserAdmin =>
      currentProfile.value?.role == 'admin' || currentProfile.value?.role == 'super_admin';

  @override
  void onInit() {
    super.onInit();
    loadUsers();
  }

  Future<void> loadUsers() async {
    AppLogger.debug('USERS_CTRL', 'Loading staff users and roles...');
    isLoading.value = true;
    try {
      final p = await _authRepository.getCurrentProfile();
      currentProfile.value = p;

      final users = await _authRepository.adminGetAllStaffUsers();
      allUsers.assignAll(users);

      _computeRoleMetrics(users);
      AppLogger.info('USERS_CTRL', 'Loaded ${users.length} staff profiles.');
    } catch (e, st) {
      AppLogger.error('USERS_CTRL', 'Error loading staff users: $e', error: e, stackTrace: st);
      Get.snackbar(
        'Error Loading Staff Users',
        e.toString(),
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
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
      list = list.where((u) => u.role.toLowerCase() == selectedRoleFilter.value.toLowerCase()).toList();
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

  void openCreateProfileDialog() {
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    departmentController.clear();
    phoneController.clear();
    selectedRole.value = 'editor';

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.person_add_alt_1_outlined, color: AppColors.primary, size: 24),
            SizedBox(width: 10),
            Text(
              'Create Profile for Role',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Provision a new staff profile with a dedicated role and system access level.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                const Text('Full Name *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Rahul Sharma',
                    prefixIcon: Icon(Icons.person_outline, size: 18),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Work Email *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'user@kingtechnology.com',
                    prefixIcon: Icon(Icons.email_outlined, size: 18),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Initial Password *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    hintText: 'Temporary password for first login',
                    prefixIcon: Icon(Icons.lock_outline, size: 18),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Department', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: departmentController,
                            decoration: const InputDecoration(
                              hintText: 'Operations / IT / HR',
                              prefixIcon: Icon(Icons.business_outlined, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Phone Number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: phoneController,
                            decoration: const InputDecoration(
                              hintText: '+91 9876543210',
                              prefixIcon: Icon(Icons.phone_outlined, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Assigned Role & Permissions *',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                Obx(() => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedRole.value,
                          items: const [
                            DropdownMenuItem(
                              value: 'editor',
                              child: Text('Editor (Upload, edit metadata, view all docs)'),
                            ),
                            DropdownMenuItem(
                              value: 'viewer',
                              child: Text('Viewer (Read-only, preview PDFs & images)'),
                            ),
                            DropdownMenuItem(
                              value: 'user',
                              child: Text('Standard User (Personal view access)'),
                            ),
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('Admin (Full management & staff creation)'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) selectedRole.value = val;
                          },
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: submitCreateProfile,
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Create Profile'),
          ),
        ],
      ),
    );
  }

  Future<void> submitCreateProfile() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final department = departmentController.text.trim();
    final phone = phoneController.text.trim();
    final role = selectedRole.value;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Required Fields Missing',
        'Please enter Full Name, Work Email, and Initial Password.',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    if (!GetUtils.isEmail(email)) {
      Get.snackbar(
        'Invalid Email',
        'Please provide a valid work email address.',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    Get.back(); // close dialog
    isLoading.value = true;
    try {
      await _authRepository.adminCreateStaffUser(
        email: email,
        password: password,
        fullName: name,
        role: role,
        department: department.isNotEmpty ? department : null,
        phoneNumber: phone.isNotEmpty ? phone : null,
      );

      Get.snackbar(
        'Profile Created',
        'Staff profile for "$name" ($role) created successfully.',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );

      loadUsers();
    } catch (e, st) {
      AppLogger.error('USERS_CTRL', 'Failed to create staff profile: $e', error: e, stackTrace: st);
      Get.snackbar(
        'Profile Creation Failed',
        e.toString(),
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      isLoading.value = false;
    }
  }

  Future<void> updateUserRole(ProfileModel targetUser, String newRole) async {
    AppLogger.debug('USERS_CTRL', 'Changing role for ${targetUser.fullName} to $newRole');
    try {
      await _authRepository.adminUpdateUserRole(
        targetUserId: targetUser.id,
        role: newRole,
        isActive: targetUser.isActive,
      );

      Get.snackbar(
        'Role Updated',
        '${targetUser.fullName} role changed to ${newRole.toUpperCase()}',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );

      loadUsers();
    } catch (e, st) {
      AppLogger.error('USERS_CTRL', 'Failed to update role: $e', error: e, stackTrace: st);
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  Future<void> toggleUserStatus(ProfileModel targetUser) async {
    try {
      await _authRepository.adminUpdateUserRole(
        targetUserId: targetUser.id,
        role: targetUser.role,
        isActive: !targetUser.isActive,
      );

      Get.snackbar(
        'Status Changed',
        '${targetUser.fullName} is now ${!targetUser.isActive ? "ACTIVE" : "INACTIVE"}',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );

      loadUsers();
    } catch (e, st) {
      AppLogger.error('USERS_CTRL', 'Failed to toggle status: $e', error: e, stackTrace: st);
      Get.snackbar('Error', e.toString(), backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    departmentController.dispose();
    phoneController.dispose();
    super.onClose();
  }
}
