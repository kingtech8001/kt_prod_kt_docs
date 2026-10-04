import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/services/auth_service.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';

class WebHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final ValueChanged<String>? onSearch;
  final String? searchHint;
  final List<Widget>? customActions;
  final bool showDrawerButton;

  const WebHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onSearch,
    this.searchHint,
    this.customActions,
    this.showDrawerButton = false,
  });

  Widget _buildDemoBadge() {
    return Obx(() {
      if (!AuthService.to.isDemoMode.value) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.warningLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.visibility_rounded, size: 14, color: AppColors.warning),
            SizedBox(width: 5),
            Text(
              'DEMO MODE (STATIC)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.warning,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 768;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 24,
        vertical: isCompact ? 12 : 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: isCompact ? _buildCompactHeader(context) : _buildWideHeader(context),
    );
  }

  Widget _buildWideHeader(BuildContext context) {
    return Row(
      children: [
        if (showDrawerButton) ...[
          IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textPrimary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          const SizedBox(width: 8),
        ],
        // Title and Subtitle
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              _buildDemoBadge(),
            ],
          ),
        ),

        // Search Bar if enabled
        if (onSearch != null) ...[
          SizedBox(
            width: 260,
            height: 38,
            child: TextField(
              onChanged: onSearch,
              decoration: InputDecoration(
                hintText: searchHint ?? 'Search...',
                prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.textMuted),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                filled: true,
                fillColor: AppColors.background,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],

        // Custom Actions if any
        if (customActions != null) ...?customActions,

        // Upload Document Button
        ElevatedButton.icon(
          onPressed: () => Get.toNamed(AppRoutes.UPLOAD),
          icon: const Icon(Icons.cloud_upload_outlined, size: 16),
          label: const Text('Upload'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (showDrawerButton) ...[
              IconButton(
                icon: const Icon(Icons.menu, color: AppColors.textPrimary),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildDemoBadge(),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Get.toNamed(AppRoutes.UPLOAD),
              icon: const Icon(Icons.cloud_upload_outlined, size: 14),
              label: const Text('Upload', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
            ),
          ],
        ),
        if (customActions != null && customActions!.isNotEmpty) ...[
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: customActions!
                  .expand((w) => [w, const SizedBox(width: 8)])
                  .take(customActions!.length * 2 - 1)
                  .toList(),
            ),
          ),
        ],
        if (onSearch != null) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: TextField(
              onChanged: onSearch,
              decoration: InputDecoration(
                hintText: searchHint ?? 'Search...',
                prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.textMuted),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                filled: true,
                fillColor: AppColors.background,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
