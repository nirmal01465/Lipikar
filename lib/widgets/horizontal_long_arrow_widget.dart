import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/finances_colors.dart';

class AnimatedHorizontalArrowWidget extends StatefulWidget {
  const AnimatedHorizontalArrowWidget({Key? key}) : super(key: key);

  @override
  _AnimatedHorizontalArrowWidgetState createState() => _AnimatedHorizontalArrowWidgetState();
}

class _AnimatedHorizontalArrowWidgetState extends State<AnimatedHorizontalArrowWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _firstSegmentAnimation;
  late Animation<double> _secondSegmentAnimation;
  late Animation<double> _thirdSegmentAnimation;
  late Animation<double> _expandedSegmentAnimation;

  @override
  void initState() {
    super.initState();
    // Duration can be adjusted as needed.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Animate the first segment from width 0 to 40.
    _firstSegmentAnimation = Tween<double>(begin: 0, end: 40).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );
    // Animate the second segment from 0 to 25.
    _secondSegmentAnimation = Tween<double>(begin: 0, end: 25).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.5, curve: Curves.easeOut),
      ),
    );
    // Animate the third segment from 0 to 25.
    _thirdSegmentAnimation = Tween<double>(begin: 0, end: 25).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.7, curve: Curves.easeOut),
      ),
    );
    // Animate the expanded segment: you might animate its width or a factor for the Expanded widget.
    // Here we use a factor from 0 to 1 to indicate animation progress.
    _expandedSegmentAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start the animation when the widget is inserted in the tree.
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use AnimatedBuilder to rebuild the UI when the animation value changes.
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            children: [
              Container(
                height: 3.7,
                width: _firstSegmentAnimation.value,
                decoration: BoxDecoration(
                  color: DocAppColors.purple,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                height: 3.7,
                width: _secondSegmentAnimation.value,
                decoration: BoxDecoration(
                  color: DocAppColors.purple,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                height: 3.7,
                width: _thirdSegmentAnimation.value,
                decoration: BoxDecoration(
                  color: DocAppColors.purple,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(width: 30),
              Expanded(
                child: Container(
                  height: 3.7,
                  // Here, the width is animated via a fraction of available space.
                  // When _expandedSegmentAnimation.value is 1, it fills the available width.
                  width: MediaQuery.of(context).size.width * _expandedSegmentAnimation.value,
                  decoration: BoxDecoration(
                    color: DocAppColors.purple,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 45,
                width: 70,
                child: Stack(
                  children: [
                    Positioned(
                      left: 59.6,
                      child: Transform.rotate(
                        angle: pi * 1.8,
                        child: Container(
                          width: 3.7,
                          height: 25,
                          decoration: BoxDecoration(
                            color: DocAppColors.purple,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // This segment remains static but you could animate its properties too.
                          Container(
                            height: 3.7,
                            width: 75,
                            decoration: BoxDecoration(
                              color: DocAppColors.purple,
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
            ],
          );
        },
      ),
    );
  }
}
