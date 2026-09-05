import 'package:flutter/material.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';

/// Reusable animated Shimmer effect container using a smooth linear gradient sweep.
/// Zero external dependencies, pure Flutter canvas performance.
class AppShimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const AppShimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final double value = _controller.value;
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                AppColors.border,
                AppColors.surface,
                AppColors.border,
              ],
              stops: [
                (value - 0.3).clamp(0.0, 1.0),
                value.clamp(0.0, 1.0),
                (value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Generic skeleton rectangle / pill placeholder.
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadiusGeometry? borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: borderRadius ?? BorderRadius.circular(AppConstants.radiusSmall),
      ),
    );
  }
}

/// Skeleton for a single MetricCard.
class MetricCardSkeleton extends StatelessWidget {
  const MetricCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(width: 48, height: 48),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const ShimmerBox(width: 80, height: 12),
                const SizedBox(height: 10),
                const ShimmerBox(width: 60, height: 26),
                const SizedBox(height: 8),
                ShimmerBox(
                  width: double.infinity,
                  height: 12,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Responsive grid of MetricCard skeletons (4 cols on Desktop, 2 on Tablet, 1 on Mobile).
class DashboardMetricsSkeleton extends StatelessWidget {
  const DashboardMetricsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width < AppConstants.tabletBreakpoint) {
          // Mobile: 1 column
          return const Column(
            children: [
              MetricCardSkeleton(),
              SizedBox(height: 12),
              MetricCardSkeleton(),
              SizedBox(height: 12),
              MetricCardSkeleton(),
              SizedBox(height: 12),
              MetricCardSkeleton(),
            ],
          );
        } else if (width < AppConstants.desktopBreakpoint) {
          // Tablet: 2 columns
          return const Column(
            children: [
              Row(
                children: [
                  Expanded(child: MetricCardSkeleton()),
                  SizedBox(width: 16),
                  Expanded(child: MetricCardSkeleton()),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: MetricCardSkeleton()),
                  SizedBox(width: 16),
                  Expanded(child: MetricCardSkeleton()),
                ],
              ),
            ],
          );
        } else {
          // Desktop: 4 columns
          return const Row(
            children: [
              Expanded(child: MetricCardSkeleton()),
              SizedBox(width: 16),
              Expanded(child: MetricCardSkeleton()),
              SizedBox(width: 16),
              Expanded(child: MetricCardSkeleton()),
              SizedBox(width: 16),
              Expanded(child: MetricCardSkeleton()),
            ],
          );
        }
      },
    );
  }
}

/// Skeleton for Expiring Warranties & Pending Utility Bills.
class DashboardAlertsSkeleton extends StatelessWidget {
  const DashboardAlertsSkeleton({super.key});

  Widget _buildAlertCard() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  ShimmerBox(width: 24, height: 24),
                  SizedBox(width: 8),
                  ShimmerBox(width: 160, height: 16),
                ],
              ),
              ShimmerBox(width: 50, height: 14),
            ],
          ),
          const Divider(height: 24),
          for (int i = 0; i < 3; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const ShimmerBox(width: 36, height: 36),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 180, height: 14),
                        SizedBox(height: 6),
                        ShimmerBox(width: 120, height: 10),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ShimmerBox(
                    width: 70,
                    height: 20,
                    borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                ],
              ),
            ),
            if (i < 2) const Divider(height: 16),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= AppConstants.desktopBreakpoint;
        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildAlertCard()),
              const SizedBox(width: 20),
              Expanded(child: _buildAlertCard()),
            ],
          );
        } else {
          return Column(
            children: [
              _buildAlertCard(),
              const SizedBox(height: 20),
              _buildAlertCard(),
            ],
          );
        }
      },
    );
  }
}

