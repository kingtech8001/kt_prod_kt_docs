import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/core/utils/app_dialog.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';

/// Modal dialog for provisioning a staff user with strict in-context validation and error handling.
/// 100% GetX-compliant, zero setState, responsive BoxConstraints.
class CreateStaffDialog extends StatelessWidget {
  final Future<void> Function({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? department,
    String? phoneNumber,
  }) onSubmit;

  final TextEditingController _nameController;
  final TextEditingController _emailController;
  final TextEditingController _passwordController;
  final TextEditingController _departmentController;
  final TextEditingController _phoneController;

  final RxString _selectedRole = 'editor'.obs;
  final RxBool _isSubmitting = false.obs;
  final RxString _errorMessage = ''.obs;

  CreateStaffDialog({super.key, required this.onSubmit})
      : _nameController = TextEditingController(),
        _emailController = TextEditingController(),
        _passwordController = TextEditingController(),
        _departmentController = TextEditingController(),
        _phoneController = TextEditingController();

  static Future<bool?> show({
    required Future<void> Function({
      required String email,
      required String password,
      required String fullName,
      required String role,
      String? department,
      String? phoneNumber,
    }) onSubmit,
  }) {
    return AppDialog.show<bool>(
      CreateStaffDialog(onSubmit: onSubmit),
      barrierDismissible: false,
    );
  }

  void _disposeControllers() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _departmentController.dispose();
    _phoneController.dispose();
  }

  Future<void> _handleSubmit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final department = _departmentController.text.trim();
    final phone = _phoneController.text.trim();

    // In-context field validations (Rule 3.B)
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _errorMessage.value =
          'Please enter Full Name, Work Email, and Initial Password.';
      return;
    }

    if (!GetUtils.isEmail(email)) {
      _errorMessage.value = 'Please provide a valid work email address.';
      return;
    }

    if (password.length < 6) {
      _errorMessage.value = 'Password must be at least 6 characters long.';
      return;
    }

    _isSubmitting.value = true;
    _errorMessage.value = '';

    try {
      await onSubmit(
        email: email,
        password: password,
        fullName: name,
        role: _selectedRole.value,
        department: department.isNotEmpty ? department : null,
        phoneNumber: phone.isNotEmpty ? phone : null,
      );
      _disposeControllers();
      // Close dialog only after successful creation
      Get.back(result: true);
    } catch (e) {
      // In-context error display (Rule 3.B: keep dialog open)
      _errorMessage.value = e.toString().replaceAll('Exception:', '').trim();
    } finally {
      _isSubmitting.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      ),
      backgroundColor: AppColors.surface,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.sizeOf(context).height * 0.90,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.person_add_alt_1_outlined,
                          color: AppColors.primary, size: 24),
                      SizedBox(width: 10),
                      Text(
                        'Create Profile for Role',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  Obx(
                    () => IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      color: AppColors.textSecondary,
                      splashRadius: 18,
                      onPressed: _isSubmitting.value
                          ? null
                          : () {
                              _disposeControllers();
                              Get.back();
                            },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Provision a new staff profile with a dedicated role and system access level.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),

              // Inline Error Banner (Rule 3.B)
              Obx(() {
                if (_errorMessage.value.isEmpty) return const SizedBox.shrink();
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage.value,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 16),

              // Scrollable Form Fields
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Full Name *',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      Obx(
                        () => TextField(
                          controller: _nameController,
                          enabled: !_isSubmitting.value,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Rahul Sharma',
                            prefixIcon: Icon(Icons.person_outline, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text('Work Email *',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      Obx(
                        () => TextField(
                          controller: _emailController,
                          enabled: !_isSubmitting.value,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'user@kingtechnology.com',
                            prefixIcon: Icon(Icons.email_outlined, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text('Initial Password *',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      Obx(
                        () => TextField(
                          controller: _passwordController,
                          enabled: !_isSubmitting.value,
                          obscureText: true,
                          decoration: const InputDecoration(
                            hintText: 'Temporary password for first login',
                            prefixIcon: Icon(Icons.lock_outline, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Department',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                const SizedBox(height: 6),
                                Obx(
                                  () => TextField(
                                    controller: _departmentController,
                                    enabled: !_isSubmitting.value,
                                    decoration: const InputDecoration(
                                      hintText: 'Operations / IT / HR',
                                      prefixIcon: Icon(Icons.business_outlined, size: 18),
                                    ),
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
                                const Text('Phone Number',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                const SizedBox(height: 6),
                                Obx(
                                  () => TextField(
                                    controller: _phoneController,
                                    enabled: !_isSubmitting.value,
                                    decoration: const InputDecoration(
                                      hintText: '+91 9876543210',
                                      prefixIcon: Icon(Icons.phone_outlined, size: 18),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Assigned Role & Permissions *',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: Obx(
                            () => DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedRole.value,
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
                              onChanged: _isSubmitting.value
                                  ? null
                                  : (val) {
                                      if (val != null) {
                                        _selectedRole.value = val;
                                      }
                                    },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Obx(
                    () => OutlinedButton(
                      onPressed: _isSubmitting.value
                          ? null
                          : () {
                              _disposeControllers();
                              Get.back();
                            },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Obx(
                    () => ElevatedButton(
                      onPressed: _isSubmitting.value ? null : _handleSubmit,
                      child: _isSubmitting.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check, size: 16),
                                SizedBox(width: 6),
                                Text('Create Profile'),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
