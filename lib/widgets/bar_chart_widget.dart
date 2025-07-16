import 'package:flutter/material.dart';
import '../utils/finances_colors.dart';

class BarChartWidget extends StatefulWidget {
  final List<double> percentages;
  const BarChartWidget({
    Key? key,
    required this.percentages,
  }) :
        assert(percentages.length == 7),
        super(key: key);

  static const List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  State<BarChartWidget> createState() => _BarChartWidgetState();
}

class _BarChartWidgetState extends State<BarChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _barAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _barAnimations = widget.percentages.map((percentage) {
      return Tween<double>(begin: 0.0, end: percentage).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOutCubic,
        ),
      );
    }).toList();

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getColorForValue(double value) {
    if (value < 40) {
      return DocAppColors.lightBlue;
    } else if (value < 70) {
      return DocAppColors.lightOrange;
    } else {
      return DocAppColors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Weekly Scan Activity',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: DocAppColors.purple,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(widget.percentages.length, (index) {
                    final currentValue = _barAnimations[index].value;
                    final Color barColor = _getColorForValue(currentValue);
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Display the animated value
                        Text(
                          currentValue.toInt().toString(),
                          style: TextStyle(
                            color: DocAppColors.purple.withOpacity(0.7),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 5),
                        // Animated bar
                        Container(
                          width: 30,
                          height: (currentValue / 100) * 200,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                barColor.withOpacity(0.7),
                                barColor,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: barColor.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Day label
                        Text(
                          BarChartWidget.days[index],
                          style: TextStyle(
                            color: DocAppColors.purple.withOpacity(0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