/// Skeleton for a single DocumentCard.
class DocumentCardSkeleton extends StatelessWidget {
  const DocumentCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview thumbnail area
          const ShimmerBox(
            width: double.infinity,
            height: 110,
            borderRadius: BorderRadius.zero,
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerBox(width: 140, height: 14),
                const SizedBox(height: 8),
                const ShimmerBox(width: 90, height: 10),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBox(
                      width: 60,
                      height: 18,
                      borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                    ),
                    const Row(
                      children: [
                        ShimmerBox(width: 24, height: 24),
                        SizedBox(width: 8),
                        ShimmerBox(width: 24, height: 24),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Responsive grid of DocumentCard skeletons (3/4 Desktop, 2 Tablet, 1 Mobile).
class DashboardRecentDocumentsSkeleton extends StatelessWidget {
  const DashboardRecentDocumentsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxis = 3;
        if (width < AppConstants.tabletBreakpoint) {
          crossAxis = 1;
        } else if (width < AppConstants.desktopBreakpoint) {
          crossAxis = 2;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxis,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 240,
          ),
          itemBuilder: (context, index) => const DocumentCardSkeleton(),
        );
      },
    );
  }
}

/// Skeleton for Dashboard low-priority trash summary strip.
class DashboardTrashSkeleton extends StatelessWidget {
  const DashboardTrashSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingLarge,
        vertical: AppConstants.paddingMedium,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              ShimmerBox(width: 32, height: 32),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 140, height: 14),
                  SizedBox(height: 6),
                  ShimmerBox(width: 240, height: 10),
                ],
              ),
            ],
          ),
          ShimmerBox(width: 90, height: 28),
        ],
      ),
    );
  }
}

/// Full dashboard skeleton view replacing bare spinners.
class DashboardSkeletonView extends StatelessWidget {
  const DashboardSkeletonView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DashboardMetricsSkeleton(),
            const SizedBox(height: 28),
            const DashboardAlertsSkeleton(),
            const SizedBox(height: 24),
            const DashboardTrashSkeleton(),
            const SizedBox(height: 32),
            // Header skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 160, height: 18),
                    SizedBox(height: 6),
                    ShimmerBox(width: 260, height: 12),
                  ],
                ),
                ShimmerBox(
                  width: 80,
                  height: 32,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const DashboardRecentDocumentsSkeleton(),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for a single Document list item in Document Explorer.
class DocumentListTileSkeleton extends StatelessWidget {
  const DocumentListTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
        border: Border.all(color: AppColors.border),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: const Row(
        children: [
          ShimmerBox(width: 42, height: 42),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 180, height: 14),
                SizedBox(height: 6),
                ShimmerBox(width: 120, height: 10),
              ],
            ),
          ),
          SizedBox(width: 12),
          ShimmerBox(width: 70, height: 22),
          SizedBox(width: 16),
          Row(
            children: [
              ShimmerBox(width: 24, height: 24),
              SizedBox(width: 8),
              ShimmerBox(width: 24, height: 24),
              SizedBox(width: 8),
              ShimmerBox(width: 24, height: 24),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shimmer skeleton for Document Explorer in List View mode.
class ExploreListSkeleton extends StatelessWidget {
  const ExploreListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        itemCount: 8,
        itemBuilder: (context, index) => const DocumentListTileSkeleton(),
      ),
    );
  }
}

/// Shimmer skeleton for Document Explorer in Grid View mode.
class ExploreGridSkeleton extends StatelessWidget {
  const ExploreGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          int crossAxis = 4;
          if (width < AppConstants.tabletBreakpoint) {
            crossAxis = 1;
          } else if (width < AppConstants.desktopBreakpoint) {
            crossAxis = 2;
          } else if (width < 1400) {
            crossAxis = 3;
          }

          return GridView.builder(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            itemCount: 8,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxis,
              crossAxisSpacing: AppConstants.paddingMedium,
              mainAxisSpacing: AppConstants.paddingMedium,
              mainAxisExtent: 240,
            ),
            itemBuilder: (context, index) => const DocumentCardSkeleton(),
          );
        },
      ),
    );
  }
}

