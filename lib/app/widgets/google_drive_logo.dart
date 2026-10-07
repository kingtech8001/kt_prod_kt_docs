import 'package:flutter/material.dart';

/// Pixel-perfect vector implementation of the official Google Drive logo.
/// Clean, high-DPI custom painter with official Google brand colors.
class GoogleDriveLogo extends StatelessWidget {
  final double size;

  const GoogleDriveLogo({
    super.key,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: const _GoogleDrivePainter(),
      ),
    );
  }
}

class _GoogleDrivePainter extends CustomPainter {
  const _GoogleDrivePainter();

  // Official Google Drive brand colors
  static const Color yellowColor = Color(0xFFFFBA00);
  static const Color greenColor = Color(0xFF00AC47);
  static const Color blueColor = Color(0xFF0066DA);

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Google Drive logo geometry is an equilateral triangle with 3 interlocking bands.
    // 1. Top-Right band (Yellow):
    // From apex heading down-right, with overlapping angles.
    final Path yellowPath = Path();
    yellowPath.moveTo(w * 0.36, h * 0.08);
    yellowPath.lineTo(w * 0.64, h * 0.08);
    yellowPath.lineTo(w * 0.96, h * 0.64);
    yellowPath.lineTo(w * 0.82, h * 0.88);
    yellowPath.lineTo(w * 0.68, h * 0.64);
    yellowPath.lineTo(w * 0.50, h * 0.32);
    yellowPath.close();

    paint.color = yellowColor;
    canvas.drawPath(yellowPath, paint);

    // 2. Bottom band (Green):
    // Horizontal band across the base
    final Path greenPath = Path();
    greenPath.moveTo(w * 0.22, h * 0.88);
    greenPath.lineTo(w * 0.82, h * 0.88);
    greenPath.lineTo(w * 0.68, h * 0.64);
    greenPath.lineTo(w * 0.32, h * 0.64);
    greenPath.lineTo(w * 0.18, h * 0.88);
    greenPath.close();

    paint.color = greenColor;
    canvas.drawPath(greenPath, paint);

    // 3. Left band (Blue):
    // From apex heading down-left to base
    final Path bluePath = Path();
    bluePath.moveTo(w * 0.36, h * 0.08);
    bluePath.lineTo(w * 0.50, h * 0.32);
    bluePath.lineTo(w * 0.32, h * 0.64);
    bluePath.lineTo(w * 0.04, h * 0.64);
    bluePath.lineTo(w * 0.18, h * 0.40);
    bluePath.close();

    paint.color = blueColor;
    canvas.drawPath(bluePath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A compact, standardized Google Drive badge widget for cards and lists.
class GoogleDriveBadge extends StatelessWidget {
  final bool compact;

  const GoogleDriveBadge({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFF86EFAC),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GoogleDriveLogo(size: compact ? 12 : 14),
          const SizedBox(width: 5),
          Text(
            'Google Drive',
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF15803D),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
