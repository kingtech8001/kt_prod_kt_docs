import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/modules/splash/controllers/splash_controller.dart';
import 'package:kt_prod_kt_docs/app/widgets/app_shimmer.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';

/// Branded splash screen displayed while Supabase session is being restored.
///
/// Shows a branded logo, app name, and a shimmer-animated loading indicator
/// that mirrors the app's visual identity. Complies with project rules:
/// NEVER use bare spinners or blank screens for loading states.
class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    // Access controller to trigger onInit (GetView lazy-access)
    // ignore: unnecessary_statements
    controller;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Branded Logo Box (matches HTML splash screen)
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.description_outlined,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 24),

            // App Name
            const Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            const Text(
              'Restoring your session...',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            // Shimmer loading indicator (follows project shimmer rules)
            AppShimmer(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShimmerBox(
                    width: 12,
                    height: 12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(width: 8),
                  ShimmerBox(
                    width: 12,
                    height: 12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(width: 8),
                  ShimmerBox(
                    width: 12,
                    height: 12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  const ShimmerBox(
                    width: 100,
                    height: 12,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