/// Shimmer skeleton table row for Staff & Role management.
class StaffTableRowSkeleton extends StatelessWidget {
  const StaffTableRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          const ShimmerBox(width: 36, height: 36, borderRadius: BorderRadius.all(Radius.circular(18))),
          const SizedBox(width: 12),
          const Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 130, height: 14),
                SizedBox(height: 6),
                ShimmerBox(width: 180, height: 10),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 100, height: 12),
                SizedBox(height: 6),
                ShimmerBox(width: 80, height: 10),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            flex: 2,
            child: ShimmerBox(width: 80, height: 26),
          ),
          const SizedBox(width: 12),
          const Expanded(
            flex: 2,
            child: ShimmerBox(width: 70, height: 12),
          ),
          const SizedBox(
            width: 100,
            child: Center(
              child: ShimmerBox(width: 48, height: 24),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full skeleton view for Staff & Role Management screen.
class StaffSkeletonView extends StatelessWidget {
  const StaffSkeletonView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Metrics skeleton
            const DashboardMetricsSkeleton(),
            const SizedBox(height: 24),

            // 2. Toolbar skeleton
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ShimmerBox(width: 70, height: 32),
                      SizedBox(width: 8),
                      ShimmerBox(width: 70, height: 32),
                      SizedBox(width: 8),
                      ShimmerBox(width: 70, height: 32),
                    ],
                  ),
                  ShimmerBox(width: 200, height: 38),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Table skeleton
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(AppConstants.radiusMedium),
                        topRight: Radius.circular(AppConstants.radiusMedium),
                      ),
                      border: Border(bottom: BorderSide(color: AppColors.border)),
                    ),
                    child: const Row(
                      children: [
                        Expanded(flex: 3, child: ShimmerBox(width: 100, height: 12)),
                        Expanded(flex: 2, child: ShimmerBox(width: 80, height: 12)),
                        Expanded(flex: 2, child: ShimmerBox(width: 80, height: 12)),
                        Expanded(flex: 2, child: ShimmerBox(width: 70, height: 12)),
                        SizedBox(width: 100, child: Center(child: ShimmerBox(width: 50, height: 12))),
                      ],
                    ),
                  ),
                  for (int i = 0; i < 5; i++) ...[
                    const StaffTableRowSkeleton(),
                    if (i < 4) const Divider(height: 1),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer skeleton for Trash Bin in Grid View mode.
class TrashGridSkeleton extends StatelessWidget {
  const TrashGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          int crossAxis = 4;
          if (width < AppConstants.tabletBreakpoint) {
            crossAxis = 1;
          } else if (width < AppConstants.desktopBreakpoint) {
            crossAxis = 2;
          } else if (width < 1400) {
            crossAxis = 3;
          }

          return GridView.builder(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            itemCount: 8,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxis,
              crossAxisSpacing: AppConstants.paddingMedium,
              mainAxisSpacing: AppConstants.paddingMedium,
              mainAxisExtent: 240,
            ),
            itemBuilder: (context, index) => const DocumentCardSkeleton(),
          );
        },
      ),
    );
  }
}

/// Shimmer loader for lazy loading / infinite scroll pagination batches.
/// Replaces bare circular progress indicators at list/grid bottom.
class BottomShimmerLoader extends StatelessWidget {
  const BottomShimmerLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppConstants.paddingLarge,
          horizontal: AppConstants.paddingLarge,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShimmerBox(
              width: 14,
              height: 14,
              borderRadius: BorderRadius.circular(7),
            ),
            const SizedBox(width: AppConstants.paddingSmall),
            ShimmerBox(
              width: 14,
              height: 14,
              borderRadius: BorderRadius.circular(7),
            ),
            const SizedBox(width: AppConstants.paddingSmall),
            ShimmerBox(
              width: 14,
              height: 14,
              borderRadius: BorderRadius.circular(7),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            const ShimmerBox(
              width: 120,
              height: 14,
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for a single FolderCard in Folders View.
class FolderCardSkeleton extends StatelessWidget {
  const FolderCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ShimmerBox(width: 44, height: 44),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerBox(width: 120, height: 16),
                    const SizedBox(height: 6),
                    ShimmerBox(
                      width: 70,
                      height: 18,
                      borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBox(width: 80, height: 12),
              ShimmerBox(width: 70, height: 26),
            ],
          ),
        ],
      ),
    );
  }
}

