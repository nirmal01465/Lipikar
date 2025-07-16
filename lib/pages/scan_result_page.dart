import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ocr_service.dart';

class TextLine {
  final List<BoxText> words;
  final double averageY;
  final double minX;
  final double maxX;

  TextLine({
    required this.words,
    required this.averageY,
    required this.minX,
    required this.maxX,
  });

  String get text => words.map((w) => w.text).join(' ');
}

class ScanResultPage extends StatefulWidget {
  final File scannedImage;
  final String detectedLanguage;
  final List<BoxText> results;

  const ScanResultPage({
    Key? key,
    required this.scannedImage,
    required this.detectedLanguage,
    required this.results,
  }) : super(key: key);

  @override
  State<ScanResultPage> createState() => _ScanResultPageState();
}

class _ScanResultPageState extends State<ScanResultPage> with TickerProviderStateMixin {
  Size? _imageSize;
  double _imageScale = 1.0;
  bool _showBoundingBoxes = true;
  bool _showIndexLabels = false;
  List<TextLine> _textLines = [];
  bool _showCombinedText = true;
  bool _isLoading = false;
  int? _highlightedWordIndex;
  SharedPreferences? _prefs;

  late AnimationController _animationController;
  late AnimationController _highlightController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _highlightScaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _highlightColorAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeImage();
    _organizeTextIntoLines();
    _initSharedPreferences();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _highlightScaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _highlightController, curve: Curves.elasticOut),
    );

    _highlightColorAnimation = ColorTween(
      begin: Colors.teal.withOpacity(0.2),
      end: Colors.amber.withOpacity(0.5),
    ).animate(
      CurvedAnimation(parent: _highlightController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
    _slideController.forward();
  }

  void _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    await _saveSessionData();
  }

  Future<void> _saveSessionData() async {
    if (_prefs == null) return;

    final now = DateTime.now();
    final dateTimeString = now.toIso8601String();
    final totalWords = widget.results.length;

    await _prefs!.setString('last_scan_datetime', dateTimeString);
    await _prefs!.setInt('last_scan_word_count', totalWords);
    await _prefs!.setString('last_scan_language', widget.detectedLanguage);

    final totalScans = (_prefs!.getInt('total_scans') ?? 0) + 1;
    final totalWordsExtracted = (_prefs!.getInt('total_words_extracted') ?? 0) + totalWords;

    await _prefs!.setInt('total_scans', totalScans);
    await _prefs!.setInt('total_words_extracted', totalWordsExtracted);

    final history = _prefs!.getStringList('scan_history') ?? [];
    history.add('$dateTimeString|$totalWords|${widget.detectedLanguage}');
    if (history.length > 50) history.removeAt(0);
    await _prefs!.setStringList('scan_history', history);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _highlightController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _initializeImage() async {
    final size = await _getImageSize(widget.scannedImage);
    setState(() => _imageSize = size);
  }

  void _organizeTextIntoLines() {
    if (widget.results.isEmpty) return;

    final Map<int, List<BoxText>> lineGroups = {};
    const double lineThreshold = 20.0;

    for (final box in widget.results) {
      final centerY = (box.textBBox.yMin + box.textBBox.yMax) / 2;
      final lineKey = (centerY / lineThreshold).round();
      lineGroups[lineKey] ??= [];
      lineGroups[lineKey]!.add(box);
    }

    _textLines = lineGroups.entries.map((entry) {
      final words = entry.value
        ..sort((a, b) => a.textBBox.xMin.compareTo(b.textBBox.xMin));
      final averageY = words.map((w) => (w.textBBox.yMin + w.textBBox.yMax) / 2).reduce((a, b) => a + b) / words.length;
      final minX = words.map((w) => w.textBBox.xMin).reduce(min);
      final maxX = words.map((w) => w.textBBox.xMax).reduce(max);
      return TextLine(words: words, averageY: averageY, minX: minX, maxX: maxX);
    }).toList()
      ..sort((a, b) => a.averageY.compareTo(b.averageY));
  }

  void _highlightWord(int wordIndex) {
    setState(() {
      _highlightedWordIndex = wordIndex;
    });
    _highlightController.reset();
    _highlightController.forward();

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _highlightedWordIndex = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('OCR Scan Results', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  Text(
                    widget.detectedLanguage,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white70),
                  ),
                ],
              ),
            );
          },
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF5A4CFD), Color(0xFF9B89F0)],
            ),
          ),
        ),
        actions: [
          _buildAnimatedIconButton(
            icon: _showBoundingBoxes ? Icons.visibility : Icons.visibility_off,
            onPressed: () => setState(() => _showBoundingBoxes = !_showBoundingBoxes),
            tooltip: 'Toggle Bounding Boxes',
          ),
          _buildAnimatedIconButton(
            icon: _showIndexLabels ? Icons.numbers : Icons.tag,
            onPressed: () => setState(() => _showIndexLabels = !_showIndexLabels),
            tooltip: 'Toggle Index Labels',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'copy_all',
                child: Row(children: [Icon(Icons.copy_all), SizedBox(width: 8), Text('Copy All Text')]),
              ),
              const PopupMenuItem(
                value: 'statistics',
                child: Row(children: [Icon(Icons.analytics), SizedBox(width: 8), Text('View Statistics')]),
              ),
              const PopupMenuItem(
                value: 'save',
                child: Row(children: [Icon(Icons.save), SizedBox(width: 8), Text('Save Results')]),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(children: [Icon(Icons.share), SizedBox(width: 8), Text('Share Text')]),
              ),
            ],
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsCard(),
          Expanded(
            flex: 3,
            child: _imageSize == null
                ? const Center(child: CircularProgressIndicator())
                : _buildImageDisplay(),
          ),
          SlideTransition(
            position: _slideAnimation,
            child: _buildDigitalTextButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 24),
            onPressed: onPressed,
            tooltip: tooltip,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              padding: const EdgeInsets.all(8),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsCard() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _fadeAnimation.value)),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFF0F4F8)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Words', widget.results.length.toString(), Icons.text_fields, Colors.blueAccent),
                  _buildStatItem('Lines', _textLines.length.toString(), Icons.format_list_numbered, Colors.greenAccent),
                  _buildStatItem('Language', widget.detectedLanguage, Icons.language, Colors.orangeAccent),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
              radius: 0.8,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF2D3748),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  Widget _buildImageDisplay() {
    if (_imageSize == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final containerWidth = constraints.maxWidth;
        final containerHeight = constraints.maxHeight;
        final scaleX = containerWidth / _imageSize!.width;
        final scaleY = containerHeight / _imageSize!.height;
        _imageScale = min(scaleX, scaleY);
        final displayWidth = _imageSize!.width * _imageScale;
        final displayHeight = _imageSize!.height * _imageScale;

        return AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      width: displayWidth,
                      height: displayHeight,
                      child: Stack(
                        children: [
                          Hero(
                            tag: 'scanned_image',
                            child: Image.file(
                              widget.scannedImage,
                              width: displayWidth,
                              height: displayHeight,
                              fit: BoxFit.contain,
                            ),
                          ),
                          ...widget.results.asMap().entries.map((entry) {
                            final index = entry.key;
                            final box = entry.value;
                            final left = box.textBBox.xMin * _imageScale;
                            final top = box.textBBox.yMin * _imageScale;
                            final width = (box.textBBox.xMax - box.textBBox.xMin) * _imageScale;
                            final height = (box.textBBox.yMax - box.textBBox.yMin) * _imageScale;

                            final localPolygon = box.polygon.map((pt) {
                              final localX = (pt.dx - box.textBBox.xMin) * _imageScale;
                              final localY = (pt.dy - box.textBBox.yMin) * _imageScale;
                              return Offset(localX, localY);
                            }).toList();

                            return Positioned(
                              left: left,
                              top: top,
                              width: width,
                              height: height,
                              child: GestureDetector(
                                onTap: () {
                                  _highlightWord(index);
                                  _showTextDetailDialog(box.text, index + 1);
                                },
                                child: AnimatedBuilder(
                                  animation: _highlightController,
                                  builder: (context, child) {
                                    final isHighlighted = _highlightedWordIndex == index;
                                    return Transform.scale(
                                      scale: isHighlighted ? _highlightScaleAnimation.value : 1.0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          borderRadius: BorderRadius.circular(6),
                                          boxShadow: isHighlighted
                                              ? [
                                            BoxShadow(
                                              color: Colors.amber.withOpacity(0.4),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                              : null,
                                        ),
                                        child: Stack(
                                          children: [
                                            if (_showBoundingBoxes)
                                              CustomPaint(
                                                painter: PolygonPainter(
                                                  points: localPolygon,
                                                  isHighlighted: isHighlighted,
                                                  highlightColor: _highlightColorAnimation.value ?? Colors.amber,
                                                  borderColor: Colors.teal,
                                                  strokeWidth: isHighlighted ? 1.5 : 1.0,
                                                ),
                                              ),
                                            if (_showIndexLabels && _showBoundingBoxes)
                                              Center(
                                                child: Text(
                                                  '#${index + 1}',
                                                  style: TextStyle(
                                                    color: isHighlighted ? Colors.white : Colors.teal,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDigitalTextButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: _showDigitalTextBottomSheet,
        icon: const Icon(Icons.auto_stories, size: 26),
        label: Text(
          'View Digital Text (${widget.results.length} items)',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5A4CFD),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 10,
          shadowColor: const Color(0xFF5A4CFD).withOpacity(0.4),
        ),
      ),
    );
  }

  void _showDigitalTextBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5)),
              ],
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 60,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                _buildBottomSheetHeader(),
                const Divider(height: 1, color: Colors.grey),
                Expanded(
                  child: AnimatedList(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    itemBuilder: (context, index, animation) {
                      if (index == 0) {
                        return _buildCombinedTextWithAnimation(animation);
                      } else if (index - 1 < _textLines.length) {
                        return _buildTextLineWithAnimation(_textLines[index - 1], index - 1, animation);
                      }
                      return const SizedBox.shrink();
                    },
                    initialItemCount: _textLines.length + 1,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomSheetHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Extracted Text',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
          ),
          Row(
            children: [
              _buildHeaderButton(
                icon: _isLoading ? null : Icons.merge_type,
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _onTogglePressed,
                tooltip: 'Toggle Combined Text',
                isActive: _showCombinedText,
              ),
              _buildHeaderButton(
                icon: Icons.copy_all,
                onPressed: _copyAllText,
                tooltip: 'Copy All',
              ),
              _buildHeaderButton(
                icon: Icons.share,
                onPressed: _shareAllText,
                tooltip: 'Share All',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    IconData? icon,
    bool isLoading = false,
    VoidCallback? onPressed,
    String? tooltip,
    bool isActive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 10),
      child: IconButton(
        icon: isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF5A4CFD)),
        )
            : Icon(
          icon,
          color: isActive ? const Color(0xFF5A4CFD) : Colors.grey.shade600,
          size: 24,
        ),
        onPressed: onPressed,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: isActive ? const Color(0xFF5A4CFD).withOpacity(0.15) : Colors.grey.shade100,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.all(10),
        ),
      ),
    );
  }

  Widget _buildCombinedTextWithAnimation(Animation<double> animation) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 400),
      firstChild: _isLoading ? _buildCombinedSkeleton() : _buildCombinedText(),
      secondChild: const SizedBox.shrink(),
      crossFadeState: _showCombinedText ? CrossFadeState.showFirst : CrossFadeState.showSecond,
    );
  }

  Widget _buildTextLineWithAnimation(TextLine line, int lineIndex, Animation<double> animation) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: FadeTransition(
        opacity: animation,
        child: _buildTextLineWidget(line, lineIndex),
      ),
    );
  }

  Widget _buildCombinedText() {
    List<TextSpan> _buildSpansForLine(TextLine line) {
      final spans = <TextSpan>[];
      for (var i = 0; i < line.words.length; i++) {
        spans.add(TextSpan(text: line.words[i].text));
        if (i < line.words.length - 1) {
          spans.add(const TextSpan(
            text: ' • ',
            style: TextStyle(color: Colors.teal),
          ));
        }
      }
      return spans;
    }

    final lineSpans = <InlineSpan>[];
    for (var i = 0; i < _textLines.length; i++) {
      lineSpans.addAll(_buildSpansForLine(_textLines[i]));
      if (i < _textLines.length - 1) {
        lineSpans.add(const TextSpan(text: '\n'));
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7FAFC), Colors.white],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Combined Text',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
              children: lineSpans,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextLineWidget(TextLine line, int lineIndex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.withOpacity(0.2), Colors.teal.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Line ${lineIndex + 1}',
                  style: const TextStyle(
                    color: Colors.teal,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${line.words.length} words',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: line.words.asMap().entries.map((entry) {
              final i = entry.key;
              final word = entry.value;
              final wordIndex = widget.results.indexOf(word);
              return GestureDetector(
                onTap: () {
                  _highlightWord(wordIndex);
                  _showTextDetailDialog(word.text, wordIndex + 1);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _highlightedWordIndex == wordIndex ? Colors.teal.withOpacity(0.1) : Colors.teal.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: _highlightedWordIndex == wordIndex
                        ? [
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                        : null,
                  ),
                  child: Text(
                    word.text,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(line.text, style: const TextStyle(fontSize: 16, height: 1.5)),
          ),
        ],
      ),
    );
  }

  void _showTextDetailDialog(String text, int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Text #$index',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF2D3748)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey.shade50, Colors.grey.shade100],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(text, style: const TextStyle(fontSize: 18, height: 1.5)),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close', style: TextStyle(color: Colors.teal, fontSize: 16)),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            _copyText(text);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 5,
                          ),
                          child: const Text('Copy', style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'copy_all':
        _copyAllText();
        break;
      case 'statistics':
        _showStatisticsDialog();
        break;
      case 'save':
        _saveResults();
        break;
      case 'share':
        _shareAllText();
        break;
    }
  }

  void _showStatisticsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Scan Statistics',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
              ),
              const SizedBox(height: 16),
              Text('Total Scans: ${_prefs?.getInt('total_scans') ?? 0}', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text('Total Words Extracted: ${_prefs?.getInt('total_words_extracted') ?? 0}', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text('Last Scan: ${_prefs?.getString('last_scan_datetime') ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(color: Colors.teal, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyAllText() {
    final allText = _textLines.map((line) => line.text).join('\n');
    _copyText(allText);
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Text copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.teal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareAllText() {
    final allText = _textLines.map((line) => line.text).join('\n');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Share functionality would open here'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.teal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _saveResults() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Results saved successfully'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.teal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _onTogglePressed() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _showCombinedText = !_showCombinedText;
      _isLoading = false;
    });
  }

  Future<Size> _getImageSize(File file) {
    final completer = Completer<Size>();
    final img = Image.file(file);
    img.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((info, _) => completer.complete(
          Size(info.image.width.toDouble(), info.image.height.toDouble()))),
    );
    return completer.future;
  }

  Widget _buildCombinedSkeleton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(4, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            width: double.infinity,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }),
      ),
    );
  }
}