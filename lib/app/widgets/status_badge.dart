import 'package:flutter/material.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';

enum StatusBadgeType {
  info,
  success,
  warning,
  error,
  inactive,
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color? textColor;
  final Color? backgroundColor;
  final IconData? icon;
  final StatusBadgeType? type;

  const StatusBadge({
    super.key,
    required this.label,
    this.textColor,
    this.backgroundColor,
    this.icon,
    this.type,
  });

  factory StatusBadge.paid() {
    return const StatusBadge(
      label: 'Paid',
      textColor: AppColors.success,
      backgroundColor: AppColors.successLight,
      icon: Icons.check_circle_outline,
    );
  }

  factory StatusBadge.pending() {
    return const StatusBadge(
      label: 'Pending',
      textColor: AppColors.warning,
      backgroundColor: AppColors.warningLight,
      icon: Icons.access_time,
    );
  }

  factory StatusBadge.overdue() {
    return const StatusBadge(
      label: 'Overdue',
      textColor: AppColors.error,
      backgroundColor: AppColors.errorLight,
      icon: Icons.error_outline,
    );
  }

  factory StatusBadge.warrantyActive({int? daysRemaining}) {
    final text = daysRemaining != null && daysRemaining > 0
        ? 'Active ($daysRemaining d)'
        : 'Active';
    return StatusBadge(
      label: text,
      textColor: AppColors.warrantyEmerald,
      backgroundColor: AppColors.warrantyEmeraldLight,
      icon: Icons.verified_user_outlined,
    );
  }

  factory StatusBadge.warrantyExpiringSoon({required int daysRemaining}) {
    return StatusBadge(
      label: 'Expires in $daysRemaining d',
      textColor: AppColors.warning,
      backgroundColor: AppColors.warningLight,
      icon: Icons.warning_amber_rounded,
    );
  }

  factory StatusBadge.warrantyExpired() {
    return const StatusBadge(
      label: 'Expired',
      textColor: AppColors.error,
      backgroundColor: AppColors.errorLight,
      icon: Icons.cancel_outlined,
    );
  }

  factory StatusBadge.noWarranty() {
    return const StatusBadge(
      label: 'No Warranty',
      textColor: AppColors.textSecondary,
      backgroundColor: AppColors.border,
      icon: Icons.receipt_long_outlined,
    );
  }

  factory StatusBadge.city({required String cityName}) {
    return StatusBadge(
      label: cityName,
      textColor: AppColors.primaryDark,
      backgroundColor: AppColors.primarySurface,
      icon: Icons.location_on_outlined,
    );
  }

  factory StatusBadge.category({required String name, Color? color}) {
    final c = color ?? AppColors.primary;
    return StatusBadge(
      label: name,
      textColor: c,
      backgroundColor: c.withValues(alpha: 0.12),
    );
  }

  Color get _resolvedTextColor {
    if (textColor != null) return textColor!;
    switch (type) {
      case StatusBadgeType.success:
        return AppColors.success;
      case StatusBadgeType.warning:
        return AppColors.warning;
      case StatusBadgeType.error:
        return AppColors.error;
      case StatusBadgeType.inactive:
        return AppColors.textMuted;
      case StatusBadgeType.info:
      default:
        return AppColors.primary;
    }
  }

  Color get _resolvedBgColor {
    if (backgroundColor != null) return backgroundColor!;
    switch (type) {
      case StatusBadgeType.success:
        return AppColors.successLight;
      case StatusBadgeType.warning:
        return AppColors.warningLight;
      case StatusBadgeType.error:
        return AppColors.errorLight;
      case StatusBadgeType.inactive:
        return AppColors.border;
      case StatusBadgeType.info:
      default:
        return AppColors.primarySurface;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = _resolvedTextColor;
    final bg = _resolvedBgColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
