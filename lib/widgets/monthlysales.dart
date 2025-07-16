import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../utils/finances_colors.dart';

class MonthlySalesLineChartPage extends StatefulWidget {
  const MonthlySalesLineChartPage({Key? key}) : super(key: key);

  @override
  State<MonthlySalesLineChartPage> createState() => _MonthlySalesLineChartPageState();
}

class _MonthlySalesLineChartPageState extends State<MonthlySalesLineChartPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Sample data for three different lines (e.g. for Image, Document, Receipt)
  final List<double> _line1Data = [
    12, 20, 23, 30, 58, 35, 29, 41, 38, 36,
    42, 45, 48, 38, 33, 40, 16, 70, 51, 39,
    42, 44, 49, 55, 52, 16, 60, 47, 53, 22
  ];
  final List<double> _line2Data = [
    20, 51, 22, 36, 24, 30, 25, 28, 30, 12,
    5, 36, 19, 40, 36, 18, 53, 41, 47, 59,
    50, 52, 45, 51, 52, 34, 57, 59, 40, 55
  ];
  final List<double> _line3Data = [
    18, 16, 15, 20, 24, 26, 22, 25, 29, 32,
    36, 34, 39, 21, 37, 40, 32, 45, 68, 46,
    42, 54, 46, 30, 39, 61, 52, 45, 13, 38
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Helper to build a gradient line with animated data
  LineChartBarData _buildLineChartBarData({
    required List<double> data,
    required List<Color> colorGradient,
  }) {
    return LineChartBarData(
      spots: data.asMap().entries.map((entry) {
        // Animate x axis as days 1 to 30; animate y values using the animation factor
        final day = (entry.key + 1).toDouble();
        final value = entry.value * _animation.value;
        return FlSpot(day, value);
      }).toList(),
      isCurved: true,
      curveSmoothness: 0.2,
      gradient: LinearGradient(
        colors: colorGradient,
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      barWidth: 4,
      dotData: FlDotData(show: true),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: colorGradient.map((c) => c.withOpacity(0.3)).toList(),
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  /// Helper to build a simple legend item
  Widget _buildLegendItem(String title, List<Color> gradientColors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 10,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color:Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return LineChart(
                  LineChartData(
                    minX: 1,
                    maxX: 30,
                    minY: 0,
                    maxY: 70,
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        // tooltipBgColor: Colors.black87,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((LineBarSpot spot) {
                            return LineTooltipItem(
                              'Day ${spot.x.toInt()}\nValue: ${spot.y.toStringAsFixed(2)}',
                              const TextStyle(color: Colors.white),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      horizontalInterval: 10,
                      verticalInterval: 5,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.black.withOpacity(0.2),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(
                        color: Colors.black.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        axisNameWidget: const Text(
                          'Days',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: 5,
                          getTitlesWidget: (value, meta) {
                            if (value % 5 == 0) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        axisNameWidget: const Text(
                          'Total Scans',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: 10,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    lineBarsData: [
                      _buildLineChartBarData(
                        data: _line1Data,
                        colorGradient: const [
                          Color(0xFFff8a65),
                          Color(0xFFff5757),
                        ],
                      ),
                      _buildLineChartBarData(
                        data: _line2Data,
                        colorGradient: const [
                          Color(0xFF80deea),
                          Color(0xFF2979ff),
                        ],
                      ),
                      _buildLineChartBarData(
                        data: _line3Data,
                        colorGradient: const [
                          Color(0xFFa7ffeb),
                          Color(0xFF64ffda),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildLegendItem(
                'Image',
                const [Color(0xFFff8a65), Color(0xFFff5757)],
              ),
              _buildLegendItem(
                'Document',
                const [Color(0xFF80deea), Color(0xFF2979ff)],
              ),
              _buildLegendItem(
                'Receipt',
                const [Color(0xFFa7ffeb), Color(0xFF64ffda)],
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
