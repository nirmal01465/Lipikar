import 'package:flutter/material.dart';
import '../widgets/ocr_overview_model.dart';
import 'finances_colors.dart';

/// Advanced painter for drawing precisely-fitted polygons around OCR-detected text
class EnhancedTextBoundaryPainter extends CustomPainter {
  final OcrViewModel viewModel;

  EnhancedTextBoundaryPainter({
    required this.viewModel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Paint for unselected boundaries
    final Paint defaultPaint = Paint()
      ..color = Colors.green.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Paint for selected boundary with pulse effect
    final Paint selectedPaint = Paint()
      ..color = DocAppColors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 + (viewModel.pulseValue * 2.0);

    // Paint for selected highlight
    final Paint highlightPaint = Paint()
      ..color = DocAppColors.orange.withOpacity(0.2 + (viewModel.pulseValue * 0.1))
      ..style = PaintingStyle.fill;

    // Draw each word's polygon
    for (int i = 0; i < viewModel.wordElements.length; i++) {
      final polygonPoints = viewModel.enhancedPolygons[i];
      if (polygonPoints == null || polygonPoints.isEmpty) continue;

      // Create path from scaled polygon points
      final path = Path();

      // Scale points according to scaleFactor and apply pulse effect for selected word
      final isSelected = i == viewModel.selectedWordIndex;
      List<Offset> scaledPoints;

      if (isSelected) {
        // For selected words, apply pulse effect by scaling from the center
        final centerX = polygonPoints.fold<double>(0, (sum, point) => sum + point.dx) / polygonPoints.length;
        final centerY = polygonPoints.fold<double>(0, (sum, point) => sum + point.dy) / polygonPoints.length;

        // Apply pulse effect (expand/contract)
        final pulseScale = 1.0 + (viewModel.pulseValue * 0.05);

        scaledPoints = polygonPoints.map((point) {
          // Distance from center
          final dx = point.dx - centerX;
          final dy = point.dy - centerY;

          // Apply scaling with pulse effect
          return Offset(
            (centerX + dx * pulseScale) * viewModel.scaleFactor,
            (centerY + dy * pulseScale) * viewModel.scaleFactor,
          );
        }).toList();
      } else {
        // Regular scaling for non-selected words
        scaledPoints = polygonPoints.map((point) =>
            Offset(
              point.dx * viewModel.scaleFactor,
              point.dy * viewModel.scaleFactor,
            )
        ).toList();
      }

      // Draw the polygon path
      if (scaledPoints.isNotEmpty) {
        path.moveTo(scaledPoints[0].dx, scaledPoints[0].dy);
        for (int j = 1; j < scaledPoints.length; j++) {
          path.lineTo(scaledPoints[j].dx, scaledPoints[j].dy);
        }
        path.close();

        // Fill and stroke with appropriate styling
        if (isSelected) {
          canvas.drawPath(path, highlightPaint);
          canvas.drawPath(path, selectedPaint);
        } else {
          canvas.drawPath(path, defaultPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant EnhancedTextBoundaryPainter oldDelegate) {
    return oldDelegate.viewModel != viewModel ||
        oldDelegate.viewModel.pulseValue != viewModel.pulseValue ||
        oldDelegate.viewModel.selectedWordIndex != viewModel.selectedWordIndex ||
        oldDelegate.viewModel.scaleFactor != viewModel.scaleFactor;
  }
}