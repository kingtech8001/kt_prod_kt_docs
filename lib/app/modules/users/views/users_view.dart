import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/profile_model.dart';
import 'package:kt_prod_kt_docs/app/modules/users/controllers/users_controller.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/app/widgets/metric_card.dart';
import 'package:kt_prod_kt_docs/app/widgets/status_badge.dart';
import 'package:kt_prod_kt_docs/app/widgets/web_scaffold.dart';
import 'package:kt_prod_kt_docs/core/utils/app_formatters.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';

class UsersView extends GetView<UsersController> {
  const UsersView({super.key});

  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      title: 'Staff & Role Management',
      subtitle: 'Provision user profiles, assign operational roles, and manage company access',
      currentRoute: AppRoutes.USERS,
      headerActions: [
        ElevatedButton.icon(
          onPressed: controller.openCreateProfileDialog,
          icon: const Icon(Icons.person_add_alt_1_outlined, size: 16),
          label: const Text('Create Profile for Role'),
        ),
        const SizedBox(width: 12),
      ],
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final users = controller.filteredUsers;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Role Distribution Metrics Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  int crossAxis = 4;
                  if (width < 600) {
                    crossAxis = 1;
                  } else if (width < 950) {
                    crossAxis = 2;
                  }

                  final items = [
                    MetricCard(
                      title: 'TOTAL PROFILES',
                      value: '${controller.totalUsersCount.value}',
                      icon: Icons.people_outline,
                      accentColor: AppColors.primary,
                    ),
                    MetricCard(
                      title: 'EDITORS',
                      value: '${controller.editorCount.value}',
                      subtitle: 'Upload & manage documents',
                      icon: Icons.edit_note_outlined,
                      accentColor: AppColors.financeBlue,
                    ),
                    MetricCard(
                      title: 'VIEWERS',
                      value: '${controller.viewerCount.value}',
                      subtitle: 'Read-only preview access',
                      icon: Icons.visibility_outlined,
                      accentColor: AppColors.warrantyEmerald,
                    ),
                    MetricCard(
                      title: 'STANDARD USERS',
                      value: '${controller.standardUserCount.value}',
                      subtitle: 'Personal viewing',
                      icon: Icons.person_outline,
                      accentColor: AppColors.textSecondary,
                    ),
                  ];

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxis,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      mainAxisExtent: 110,
                    ),
                    itemBuilder: (context, index) => items[index],
                  );
                },
              ),

              const SizedBox(height: 24),

              // 2. Filter & Action Toolbar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 650;

                    final searchInput = SizedBox(
                      width: isCompact ? double.infinity : 280,
                      height: 38,
                      child: TextField(
                        onChanged: controller.onSearchChanged,
                        decoration: const InputDecoration(
                          hintText: 'Search by name, email, department...',
                          prefixIcon: Icon(Icons.search, size: 16, color: AppColors.textMuted),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                      ),
                    );

                    final roleFilters = Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: ['all', 'editor', 'viewer', 'user', 'admin'].map((role) {
                        final isSelected = controller.selectedRoleFilter.value == role;
                        final label = role == 'all' ? 'All Roles' : role.toUpperCase();

                        return ChoiceChip(
                          label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary),
                          onSelected: (_) => controller.onRoleFilterSelected(role),
                        );
                      }).toList(),
                    );

                    if (isCompact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          searchInput,
                          const SizedBox(height: 10),
                          roleFilters,
                        ],
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        roleFilters,
                        searchInput,
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // 3. Staff Profiles List / Table
              if (users.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_search_outlined, size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      const Text(
                        'No staff profiles found',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Click "Create Profile for Role" to provision your first staff user.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: controller.openCreateProfileDialog,
                        icon: const Icon(Icons.person_add_alt_1_outlined, size: 16),
                        label: const Text('Create Profile for Role'),
                      ),
                    ],
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth > 800;
                    if (isDesktop) {
                      return _buildDesktopTable(users);
                    } else {
                      return _buildMobileCards(users);
                    }
                  },
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDesktopTable(List<ProfileModel> users) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('STAFF MEMBER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted))),
                Expanded(flex: 2, child: Text('DEPARTMENT & PHONE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted))),
                Expanded(flex: 2, child: Text('ASSIGNED ROLE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted))),
                Expanded(flex: 2, child: Text('JOINED DATE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted))),
                SizedBox(width: 100, child: Center(child: Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted)))),
              ],
            ),
          ),

          // Table Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: users.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = users[index];
              final isCurrent = user.id == controller.currentProfile.value?.id;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    // Member Info
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primarySurface,
                            child: Text(
                              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      user.fullName,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                    if (isCurrent) ...[
                                      const SizedBox(width: 6),
                                      const Text('(You)', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                    ],
                                  ],
                                ),
                                Text(user.email, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Department & Phone
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.department ?? 'General Operations',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          Text(user.phoneNumber ?? 'No phone',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ),

                    // Role with Quick Switcher Dropdown
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isDense: true,
                              value: user.role,
                              items: const [
                                DropdownMenuItem(value: 'admin', child: Text('ADMIN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                                DropdownMenuItem(value: 'editor', child: Text('EDITOR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                                DropdownMenuItem(value: 'viewer', child: Text('VIEWER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                                DropdownMenuItem(value: 'user', child: Text('USER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                              ],
                              onChanged: isCurrent
                                  ? null
                                  : (newRole) {
                                      if (newRole != null && newRole != user.role) {
                                        controller.updateUserRole(user, newRole);
                                      }
                                    },
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Joined Date
                    Expanded(
                      flex: 2,
                      child: Text(
                        AppFormatters.formatDate(user.createdAt),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),

                    // Active Toggle
                    SizedBox(
                      width: 100,
                      child: Center(
                        child: isCurrent
                            ? const StatusBadge(label: 'ACTIVE', type: StatusBadgeType.success)
                            : IconButton(
                                icon: Icon(
                                  user.isActive ? Icons.toggle_on : Icons.toggle_off,
                                  color: user.isActive ? AppColors.success : AppColors.textMuted,
                                  size: 32,
                                ),
                                tooltip: user.isActive ? 'Deactivate user' : 'Activate user',
                                onPressed: () => controller.toggleUserStatus(user),
                              ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCards(List<ProfileModel> users) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = users[index];
        final isCurrent = user.id == controller.currentProfile.value?.id;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primarySurface,
                    child: Text(
                      user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        Text(user.email, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  StatusBadge(
                    label: user.role.toUpperCase(),
                    type: user.role == 'admin' ? StatusBadgeType.warning : StatusBadgeType.info,
                  ),
                ],
              ),
              const Divider(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Dept: ${user.department ?? "General"}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  if (!isCurrent)
                    IconButton(
                      icon: Icon(
                        user.isActive ? Icons.toggle_on : Icons.toggle_off,
                        color: user.isActive ? AppColors.success : AppColors.textMuted,
                        size: 28,
                      ),
                      onPressed: () => controller.toggleUserStatus(user),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
