import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerWrapper extends StatelessWidget {
  final Widget child;

  const ShimmerWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDarkMode
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFE0E0E0);
    
    final highlightColor = isDarkMode
        ? const Color(0xFF2D2D2D)
        : const Color(0xFFF5F5F5);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: child,
    );
  }
}

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class SkeletonLine extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonLine({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 4,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class SkeletonCircle extends StatelessWidget {
  final double size;
  final EdgeInsetsGeometry? margin;

  const SkeletonCircle({
    super.key,
    this.size = 48,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      margin: margin,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

// SPECIFIC SKELETON PRESETS FOR PREMIUM UX
class OrderHistorySkeleton extends StatelessWidget {
  const OrderHistorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonLine(width: 140, height: 16),
                      const SizedBox(height: 8),
                      const SkeletonLine(width: 100, height: 12),
                      const SizedBox(height: 8),
                      Container(
                        width: 70,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SkeletonLine(width: 50, height: 16),
                    SizedBox(height: 12),
                    SkeletonBox(width: 12, height: 12, borderRadius: 2),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ProductDetailSkeleton extends StatelessWidget {
  const ProductDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Aspect ratio placeholder for hero image
            const SkeletonBox(
              width: double.infinity,
              height: 480,
              borderRadius: 0,
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonLine(width: 80, height: 12),
                  const SizedBox(height: 8),
                  const SkeletonLine(width: 220, height: 22),
                  const SizedBox(height: 12),
                  const SkeletonLine(width: 120, height: 18),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 20),
                  const SkeletonLine(width: 60, height: 14),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(
                      4,
                      (index) => Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SkeletonLine(width: 100, height: 14),
                  const SizedBox(height: 10),
                  const SkeletonLine(width: double.infinity, height: 12),
                  const SizedBox(height: 6),
                  const SkeletonLine(width: double.infinity, height: 12),
                  const SizedBox(height: 6),
                  const SkeletonLine(width: 180, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderTrackingSkeleton extends StatelessWidget {
  const OrderTrackingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonLine(width: 140, height: 22),
            const SizedBox(height: 12),
            const SkeletonLine(width: 180, height: 14),
            const SizedBox(height: 40),
            Column(
              children: List.generate(3, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonCircle(size: 24),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SkeletonLine(width: 120, height: 14),
                            const SizedBox(height: 6),
                            const SkeletonLine(width: 80, height: 11),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreenSkeleton extends StatelessWidget {
  const HomeScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar skeleton
            Container(
              margin: const EdgeInsets.fromLTRB(16, 60, 16, 16),
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            // Hero banner slider skeleton
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(height: 24),
            // Discover Categories title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: SkeletonLine(width: 180, height: 16),
            ),
            const SizedBox(height: 12),
            // Category horizontal list
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 16),
                    width: 72,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            // Trending Edits title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: SkeletonLine(width: 140, height: 16),
            ),
            const SizedBox(height: 16),
            // Product grid skeleton
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.49,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const SkeletonLine(width: 40, height: 10),
                    const SizedBox(height: 6),
                    const SkeletonLine(width: 100, height: 12),
                    const SizedBox(height: 6),
                    const SkeletonLine(width: 50, height: 12),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
