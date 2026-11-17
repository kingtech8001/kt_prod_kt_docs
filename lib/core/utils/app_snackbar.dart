import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';

/// Compact, non-blocking notification toast utility strictly adhering to
/// KT_Docs_AI_Master_Context.md Section 1, 3.A, 3.B and multi-device adaptive layout.
///
/// Features:
/// - Desktop/Tablet (>= 768px): Positioned at the top-right corner with a small compact width (~400px).
/// - Mobile (< 768px): Positioned top-center with responsive side padding.
/// - Non-blocking: Custom overlay entry with transparent hit-test routing so all underlying buttons,
///   dialogs, inputs, and navigation elements remain 100% clickable/workable while displayed.
/// - Stacking & Auto-dismiss: Smooth sliding animation and clean auto-dismiss.
class AppSnackbar {
  AppSnackbar._();

  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  /// Immediately dismisses any active toast/snackbar.
  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    if (_currentEntry != null) {
      try {
        _currentEntry?.remove();
      } catch (_) {}
      _currentEntry = null;
    }
    // Also clean up any lingering GetX native snackbars if present
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }
  }

  /// Closes all active dialogs and bottom sheets.
  /// Dismisses any open toast/snackbar first to prevent navigation interception.
  static void closeAllModals() {
    dismiss();
    while (Get.isDialogOpen == true || Get.isBottomSheetOpen == true) {
      Get.back();
    }
  }

  /// Displays a success notification.
  /// Strictly follows Rule 3.B: Closes all pending dialogs/bottom sheets first,
  /// then waits for the current frame to complete before presenting the toast,
  /// ensuring Get.context is cleanly restored and underlying UI clicks are workable.
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
    dismiss();

    final overlayState = Get.overlayContext?.findRenderObject() != null
        ? Overlay.maybeOf(Get.overlayContext!)
        : (Get.key.currentState?.overlay);

    if (overlayState == null) return;

    final cleanMessage = message.length > 250
        ? '${message.substring(0, 250)}...'
        : message;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _CompactToastWidget(
        title: title,
        message: cleanMessage,
        backgroundColor: backgroundColor,
        icon: icon,
        onDismiss: () {
          if (_currentEntry == entry) {
            dismiss();
          }
        },
      ),
    );

    _currentEntry = entry;
    overlayState.insert(entry);

    _dismissTimer = Timer(const Duration(seconds: 4), () {
      if (_currentEntry == entry) {
        dismiss();
      }
    });
  }
}

class _CompactToastWidget extends StatefulWidget {
  final String title;
  final String message;
  final Color backgroundColor;
  final IconData icon;
  final VoidCallback onDismiss;

  const _CompactToastWidget({
    required this.title,
    required this.message,
    required this.backgroundColor,
    required this.icon,
    required this.onDismiss,
  });

  @override
  State<_CompactToastWidget> createState() => _CompactToastWidgetState();
}

class _CompactToastWidgetState extends State<_CompactToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isDesktopOrTablet = screenWidth >= AppConstants.tabletBreakpoint;

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: Stack(
          children: [
            // Ensure clicks outside the compact toast card pass straight through to buttons/dialogs
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (_) {},
              ),
            ),
            Align(
              alignment: isDesktopOrTablet ? Alignment.topRight : Alignment.topCenter,
              child: SafeArea(
                top: true,
                left: false,
                right: false,
                bottom: false,
                child: Padding(
                  padding: isDesktopOrTablet
                      ? const EdgeInsets.only(top: 16, right: 24, left: 16)
                      : const EdgeInsets.symmetric(
                          horizontal: AppConstants.mobileSnackbarMargin,
                          vertical: 12,
                        ),
                  child: SlideTransition(
                    position: _offsetAnimation,
                    fade: _fadeAnimation,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isDesktopOrTablet
                            ? AppConstants.compactSnackbarMaxWidth
                            : double.infinity,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          decoration: BoxDecoration(
                            color: widget.backgroundColor,
                            borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2, right: 10),
                                child: Icon(
                                  widget.icon,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (widget.title.isNotEmpty)
                                      Text(
                                        widget.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                    if (widget.title.isNotEmpty && widget.message.isNotEmpty)
                                      const SizedBox(height: 3),
                                    if (widget.message.isNotEmpty)
                                      Text(
                                        widget.message,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.92),
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w400,
                                          height: 1.25,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: _handleDismiss,
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 17,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SlideTransition extends StatelessWidget {
  final Animation<Offset> position;
  final Animation<double> fade;
  final Widget child;

  const SlideTransition({
    super.key,
    required this.position,
    required this.fade,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fade,
      child: FractionalTranslation(
        translation: position.value,
        child: child,
      ),
    );
  }
}