/// Full screen skeleton for Folders Explorer.
class FoldersSkeletonView extends StatelessWidget {
  const FoldersSkeletonView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toolbar skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(
                  width: 260,
                  height: 40,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                ),
                ShimmerBox(
                  width: 130,
                  height: 40,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            // Responsive Grid of Folder cards
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                int crossAxis = 4;
                if (width < AppConstants.tabletBreakpoint) {
                  crossAxis = 1;
                } else if (width < 1100) {
                  crossAxis = 2;
                } else if (width < 1400) {
                  crossAxis = 3;
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 8,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxis,
                    crossAxisSpacing: AppConstants.paddingMedium,
                    mainAxisSpacing: AppConstants.paddingMedium,
                    mainAxisExtent: 150,
                  ),
                  itemBuilder: (context, index) => const FolderCardSkeleton(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for a single Utility Bill tile (responsive for Desktop/Tablet and Mobile).
class UtilityBillTileSkeleton extends StatelessWidget {
  const UtilityBillTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < AppConstants.tabletBreakpoint;

          if (isMobile) {
            return const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ShimmerBox(width: 42, height: 42),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerBox(width: 150, height: 14),
                          SizedBox(height: 6),
                          ShimmerBox(width: 110, height: 11),
                        ],
                      ),
                    ),
                    ShimmerBox(width: 65, height: 22),
                  ],
                ),
                Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 100, height: 11),
                        SizedBox(height: 6),
                        ShimmerBox(width: 80, height: 16),
                      ],
                    ),
                    Row(
                      children: [
                        ShimmerBox(width: 24, height: 24),
                        SizedBox(width: 8),
                        ShimmerBox(width: 24, height: 24),
                        SizedBox(width: 8),
                        ShimmerBox(width: 24, height: 24),
                      ],
                    ),
                  ],
                ),
              ],
            );
          }

          return const Row(
            children: [
              ShimmerBox(width: 46, height: 46),
              SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 160, height: 14),
                    SizedBox(height: 6),
                    ShimmerBox(width: 120, height: 11),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 80, height: 13),
                    SizedBox(height: 6),
                    ShimmerBox(width: 100, height: 11),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 90, height: 13),
                    SizedBox(height: 6),
                    ShimmerBox(width: 70, height: 11),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 90, height: 16),
                    SizedBox(height: 6),
                    ShimmerBox(width: 60, height: 20),
                  ],
                ),
              ),
              Row(
                children: [
                  ShimmerBox(width: 24, height: 24),
                  SizedBox(width: 8),
                  ShimmerBox(width: 24, height: 24),
                  SizedBox(width: 8),
                  ShimmerBox(width: 24, height: 24),
                  SizedBox(width: 8),
                  ShimmerBox(width: 24, height: 24),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Full screen skeleton loader for Utility Bills screen. Zero bare spinners.
class UtilityBillsSkeletonView extends StatelessWidget {
  const UtilityBillsSkeletonView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. City Chips Skeleton
            const Row(
              children: [
                ShimmerBox(width: 70, height: 28),
                SizedBox(width: 8),
                ShimmerBox(width: 80, height: 28),
                SizedBox(width: 8),
                ShimmerBox(width: 75, height: 28),
                SizedBox(width: 8),
                ShimmerBox(width: 90, height: 28),
              ],
            ),
            const SizedBox(height: 16),

            // 2. Metrics Cards Skeleton (Responsive 4/2/1 cols)
            const DashboardMetricsSkeleton(),
            const SizedBox(height: 16),

            // 3. Secondary Toolbar Skeleton
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ShimmerBox(width: 120, height: 34),
                      SizedBox(width: 12),
                      ShimmerBox(width: 140, height: 34),
                    ],
                  ),
                  ShimmerBox(width: 80, height: 24),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Utility Bills List Skeleton Rows
            for (int i = 0; i < 5; i++) ...[
              const UtilityBillTileSkeleton(),
              if (i < 4) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

/// Skeleton for a single Appliance Vault Card mirroring the card layout.
class ApplianceTileSkeleton extends StatelessWidget {
  const ApplianceTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 700;
          if (isNarrow) {
            return const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 44, height: 44, borderRadius: BorderRadius.all(Radius.circular(10))),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerBox(width: 150, height: 14),
                          SizedBox(height: 6),
                          ShimmerBox(width: 110, height: 12),
                        ],
                      ),
                    ),
                    ShimmerBox(width: 70, height: 22),
                  ],
                ),
                SizedBox(height: 12),
                Divider(height: 1),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 120, height: 12),
                        SizedBox(height: 4),
                        ShimmerBox(width: 80, height: 11),
                      ],
                    ),
                    Row(
                      children: [
                        ShimmerBox(width: 24, height: 24),
                        SizedBox(width: 8),
                        ShimmerBox(width: 24, height: 24),
                        SizedBox(width: 8),
                        ShimmerBox(width: 24, height: 24),
                        SizedBox(width: 8),
                        ShimmerBox(width: 24, height: 24),
                      ],
                    ),
                  ],
                ),
              ],
            );
          }

          return const Row(
            children: [
              ShimmerBox(width: 46, height: 46, borderRadius: BorderRadius.all(Radius.circular(10))),
              SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 160, height: 15),
                    SizedBox(height: 6),
                    ShimmerBox(width: 200, height: 12),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 90, height: 13),
                    SizedBox(height: 6),
                    ShimmerBox(width: 110, height: 11),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 90, height: 13),
                    SizedBox(height: 6),
                    ShimmerBox(width: 70, height: 11),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 70, height: 22),
                    SizedBox(height: 6),
                    ShimmerBox(width: 90, height: 11),
                  ],
                ),
              ),
              Row(
                children: [
                  ShimmerBox(width: 24, height: 24),
                  SizedBox(width: 8),
                  ShimmerBox(width: 24, height: 24),
                  SizedBox(width: 8),
                  ShimmerBox(width: 24, height: 24),
                  SizedBox(width: 8),
                  ShimmerBox(width: 24, height: 24),
                  SizedBox(width: 8),
                  ShimmerBox(width: 24, height: 24),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Full screen skeleton loader for Appliance Vault screen. Zero bare spinners.
class ApplianceVaultSkeletonView extends StatelessWidget {
  const ApplianceVaultSkeletonView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Brand Filter Chips Skeleton
            const Row(
              children: [
                ShimmerBox(width: 75, height: 28),
                SizedBox(width: 8),
                ShimmerBox(width: 85, height: 28),
                SizedBox(width: 8),
                ShimmerBox(width: 70, height: 28),
                SizedBox(width: 8),
                ShimmerBox(width: 90, height: 28),
              ],
            ),
            const SizedBox(height: 16),

            // 2. Metrics Cards Skeleton (Responsive 4/2/1 cols)
            const DashboardMetricsSkeleton(),
            const SizedBox(height: 16),

            // 3. Secondary Toolbar Skeleton
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ShimmerBox(width: 130, height: 34),
                      SizedBox(width: 12),
                      ShimmerBox(width: 150, height: 34),
                    ],
                  ),
                  ShimmerBox(width: 85, height: 24),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Appliance List Skeleton Rows
            for (int i = 0; i < 5; i++) ...[
              const ApplianceTileSkeleton(),
              if (i < 4) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

/// Skeleton for a single Personal Document Card (Grid View).
class PersonalDocCardSkeleton extends StatelessWidget {
  const PersonalDocCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                ShimmerBox(width: 36, height: 36, borderRadius: BorderRadius.all(Radius.circular(8))),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 110, height: 13),
                      SizedBox(height: 4),
                      ShimmerBox(width: 75, height: 11),
                    ],
                  ),
                ),
                ShimmerBox(width: 20, height: 20),
              ],
            ),
          ),
          Divider(height: 1),

          // Body
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 160, height: 14),
                      SizedBox(height: 8),
                      ShimmerBox(width: 100, height: 24, borderRadius: BorderRadius.all(Radius.circular(6))),
                    ],
                  ),
                  ShimmerBox(width: 120, height: 20, borderRadius: BorderRadius.all(Radius.circular(10))),
                ],
              ),
            ),
          ),

          // Action Toolbar
          Divider(height: 1),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ShimmerBox(width: 48, height: 20),
                ShimmerBox(width: 60, height: 20),
                ShimmerBox(width: 20, height: 20),
                ShimmerBox(width: 20, height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for a single Personal Document Row (List View).
class PersonalDocListTileSkeleton extends StatelessWidget {
  const PersonalDocListTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: const Row(
        children: [
          ShimmerBox(width: 42, height: 42, borderRadius: BorderRadius.all(Radius.circular(8))),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 180, height: 14),
                SizedBox(height: 6),
                ShimmerBox(width: 240, height: 11),
              ],
            ),
          ),
          ShimmerBox(width: 80, height: 22, borderRadius: BorderRadius.all(Radius.circular(12))),
          SizedBox(width: 12),
          ShimmerBox(width: 20, height: 20),
          SizedBox(width: 8),
          ShimmerBox(width: 20, height: 20),
          SizedBox(width: 8),
          ShimmerBox(width: 20, height: 20),
          SizedBox(width: 8),
          ShimmerBox(width: 20, height: 20),
        ],
      ),
    );
  }
}

