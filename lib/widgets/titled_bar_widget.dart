import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/finances_colors.dart';

class AnimatedTiltedBarWidget extends StatefulWidget {
  const AnimatedTiltedBarWidget({Key? key}) : super(key: key);

  @override
  _AnimatedTiltedBarWidgetState createState() =>
      _AnimatedTiltedBarWidgetState();
}

class _AnimatedTiltedBarWidgetState
    extends State<AnimatedTiltedBarWidget> with TickerProviderStateMixin {
  late AnimationController _barsController;
  late AnimationController _ballController;

  // Bar animations (for right offset) – using staggered intervals
  late Animation<double> _bar1Animation;
  late Animation<double> _bar2Animation;
  late Animation<double> _bar3Animation;
  late Animation<double> _bar4Animation;

  // Ball animations for horizontal (x) and vertical (y) movement.
  late Animation<double> _ballXAnimation;
  late Animation<double> _ballYAnimation;

  static const int gap = 25;

  @override
  void initState() {
    super.initState();

    // Controller for bars animation
    _barsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Controller for ball animation (a longer duration for multiple bounces)
    _ballController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Animate each bar's right offset from off-screen to its final position.
    _bar1Animation = Tween<double>(begin: 100, end: 10).animate(
      CurvedAnimation(
        parent: _barsController,
        curve: Curves.easeOutBack,
      ),
    );
    _bar2Animation = Tween<double>(begin: 100, end: 40 + (gap * 1.15)).animate(
      CurvedAnimation(
        parent: _barsController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
      ),
    );
    _bar3Animation = Tween<double>(begin: 100, end: 60 + (gap * 2.7)).animate(
      CurvedAnimation(
        parent: _barsController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutBack),
      ),
    );
    _bar4Animation = Tween<double>(begin: 100, end: 60 + (gap * 5.5)).animate(
      CurvedAnimation(
        parent: _barsController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOutBack),
      ),
    );

    // Ball horizontal movement: from left: 32 to left: 120.
    // This path can be adjusted so the ball "meets" the bars.
    _ballXAnimation = Tween<double>(begin: 32, end: 120).animate(
      CurvedAnimation(
        parent: _ballController,
        curve: Curves.easeInOut,
      ),
    );

    // Ball vertical movement (bouncing) defined as a sequence of motions.
    // Starting at y = 72 ("ground"), the ball bounces upward then falls,
    // with each subsequent bounce being lower—simulating a realistic collision.
    _ballYAnimation = TweenSequence<double>([
      // First bounce: from ground (72) to a high point (32)
      TweenSequenceItem(
        tween: Tween<double>(begin: 72, end: 32)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      // Fall back down to ground
      TweenSequenceItem(
        tween: Tween<double>(begin: 32, end: 72)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
      // Second bounce: a smaller bounce (simulate collision with a bar)
      TweenSequenceItem(
        tween: Tween<double>(begin: 72, end: 45)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      // Fall again
      TweenSequenceItem(
        tween: Tween<double>(begin: 45, end: 72)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 15,
      ),
      // A final minor bounce before settling
      TweenSequenceItem(
        tween: Tween<double>(begin: 72, end: 60)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 10,
      ),
    ]).animate(_ballController);

    // Start animations
    _barsController.forward();
    _ballController.repeat();
  }

  @override
  void dispose() {
    _barsController.dispose();
    _ballController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: AnimatedBuilder(
        animation: Listenable.merge([_barsController, _ballController]),
        builder: (context, child) {
          return Stack(
            children: [
              // Bar 1
              Positioned(
                top: 5,
                bottom: 5,
                right: _bar1Animation.value,
                child: Container(
                  height: 190,
                  width: 30,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        DocAppColors.lightPurple,
                        DocAppColors.lightGrey,
                      ],
                      stops: [0.05, 0.4],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              // Bar 2
              Positioned(
                top: 5,
                bottom: 5,
                right: _bar2Animation.value,
                child: Container(
                  height: 190,
                  width: 30,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        DocAppColors.purple,
                        DocAppColors.green,
                      ],
                      stops: [0.001, 0.3],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              // Bar 3 with rotation
              Positioned(
                top: 5,
                bottom: 3,
                right: _bar3Animation.value,
                child: Transform.rotate(
                  angle: pi * 2.1,
                  child: Container(
                    height: 190,
                    width: 30,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          DocAppColors.orange,
                          DocAppColors.lightPurple,
                        ],
                        stops: [0.03, 0.25],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              // Bar 4 with rotation
              Positioned(
                top: 10,
                right: _bar4Animation.value,
                child: Transform.rotate(
                  angle: pi * 2.223,
                  child: Container(
                    height: 205,
                    width: 30,
                    decoration: BoxDecoration(
                      color: DocAppColors.purple,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              // Bouncing ball with both horizontal (x) and vertical (y) animations.
              Positioned(
                left: _ballXAnimation.value,
                top: _ballYAnimation.value,
                child: Transform.rotate(
                  angle: pi * 2.223,
                  child: Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          DocAppColors.orange,
                          DocAppColors.lightOrange,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
