import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/modules/profile/controllers/profile_controller.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/app/widgets/status_badge.dart';
import 'package:kt_prod_kt_docs/app/widgets/web_scaffold.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      title: 'My Profile & Account Settings',
      subtitle: 'Manage your personal staff details, department, contact info, and account security',
      currentRoute: AppRoutes.PROFILE,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final p = controller.profile.value;
        final displayName = p?.fullName.isNotEmpty == true ? p!.fullName : 'User Profile';
        final email = p?.email ?? 'user@kingtech.com';
        final role = p?.role.toUpperCase() ?? 'STAFF';
        final department = p?.department?.isNotEmpty == true ? p!.department! : 'Executive';
        final phone = p?.phoneNumber?.isNotEmpty == true ? p!.phoneNumber! : 'Not set';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Overview Header Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    displayName,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  StatusBadge(
                                    label: role,
                                    type: (role == 'ADMIN' || role == 'SUPER_ADMIN')
                                        ? StatusBadgeType.warning
                                        : StatusBadgeType.info,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                email,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 16,
                                runSpacing: 8,
                                children: [
                                  _buildInfoChip(Icons.business_outlined, 'Dept: $department'),
                                  _buildInfoChip(Icons.phone_outlined, 'Phone: $phone'),
                                  _buildInfoChip(
                                    Icons.verified_user_outlined,
                                    p?.isActive == true ? 'Account Active' : 'Account Suspended',
                                    isSuccess: p?.isActive == true,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Forms Grid / Columns
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 700;

                      final editProfileCard = Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.person_outline, color: AppColors.primary, size: 22),
                                SizedBox(width: 10),
                                Text(
                                  'Personal Information',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Update your official name, department title, and contact phone number.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const Divider(height: 24),
                            const Text('Full Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: controller.fullNameController,
                              decoration: const InputDecoration(hintText: 'Your full name'),
                            ),
                            const SizedBox(height: 16),
                            const Text('Department / Role Title', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: controller.departmentController,
                              decoration: const InputDecoration(hintText: 'e.g. Executive, IT, Accounts, Operations'),
                            ),
                            const SizedBox(height: 16),
                            const Text('Phone Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: controller.phoneController,
                              decoration: const InputDecoration(hintText: '+91 9876543210'),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: controller.isSavingProfile.value ? null : controller.saveProfile,
                                icon: controller.isSavingProfile.value
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Icon(Icons.check, size: 18),
                                label: const Text('Save Profile Changes'),
                              ),
                            ),
                          ],
                        ),
                      );

                      final securityCard = Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.lock_outline, color: AppColors.primary, size: 22),
                                SizedBox(width: 10),
                                Text(
                                  'Security & Password',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Change your login password. Must be at least 6 characters.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const Divider(height: 24),
                            const Text('New Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Obx(() => TextField(
                                  controller: controller.newPasswordController,
                                  obscureText: controller.obscureNewPassword.value,
                                  decoration: InputDecoration(
                                    hintText: 'Enter new password',
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        controller.obscureNewPassword.value
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 18,
                                      ),
                                      onPressed: () => controller.obscureNewPassword.value =
                                          !controller.obscureNewPassword.value,
                                    ),
                                  ),
                                )),
                            const SizedBox(height: 16),
                            const Text('Confirm New Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Obx(() => TextField(
                                  controller: controller.confirmPasswordController,
                                  obscureText: controller.obscureConfirmPassword.value,
                                  decoration: InputDecoration(
                                    hintText: 'Confirm new password',
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        controller.obscureConfirmPassword.value
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 18,
                                      ),
                                      onPressed: () => controller.obscureConfirmPassword.value =
                                          !controller.obscureConfirmPassword.value,
                                    ),
                                  ),
                                )),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark),
                                onPressed: controller.isChangingPassword.value ? null : controller.changePassword,
                                icon: controller.isChangingPassword.value
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Icon(Icons.key, size: 18),
                                label: const Text('Update Password'),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: editProfileCard),
                            const SizedBox(width: 24),
                            Expanded(child: securityCard),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            editProfileCard,
                            const SizedBox(height: 24),
                            securityCard,
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, {bool isSuccess = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSuccess ? AppColors.success.withValues(alpha: 0.1) : AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isSuccess ? AppColors.success.withValues(alpha: 0.3) : AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isSuccess ? AppColors.success : AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSuccess ? AppColors.success : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
