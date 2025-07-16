import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../utils/finances_colors.dart';
import '../widgets/bar_chart_widget.dart';
import '../widgets/monthlysales.dart';
import '../widgets/weekly_monthly_tab_widget.dart';

class DocumentScanHistoryPage extends StatefulWidget {
  const DocumentScanHistoryPage({Key? key}) : super(key: key);

  @override
  _DocumentScanHistoryPageState createState() => _DocumentScanHistoryPageState();
}

class _DocumentScanHistoryPageState extends State<DocumentScanHistoryPage> {
  // Dummy list of all scan history entries.
  List<ScanHistory> allScans = dummyScanHistory;
  // List to display after filtering.
  List<ScanHistory> filteredScans = [];
  String selectedFilter = "All";
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    filteredScans = allScans;
  }

  void filterScans(String filter) {
    setState(() {
      selectedFilter = filter;
      if (filter == "All") {
        filteredScans = allScans;
      } else {
        filteredScans = allScans.where((scan) => scan.scanType == filter).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Scan History"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Additional filter actions can be added here.
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric( vertical: 20),
        children: [
          // Overall Scan Statistics
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              'Total Scans',
              style: TextStyle(
                color: DocAppColors.purple,
                fontSize: isTablet ? 28 : 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Row(
              children: [
                _buildStatCard("Weekly", "45", DocAppColors.lightBlue, context),
                _buildStatCard("Monthly", "180", DocAppColors.lightOrange, context),
                _buildStatCard("Overall", "520", DocAppColors.lightPurple, context),
              ],
            ),
          ),
          const SizedBox(height: 25),
          // Dummy Bar Chart for Scan Activity
          Container(
            height: 400,
            // height: isTablet ? 250 : 180,
            child:  _selectedTabIndex == 0
                ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30,vertical: 8),
                  child: BarChartWidget(
                                percentages: [45, 60, 70, 50, 90, 100, 75],
                              ),
                )
                : MonthlySalesLineChartPage(),
          ),
          const SizedBox(height: 25),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: WeeklyMonthlyTabWidget(
              text1: 'Weekly',
              text2: 'Monthly',
              onTabChanged: (index) {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
            ),
          ),
          const SizedBox(height: 25),
          // Advanced Filter Dropdown using dropdown_button2 package
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: DropdownButtonHideUnderline(
              child: DropdownButton2<String>(
                isExpanded: true,
                value: selectedFilter,
                hint: Text(
                  'Select Scan Type',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    color: DocAppColors.purple,
                  ),
                ),
                items: ["All", "Document", "Image", "Receipt"].map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(
                      type,
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        color: DocAppColors.purple,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    filterScans(value);
                  }
                },
                // buttonHeight: isTablet ? 60 : 50,
                // buttonWidth: double.infinity,
                // itemHeight: isTablet ? 60 : 50,
                // dropdownMaxHeight: 200,
                // dropdownWidth: screenWidth * 0.8,
                // buttonDecoration: BoxDecoration(
                //   borderRadius: BorderRadius.circular(15),
                //   border: Border.all(color: DocAppColors.purple.withOpacity(0.5)),
                //   color: Colors.white,
                // ),
                // dropdownDecoration: BoxDecoration(
                //   borderRadius: BorderRadius.circular(15),
                //   color: Colors.white,
                // ),
                // icon: Icon(Icons.arrow_drop_down, color: DocAppColors.purple),
                // iconSize: isTablet ? 30 : 24,
              ),
            ),
          ),
          const SizedBox(height: 25),
          // Section Header for Scan History List
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              'Scan History',
              style: TextStyle(
                color: DocAppColors.purple,
                fontSize: isTablet ? 26 : 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 15),
          // Animated list of scan history items using flutter_staggered_animations.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: AnimationLimiter(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredScans.length,
                itemBuilder: (context, index) {
                  final scan = filteredScans[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    delay: const Duration(milliseconds: 100),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: ScanHistoryItemWidget(
                            scanHistory: scan,
                            isTablet: isTablet,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String count, Color color, BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Updated dummy data model for scan history items with additional fields.
class ScanHistory {
  final String scanType; // e.g., "Image", "Document", "Receipt"
  final String dateTime; // e.g., "2025-03-01 09:15 AM"
  final String detectedLanguage; // e.g., "English"
  final String translatedLanguage; // e.g., "Spanish"
  final String extractedData; // Summary of extracted content
  final IconData iconData;
  final Color backgroundColor;

  ScanHistory({
    required this.scanType,
    required this.dateTime,
    required this.detectedLanguage,
    required this.translatedLanguage,
    required this.extractedData,
    required this.iconData,
    required this.backgroundColor,
  });
}

// Large dummy list of scan history entries.
final List<ScanHistory> dummyScanHistory = List.generate(20, (index) {
  // Generating sample data with variety.
  final types = ["Document", "Image", "Receipt"];
  final languages = ["English", "Spanish", "French", "German"];
  final randomType = types[index % types.length];
  final detectedLang = languages[index % languages.length];
  final translatedLang = languages[(index + 1) % languages.length];
  return ScanHistory(
    scanType: randomType,
    dateTime: "2025-03-${(index % 28) + 1} ${9 + index % 5}:${(index % 60).toString().padLeft(2, '0')} ${index % 2 == 0 ? 'AM' : 'PM'}",
    detectedLanguage: detectedLang,
    translatedLanguage: translatedLang,
    extractedData: "Extracted content summary for scan item #$index, showcasing details and analysis.",
    iconData: randomType == "Document"
        ? Icons.description
        : randomType == "Image"
        ? Icons.image
        : Icons.receipt,
    backgroundColor: randomType == "Document"
        ? Colors.blue.shade100
        : randomType == "Image"
        ? Colors.orange.shade100
        : Colors.green.shade100,
  );
});

// Widget to display each scan history item with extra fields.
class ScanHistoryItemWidget extends StatelessWidget {
  final ScanHistory scanHistory;
  final bool isTablet;

  const ScanHistoryItemWidget({
    required this.scanHistory,
    required this.isTablet,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: isTablet ? 80 : 60,
            height: isTablet ? 80 : 60,
            decoration: BoxDecoration(
              color: scanHistory.backgroundColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              scanHistory.iconData,
              color: DocAppColors.purple,
              size: isTablet ? 40 : 30,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scanHistory.scanType,
                  style: TextStyle(
                    color: DocAppColors.purple,
                    fontSize: isTablet ? 20 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  scanHistory.dateTime,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: isTablet ? 18 : 14,
                  ),
                ),
                const SizedBox(height: 5),
                Column(
                  children: [
                    Text(
                      "Detected: ${scanHistory.detectedLanguage}",
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: isTablet ? 16 : 13,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Translated: ${scanHistory.translatedLanguage}",
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: isTablet ? 16 : 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  scanHistory.extractedData,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: DocAppColors.purple,
                    fontSize: isTablet ? 18 : 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
