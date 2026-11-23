import 'package:flutter/material.dart';
import 'package:kt_prod_kt_docs/app/widgets/app_shimmer.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';

/// Mirrors the header, summary cards and editable fields of detail screens.
class DetailSkeleton extends StatelessWidget {
  const DetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth < AppConstants.tabletBreakpoint
          ? 1
          : constraints.maxWidth <= AppConstants.desktopBreakpoint
          ? 2
          : 4;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: AppShimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ShimmerBox(height: AppConstants.detailSkeletonHeaderHeight),
              const SizedBox(height: AppConstants.paddingLarge),
              Wrap(
                spacing: AppConstants.paddingMedium,
                runSpacing: AppConstants.paddingMedium,
                children: List.generate(
                  AppConstants.detailSkeletonFieldCount,
                  (_) => SizedBox(
                    width:
                        ((constraints.maxWidth -
                                    AppConstants.paddingLarge * 2 -
                                    AppConstants.paddingMedium *
                                        (columns - 1)) /
                                columns)
                            .clamp(0.0, double.infinity),
                    child: const ShimmerBox(
                      height: AppConstants.detailSkeletonFieldHeight,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.paddingLarge),
              const ShimmerBox(height: AppConstants.detailSkeletonNotesHeight),
            ],
          ),
        ),
      );
    },
  );
}
