import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/profile_model.dart';
import 'package:kt_prod_kt_docs/app/data/services/auth_service.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';

class WebSidebar extends StatelessWidget {
  final String currentRoute;
  final ProfileModel? profile;
  final VoidCallback onSignOut;

  const WebSidebar({
    super.key,
    required this.currentRoute,
    this.profile,
    required this.onSignOut,
  });

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    String? badge,
    Color? badgeColor,
  }) {
    final isSelected = currentRoute == route;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
              Navigator.of(context).pop();
            }
            if (currentRoute != route) {
              Get.toNamed(route);
            }
          },
          borderRadius: BorderRadius.circular(8),
          hoverColor: AppColors.sidebarHover,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.sidebarActive : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? AppColors.sidebarTextActive
                      : AppColors.sidebarText,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.sidebarTextActive
                          : AppColors.sidebarText,
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor ?? AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final authService = Get.isRegistered<AuthService>() ? AuthService.to : null;
      final activeProfile = profile ?? authService?.currentProfile.value;
      final isAdmin = authService?.isAdmin ?? (activeProfile?.isAdmin ?? false);
      final displayName = authService?.userName ?? (activeProfile?.fullName ?? 'Admin');
      final userRole = authService?.userRoleDisplay ?? (activeProfile?.role.toUpperCase() ?? 'ADMIN');

      return Container(
        width: 250,
        color: AppColors.sidebarBg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 38,
                      height: 38,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConstants.appName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'King Technology',
                        style: TextStyle(
                          color: AppColors.sidebarText,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(color: AppColors.sidebarHover, height: 1),
            const SizedBox(height: 12),

            // Main Navigation Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildNavItem(
                    context,
                    icon: Icons.dashboard_outlined,
                    title: 'Dashboard',
                    route: AppRoutes.DASHBOARD,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.description_outlined,
                    title: 'All Documents',
                    route: AppRoutes.DOCUMENTS,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.bolt_outlined,
                    title: 'Utility Bills',
                    route: AppRoutes.UTILITY_BILLS,
                    badge: 'Light/Gas',
                    badgeColor: AppColors.utilityAmber,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.shield_outlined,
                    title: 'Appliance Vault',
                    route: AppRoutes.APPLIANCES,
                    badge: 'Warranty',
                    badgeColor: AppColors.warrantyEmerald,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.badge_outlined,
                    title: 'Personal Vault',
                    route: AppRoutes.PERSONAL_DOCS,
                    badge: 'Identity',
                    badgeColor: const Color(0xFF8B5CF6),
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.folder_outlined,
                    title: 'Folders',
                    route: AppRoutes.FOLDERS,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.star_border_outlined,
                    title: 'Favorites',
                    route: AppRoutes.FAVORITES,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.delete_outline,
                    title: 'Trash Bin',
                    route: AppRoutes.TRASH,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.history_outlined,
                    title: 'Activity Logs',
                    route: AppRoutes.ACTIVITY_LOGS,
                  ),
                  if (isAdmin)
                    _buildNavItem(
                      context,
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Staff & Roles',
                      route: AppRoutes.USERS,
                      badge: 'Admin',
                      badgeColor: AppColors.primaryLight,
                    ),
                  _buildNavItem(
                    context,
                    icon: Icons.person_outline,
                    title: 'My Profile',
                    route: AppRoutes.PROFILE,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    route: AppRoutes.SETTINGS,
                  ),
                ],
              ),
            ),

            const Divider(color: AppColors.sidebarHover, height: 1),

            // User Profile Card & Sign Out
            Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
                          Navigator.of(context).pop();
                        }
                        if (currentRoute != AppRoutes.PROFILE) {
                          Get.toNamed(AppRoutes.PROFILE);
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      hoverColor: AppColors.sidebarHover,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    userRole,
                                    style: const TextStyle(
                                      color: AppColors.primaryLight,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout,
                        color: AppColors.sidebarText, size: 18),
                    tooltip: 'Sign Out',
                    onPressed: onSignOut,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