/// Full screen skeleton loader for Personal Documents screen. Zero bare spinners.
class PersonalDocsSkeletonView extends StatelessWidget {
  final bool isGridView;

  const PersonalDocsSkeletonView({super.key, this.isGridView = true});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Person Filter Chips Skeleton
            const Row(
              children: [
                ShimmerBox(width: 80, height: 28),
                SizedBox(width: 8),
                ShimmerBox(width: 90, height: 28),
                SizedBox(width: 8),
                ShimmerBox(width: 75, height: 28),
                SizedBox(width: 8),
                ShimmerBox(width: 100, height: 28),
              ],
            ),
            const SizedBox(height: 16),

            // 2. Metrics Cards Skeleton (Responsive 4/2/1 cols)
            const DashboardMetricsSkeleton(),
            const SizedBox(height: 16),

            // 3. Secondary Toolbar Skeleton
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ShimmerBox(width: 140, height: 34),
                      SizedBox(width: 12),
                      ShimmerBox(width: 200, height: 34),
                    ],
                  ),
                  ShimmerBox(width: 60, height: 34),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Cards or List Rows Skeleton
            if (isGridView)
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  int crossAxis = 3;
                  if (width < 650) {
                    crossAxis = 1;
                  } else if (width < 1050) {
                    crossAxis = 2;
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: crossAxis * 2,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxis,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 260,
                    ),
                    itemBuilder: (context, index) => const PersonalDocCardSkeleton(),
                  );
                },
              )
            else
              Column(
                children: List.generate(
                  5,
                  (index) => const PersonalDocListTileSkeleton(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Full screen skeleton loader for Favorites screen. Zero bare spinners.
class FavoritesSkeletonView extends StatelessWidget {
  const FavoritesSkeletonView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Toolbar Skeleton (Search box + Category Chips)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ShimmerBox(width: 220, height: 36),
                      SizedBox(width: 12),
                      ShimmerBox(width: 80, height: 28),
                      SizedBox(width: 8),
                      ShimmerBox(width: 90, height: 28),
                      SizedBox(width: 8),
                      ShimmerBox(width: 85, height: 28),
                    ],
                  ),
                  ShimmerBox(width: 100, height: 20),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Responsive Grid of Document Cards Skeleton
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                int crossAxis = 3;
                if (width < 750) {
                  crossAxis = 1;
                } else if (width < 1150) {
                  crossAxis = 2;
                }
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: crossAxis * 2,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxis,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 240,
                  ),
                  itemBuilder: (context, index) => const DocumentCardSkeleton(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for Document PDF and Image Preview Dialogs.
class DocumentPreviewSkeleton extends StatelessWidget {
  const DocumentPreviewSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar Skeleton
          Row(
            children: [
              const ShimmerBox(width: 32, height: 32),
              const SizedBox(width: AppConstants.paddingMedium),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 220, height: 16),
                    SizedBox(height: 6),
                    ShimmerBox(width: 140, height: 12),
                  ],
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              ShimmerBox(
                width: 36,
                height: 36,
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              ),
              const SizedBox(width: AppConstants.paddingSmall),
              ShimmerBox(
                width: 36,
                height: 36,
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          const Divider(height: 1),
          const SizedBox(height: AppConstants.paddingMedium),

          // Main Preview Canvas Skeleton
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShimmerBox(width: 64, height: 64),
                    SizedBox(height: AppConstants.paddingMedium),
                    ShimmerBox(width: 180, height: 16),
                    SizedBox(height: AppConstants.paddingSmall),
                    ShimmerBox(width: 260, height: 12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for a single row item in Settings master configuration tables.
class SettingsItemSkeleton extends StatelessWidget {
  const SettingsItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const ShimmerBox(
            width: 36,
            height: 36,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 160, height: 14),
                SizedBox(height: 6),
                ShimmerBox(width: 220, height: 11),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const ShimmerBox(
            width: 48,
            height: 24,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          const SizedBox(width: 8),
          const ShimmerBox(
            width: 24,
            height: 24,
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
        ],
      ),
    );
  }
}

/// Shimmer card skeleton for active settings tab content.
class SettingsTabSkeleton extends StatelessWidget {
  const SettingsTabSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              if (isNarrow) {
                return const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 200, height: 18),
                    SizedBox(height: 6),
                    ShimmerBox(width: 280, height: 12),
                    SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ShimmerBox(width: 140, height: 34),
                        ShimmerBox(width: 120, height: 34),
                      ],
                    ),
                  ],
                );
              }
              return const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 220, height: 18),
                      SizedBox(height: 6),
                      ShimmerBox(width: 320, height: 12),
                    ],
                  ),
                  Row(
                    children: [
                      ShimmerBox(width: 180, height: 36),
                      SizedBox(width: 12),
                      ShimmerBox(width: 130, height: 36),
                    ],
                  ),
                ],
              );
            },
          ),
          const Divider(height: 28),
          // Skeleton Items
          for (int i = 0; i < 6; i++) ...[
            const SettingsItemSkeleton(),
            if (i < 5) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

/// Full screen skeleton loader for Settings & Master Configuration screen. Zero bare spinners.
class SettingsSkeletonView extends StatelessWidget {
  const SettingsSkeletonView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Tab Bar Skeleton
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(
                        7,
                        (index) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ShimmerBox(
                            width: 140,
                            height: 38,
                            borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Active Tab Content Skeleton Card
                const SettingsTabSkeleton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton for a single row in the Activity & Audit Logs screen.
class ActivityLogRowSkeleton extends StatelessWidget {
  const ActivityLogRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          ShimmerBox(
            width: 38,
            height: 38,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ShimmerBox(width: 120, height: 14),
                    SizedBox(width: 10),
                    ShimmerBox(
                      width: 90,
                      height: 18,
                      borderRadius: BorderRadius.all(Radius.circular(6)),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                ShimmerBox(width: 220, height: 11),
              ],
            ),
          ),
          SizedBox(width: 16),
          ShimmerBox(width: 80, height: 12),
        ],
      ),
    );
  }
}

