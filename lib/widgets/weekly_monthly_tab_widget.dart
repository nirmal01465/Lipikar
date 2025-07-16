import 'package:flutter/material.dart';
import '../utils/finances_colors.dart';

class WeeklyMonthlyTabWidget extends StatefulWidget {
  final String text1;
  final String text2;
  final int defaultSelectedIndex;
  final ValueChanged<int>? onTabChanged;

  const WeeklyMonthlyTabWidget({
    Key? key,
    required this.text1,
    required this.text2,
    this.defaultSelectedIndex = 0,
    this.onTabChanged,
  }) : super(key: key);

  @override
  State<WeeklyMonthlyTabWidget> createState() => _WeeklyMonthlyTabWidgetState();
}

class _WeeklyMonthlyTabWidgetState extends State<WeeklyMonthlyTabWidget> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.defaultSelectedIndex;
  }

  Widget _buildTab({
    required String text,
    required int index,
    required bool left,
    required bool right,
  }) {
    return Positioned(
      top: 0,
      bottom: 0,
      left: left ? 0 : null,
      right: right ? 0 : null,
      width: (MediaQuery.of(context).size.width / 2) - 25,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
          if (widget.onTabChanged != null) {
            widget.onTabChanged!(index);
          }
        },
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 450),
            style: TextStyle(
              color: _selectedIndex == index ? Colors.white : DocAppColors.purple,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            child: Text(text),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double tabWidth = (MediaQuery.of(context).size.width / 2) - 25;
    return Container(
      height: 70,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: DocAppColors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(35),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            top: 0,
            left: _selectedIndex == 0 ? 0 : (MediaQuery.of(context).size.width / 2) - 40,
            bottom: 0,
            width: tabWidth,
            child: Container(
              decoration: BoxDecoration(
                color: DocAppColors.purple,
                borderRadius: BorderRadius.circular(35),
              ),
            ),
          ),
          _buildTab(text: widget.text1, index: 0, left: true, right: false),
          _buildTab(text: widget.text2, index: 1, left: false, right: true),
        ],
      ),
    );
  }
}
