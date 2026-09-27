import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/auth_repository.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/app/widgets/web_header.dart';
import 'package:kt_prod_kt_docs/app/widgets/web_sidebar.dart';
import 'package:kt_prod_kt_docs/core/utils/app_dialog.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';

class WebScaffold extends StatefulWidget {
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

  @override
  State<WebScaffold> createState() => _WebScaffoldState();
}

class _WebScaffoldState extends State<WebScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _handleSignOut() {
    AppDialog.show(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        ),
        backgroundColor: AppColors.surface,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusSmall),
                      ),
                      child: const Icon(Icons.logout_rounded,
                          color: AppColors.error, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Sign Out',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Are you sure you want to sign out of ${AppConstants.appName}?',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Get.back(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                      ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= AppConstants.desktopBreakpoint;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.surface,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.surface,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          final state = _scaffoldKey.currentState;
          if (state != null && state.isDrawerOpen) {
            state.closeDrawer();
            return;
          }
          if (!isDesktop && state != null && !state.isDrawerOpen) {
            state.openDrawer();
            return;
          }
          if (widget.currentRoute != AppRoutes.DASHBOARD) {
            Get.offAllNamed(AppRoutes.DASHBOARD);
          }
        },
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.background,
          drawerEnableOpenDragGesture: !isDesktop,
          drawerEdgeDragWidth: isDesktop ? 0 : MediaQuery.sizeOf(context).width * 0.45,
          drawer: isDesktop
              ? null
              : Drawer(
                  backgroundColor: AppColors.sidebarBg,
                  child: SafeArea(
                    child: WebSidebar(
                      currentRoute: widget.currentRoute,
                      onSignOut: _handleSignOut,
                    ),
                  ),
                ),
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: (details) {
              // Left-to-right swipe on mobile screen opens the drawer
              if (!isDesktop && (details.primaryVelocity ?? 0) > 250) {
                final state = _scaffoldKey.currentState;
                if (state != null && !state.isDrawerOpen) {
                  state.openDrawer();
                }
              }
            },
            child: Row(
              children: [
                if (isDesktop)
                  WebSidebar(
                    currentRoute: widget.currentRoute,
                    onSignOut: _handleSignOut,
                  ),
                Expanded(
                  child: Column(
                    children: [
                      // Ensures the area above the header (status bar / notch) matches the app bar color
                      Container(
                        color: AppColors.surface,
                        child: SafeArea(
                          bottom: false,
                          left: false,
                          right: false,
                          child: WebHeader(
                            title: widget.title,
                            subtitle: widget.subtitle,
                            onSearch: widget.onSearch,
                            searchHint: widget.searchHint,
                            customActions: widget.headerActions,
                            showDrawerButton: !isDesktop,
                          ),
                        ),
                      ),
                      Expanded(child: widget.body),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
