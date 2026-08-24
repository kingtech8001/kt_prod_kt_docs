import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/auth_repository.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/app/widgets/web_header.dart';
import 'package:kt_prod_kt_docs/app/widgets/web_sidebar.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';

class WebScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget body;
  final String currentRoute;
  final ValueChanged<String>? onSearch;
  final String? searchHint;
  final List<Widget>? headerActions;

  const WebScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    required this.currentRoute,
    this.onSearch,
    this.searchHint,
    this.headerActions,
  });

  void _handleSignOut() {
    Get.dialog(
      AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of Kt DocHolder?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Get.back();
              final authRepo = Get.find<AuthRepository>();
              await authRepo.signOut();
              Get.offAllNamed(AppRoutes.LOGIN);
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= AppConstants.desktopBreakpoint;

    final sidebar = WebSidebar(
      currentRoute: currentRoute,
      onSignOut: _handleSignOut,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: isDesktop ? null : Drawer(child: sidebar),
      body: Row(
        children: [
          if (isDesktop) sidebar,
          Expanded(
            child: Column(
              children: [
                WebHeader(
                  title: title,
                  subtitle: subtitle,
                  onSearch: onSearch,
                  searchHint: searchHint,
                  customActions: headerActions,
                  showDrawerButton: !isDesktop,
                ),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
