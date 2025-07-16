import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/finances_colors.dart';

class CollapsibleHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double expandedHeight;
  final double collapsedHeight;
  final bool isCollapsed;
  final File? image;
  final String title;
  final String subtitle;

  CollapsibleHeaderDelegate({
    required this.expandedHeight,
    required this.collapsedHeight,
    required this.isCollapsed,
    required this.image,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double percent = shrinkOffset / (maxExtent - minExtent);
    final double currentHeight = maxExtent - shrinkOffset;

    return Container(
      height: currentHeight,
      decoration: BoxDecoration(
        color: DocAppColors.lightPurple,
        boxShadow: isCollapsed
            ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ]
            : [],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background with gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  DocAppColors.purple.withOpacity(0.7),
                  DocAppColors.lightPurple.withOpacity(0.9),
                ],
              ),
            ),
          ),

          // Scanned image with animation
          Positioned.fill(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: 1.0 - percent.clamp(0.0, 0.7),
              child: Center(
                child: image != null
                    ? Hero(
                  tag: 'scanned_image',
                  child: Container(
                    margin: EdgeInsets.all(isCollapsed ? 8 : 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        image!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                )
                    : Container(
                  margin: EdgeInsets.all(isCollapsed ? 8 : 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[300],
                  ),
                  child: const Icon(
                    Icons.image_not_supported,
                    size: 80,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),

          // Collapsed header content
          Positioned(
            left: 16,
            top: isCollapsed ? 18 : 40 + 200 * (1 - percent).clamp(0.0, 1.0),
            right: 100,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: isCollapsed ? 1.0 : 0.0,
              child: Row(
                children: [
                  if (isCollapsed && image != null)
                    Container(
                      height: 45,
                      width: 45,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          image!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Back button with animation
          Positioned(
            top: isCollapsed ? 18 : 40,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // Share button with animation
          Positioned(
            top: isCollapsed ? 18 : 40,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: () {
                // Share functionality
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => collapsedHeight;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}