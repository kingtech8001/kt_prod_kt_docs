import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';

class AppSnackbar {
  AppSnackbar._();

  /// Immediately dismisses any active snackbar to prevent it from intercepting
  /// subsequent back navigations or blocking button interactions.
  static void dismiss() {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }
  }

  /// Closes all active dialogs and bottom sheets.
  /// Dismisses any open snackbar first to prevent Get.back() from being intercepted.
  static void closeAllModals() {
    dismiss();
    while (Get.isDialogOpen == true || Get.isBottomSheetOpen == true) {
      Get.back();
    }
  }

  /// Displays a success notification.
  /// Strictly follows Rule 3.B: Closes all pending dialogs/bottom sheets first,
  /// then waits for the current frame to complete before presenting the snackbar,
  /// ensuring Get.context is cleanly restored to the page and button clicks are not stuck.
  static void showSuccess(String title, String message) {
    closeAllModals();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _show(
        title: title,
        message: message,
        backgroundColor: AppColors.success,
        icon: Icons.check_circle_outline_rounded,
      );
    });
  }

  static void showError(String title, String message) {
    dismiss();
    _show(
      title: title,
      message: message,
      backgroundColor: AppColors.error,
      icon: Icons.error_outline_rounded,
    );
  }

  static void showWarning(String title, String message) {
    dismiss();
    _show(
      title: title,
      message: message,
      backgroundColor: AppColors.warning,
      icon: Icons.warning_amber_rounded,
    );
  }

  static void showInfo(String title, String message) {
    dismiss();
    _show(
      title: title,
      message: message,
      backgroundColor: AppColors.info,
      icon: Icons.info_outline_rounded,
    );
  }

  static void _show({
    required String title,
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    final screenWidth = Get.width;
    final isDesktopOrTablet = screenWidth >= AppConstants.tabletBreakpoint;

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: backgroundColor,
      colorText: Colors.white,
      icon: Icon(icon, color: Colors.white, size: 22),
      borderRadius: AppConstants.radiusSmall,
      margin: isDesktopOrTablet
          ? const EdgeInsets.only(top: 16, right: 16, left: 16)
          : const EdgeInsets.symmetric(
              horizontal: AppConstants.mobileSnackbarMargin,
              vertical: 16,
            ),
      maxWidth: isDesktopOrTablet ? AppConstants.compactSnackbarMaxWidth : null,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.14),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
      duration: const Duration(seconds: 4),
      animationDuration: const Duration(milliseconds: 300),
      isDismissible: true,
      shouldIconPulse: false,
    );
  }
}
