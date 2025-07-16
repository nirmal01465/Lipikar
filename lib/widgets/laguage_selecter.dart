import 'package:flutter/material.dart';
import '../utils/finances_colors.dart';

class LanguageSelector extends StatefulWidget {
  final String currentLanguage;
  final List<String> availableLanguages;
  final Function(String) onLanguageSelected;

  const LanguageSelector({
    Key? key,
    required this.currentLanguage,
    required this.availableLanguages,
    required this.onLanguageSelected,
  }) : super(key: key);

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  late String _selectedLanguage;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.currentLanguage;
  }

  @override
  void didUpdateWidget(LanguageSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentLanguage != oldWidget.currentLanguage) {
      _selectedLanguage = widget.currentLanguage;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: DocAppColors.lightPurple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with current language and toggle
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.translate,
                    color: DocAppColors.purple,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Language: $_selectedLanguage',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: DocAppColors.purple,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: DocAppColors.purple,
                  ),
                ],
              ),
            ),
          ),
          // Language options
          AnimatedCrossFade(
            firstChild: const SizedBox(height: 0),
            secondChild: Container(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.availableLanguages.map((language) {
                  final bool isSelected = language == _selectedLanguage;
                  return GestureDetector(
                    onTap: () {
                      if (language != _selectedLanguage) {
                        setState(() {
                          _selectedLanguage = language;
                        });
                        widget.onLanguageSelected(language);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? DocAppColors.purple
                            : DocAppColors.lightPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        language,
                        style: TextStyle(
                          color: isSelected ? Colors.white : DocAppColors.purple,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}
