import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/core/utils/app_snackbar.dart';

/// Centralized utility for managing dialogs and modals safely.
/// Prevents GetX snackbar overlay conflicts, context corruption, and stuck button clicks.
class AppDialog {
  AppDialog._();

  /// Shows a dialog after ensuring any active snackbar is dismissed.
  /// This prevents lingering snackbar overlays from capturing clicks or intercepting
  /// Get.back() calls inside the modal.
  static Future<T?> show<T>(
    Widget dialog, {
    bool barrierDismissible = true,
    Color? barrierColor,
    bool useSafeArea = true,
  }) {
    AppSnackbar.dismiss();
    return Get.dialog<T>(
      dialog,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      useSafeArea: useSafeArea,
    );
  }

  /// Closes the active modal reliably.
  /// If a snackbar is open, it dismisses the snackbar first to prevent GetX from
  /// popping the snackbar instead of the modal route.
  static void back<T>({T? result}) {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }
    Get.back<T>(result: result);
  }

  /// Safely closes all open dialogs and bottom sheets.
  static void closeAllModals() {
    AppSnackbar.closeAllModals();
  }
}