/// Full screen skeleton loader for Activity & Audit Logs screen. Zero bare spinners.
class ActivityLogsSkeletonView extends StatelessWidget {
  const ActivityLogsSkeletonView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Toolbar Skeleton (Search input + Action filter pills)
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShimmerBox(width: 240, height: 38),
                      ShimmerBox(width: 120, height: 28),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      ShimmerBox(width: 60, height: 28),
                      SizedBox(width: 8),
                      ShimmerBox(width: 75, height: 28),
                      SizedBox(width: 8),
                      ShimmerBox(width: 70, height: 28),
                      SizedBox(width: 8),
                      ShimmerBox(width: 85, height: 28),
                      SizedBox(width: 8),
                      ShimmerBox(width: 70, height: 28),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Log Rows Skeleton
            for (int i = 0; i < 6; i++) ...[
              const ActivityLogRowSkeleton(),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 16),

            // 3. Bottom Pagination Toolbar Skeleton
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShimmerBox(width: 140, height: 14),
                  Row(
                    children: [
                      ShimmerBox(width: 28, height: 28),
                      SizedBox(width: 6),
                      ShimmerBox(width: 28, height: 28),
                      SizedBox(width: 6),
                      ShimmerBox(width: 28, height: 28),
                    ],
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

/// Shimmer skeleton view for Document Upload screen mirroring its 2-column/stacked geometry.
class DocumentUploadSkeletonView extends StatelessWidget {
  const DocumentUploadSkeletonView({super.key});

  Widget _buildDropzoneSkeleton() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShimmerBox(width: 48, height: 48),
          SizedBox(height: 16),
          ShimmerBox(width: 180, height: 16),
          SizedBox(height: 8),
          ShimmerBox(width: 260, height: 12),
        ],
      ),
    );
  }

  Widget _buildCompressionSkeleton() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBox(width: 150, height: 16),
              ShimmerBox(width: 50, height: 24),
            ],
          ),
          SizedBox(height: 12),
          ShimmerBox(width: 220, height: 12),
          SizedBox(height: 16),
          Row(
            children: [
              ShimmerBox(width: 80, height: 32),
              SizedBox(width: 8),
              ShimmerBox(width: 80, height: 32),
              SizedBox(width: 8),
              ShimmerBox(width: 80, height: 32),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityBadgeSkeleton() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: 24, height: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 160, height: 14),
                SizedBox(height: 6),
                ShimmerBox(width: double.infinity, height: 11),
                SizedBox(height: 4),
                ShimmerBox(width: 200, height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingExtraLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(width: 240, height: 18),
          const SizedBox(height: 8),
          const ShimmerBox(width: 320, height: 12),
          const Divider(height: 32),

          // Category Dropdown Skeleton
          const ShimmerBox(width: 130, height: 13),
          const SizedBox(height: 8),
          const ShimmerBox(width: double.infinity, height: 48),
          const SizedBox(height: 18),

          // Subcategory Dropdown Skeleton
          const ShimmerBox(width: 150, height: 13),
          const SizedBox(height: 8),
          const ShimmerBox(width: double.infinity, height: 48),
          const SizedBox(height: 18),

          // Title Field Skeleton
          const ShimmerBox(width: 120, height: 13),
          const SizedBox(height: 8),
          const ShimmerBox(width: double.infinity, height: 48),
          const SizedBox(height: 18),

          // Description Field Skeleton
          const ShimmerBox(width: 200, height: 13),
          const SizedBox(height: 8),
          const ShimmerBox(width: double.infinity, height: 80),
          const SizedBox(height: 24),

          // Metadata Card Skeleton
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ShimmerBox(width: 20, height: 20),
                    SizedBox(width: 8),
                    ShimmerBox(width: 140, height: 14),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: ShimmerBox(height: 44)),
                    SizedBox(width: 12),
                    Expanded(child: ShimmerBox(height: 44)),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: ShimmerBox(height: 44)),
                    SizedBox(width: 12),
                    Expanded(child: ShimmerBox(height: 44)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Submit Button Skeleton
          const ShimmerBox(width: double.infinity, height: 48),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingExtraLarge),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop =
                    constraints.maxWidth >= AppConstants.desktopBreakpoint;

                if (isDesktop) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Dropzone & Info
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            _buildDropzoneSkeleton(),
                            _buildCompressionSkeleton(),
                            _buildSecurityBadgeSkeleton(),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingExtraLarge),

                      // Right Column: Form Card
                      Expanded(
                        flex: 6,
                        child: _buildFormCardSkeleton(),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildDropzoneSkeleton(),
                      _buildCompressionSkeleton(),
                      _buildSecurityBadgeSkeleton(),
                      const SizedBox(height: AppConstants.paddingExtraLarge),
                      _buildFormCardSkeleton(),
                    ],
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
