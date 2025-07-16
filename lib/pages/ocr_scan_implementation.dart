import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/finances_colors.dart';
import '../widgets/ocr_overview_model.dart';
import 'ocr_content_text_view.dart';

class SynchronizedOcrViewer extends StatefulWidget {
  const SynchronizedOcrViewer({Key? key}) : super(key: key);

  @override
  State<SynchronizedOcrViewer> createState() => _SynchronizedOcrViewerState();
}

class _SynchronizedOcrViewerState extends State<SynchronizedOcrViewer>
    with SingleTickerProviderStateMixin {
  final ScrollController _imageScrollController = ScrollController();
  final ScrollController _textScrollController = ScrollController();
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  double _dragStart = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    )..addListener(() {
      Provider.of<OcrViewModel>(context, listen: false).updatePulseValue(_pulseAnimation.value);
    });
    _setupSynchronizedScrolling();
  }

  @override
  void dispose() {
    _imageScrollController.dispose();
    _textScrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _setupSynchronizedScrolling() {
    _imageScrollController.addListener(() {
      final vm = Provider.of<OcrViewModel>(context, listen: false);
      if (vm.lockScroll && _textScrollController.hasClients) {
        final px = _imageScrollController.position.pixels;
        if (_textScrollController.position.pixels != px) {
          _textScrollController.jumpTo(px);
        }
      }
    });
    _textScrollController.addListener(() {
      final vm = Provider.of<OcrViewModel>(context, listen: false);
      if (vm.lockScroll && _imageScrollController.hasClients) {
        final px = _textScrollController.position.pixels;
        if (_imageScrollController.position.pixels != px) {
          _imageScrollController.jumpTo(px);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR Document Viewer'),
        backgroundColor: DocAppColors.purple,
        actions: [
          Consumer<OcrViewModel>(
            builder: (_, vm, __) => IconButton(
              icon: Icon(vm.lockScroll ? Icons.link : Icons.link_off),
              onPressed: vm.toggleScrollLock,
              tooltip: vm.lockScroll ? 'Unlock scrolling' : 'Lock scrolling',
            ),
          ),
        ],
      ),
      body: Consumer<OcrViewModel>(
        builder: (context, vm, __) {
          if (vm.imageWidth > 0) {
            vm.scaleFactor = MediaQuery.of(context).size.width / vm.imageWidth;
          }

          return Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * vm.splitRatio,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: SingleChildScrollView(
                        controller: _imageScrollController,
                        clipBehavior: Clip.none,
                        child: Transform(
                          transform: Matrix4.identity()..scale(1.0, vm.verticalZoomScale, 1.0),
                          alignment: Alignment.topCenter,
                          child: Image.file(
                            vm.imageFile,
                            fit: BoxFit.fitWidth,
                            width: double.infinity,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: SingleChildScrollView(
                        controller: _imageScrollController,
                        physics: const NeverScrollableScrollPhysics(),
                        clipBehavior: Clip.none,
                        child: Transform(
                          transform: Matrix4.identity()..scale(1.0, vm.verticalZoomScale, 1.0),
                          alignment: Alignment.topCenter,
                          child: GestureDetector(
                            onTapDown: (details) => _handleTapOnImage(details, vm),
                            child: CustomPaint(
                              painter: EnhancedTextBoundaryPainter(viewModel: vm),
                              size: Size(
                                  vm.imageWidth * vm.scaleFactor, vm.imageHeight * vm.scaleFactor * vm.verticalZoomScale),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (vm.selectedText != null && vm.selectedTextPosition != null)
                      Positioned(
                        left: vm.selectedTextPosition!.dx * vm.scaleFactor,
                        top: vm.selectedTextPosition!.dy * vm.scaleFactor * vm.verticalZoomScale,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.white.withOpacity(0.9),
                          child: Text(
                            vm.selectedText!,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    _buildZoomControls(vm),
                  ],
                ),
              ),
              GestureDetector(
                onVerticalDragStart: (d) {
                  _dragStart = d.globalPosition.dy;
                  _isDragging = true;
                },
                onVerticalDragUpdate: (d) {
                  if (_isDragging) {
                    final h = MediaQuery.of(context).size.height;
                    final dy = d.globalPosition.dy - _dragStart;
                    final nr = (vm.splitRatio * h + dy) / h;
                    if (nr >= 0.2 && nr <= 0.8) {
                      vm.updateSplitRatio(nr);
                      _dragStart = d.globalPosition.dy;
                    }
                  }
                },
                onVerticalDragEnd: (_) => _isDragging = false,
                child: Container(
                  height: 20,
                  color: DocAppColors.lightPurple.withOpacity(0.3),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: DocAppColors.purple,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _textScrollController,
                  child: TextContentView(scrollController: _textScrollController),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleTapOnImage(TapDownDetails details, OcrViewModel vm) {
    final pos = details.localPosition;
    final scaledPos = Offset(pos.dx, pos.dy / vm.verticalZoomScale); // Adjust for zoom

    for (var i = 0; i < vm.enhancedPolygons.length; i++) {
      final polygon = vm.enhancedPolygons[i];
      if (polygon == null) continue;

      final path = Path()
        ..addPolygon(
          polygon.map((p) => Offset(p.dx * vm.scaleFactor, p.dy * vm.scaleFactor)).toList(),
          true,
        );
      if (path.contains(scaledPos)) {
        vm.selectWord(i);
        _pulseController.reset();
        _pulseController.repeat(reverse: true);
        return;
      }
    }
  }

  Widget _buildZoomControls(OcrViewModel vm) {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            IconButton(
              icon: const Icon(Icons.zoom_in),
              onPressed: () {
                final newZoom = vm.verticalZoomScale * 1.25;
                vm.updateVerticalZoom(newZoom.clamp(1.0, 5.0));
              },
              tooltip: 'Zoom in',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '${(vm.verticalZoomScale * 100).toInt()}%',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.zoom_out),
              onPressed: () {
                final newZoom = vm.verticalZoomScale / 1.25;
                vm.updateVerticalZoom(newZoom.clamp(1.0, 5.0));
              },
              tooltip: 'Zoom out',
            ),
          ],
        ),
      ),
    );
  }
}

class EnhancedTextBoundaryPainter extends CustomPainter {
  final OcrViewModel viewModel;

  EnhancedTextBoundaryPainter({required this.viewModel});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green // Match the second image's green boxes
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (var i = 0; i < viewModel.enhancedPolygons.length; i++) {
      final polygon = viewModel.enhancedPolygons[i];
      if (polygon != null) {
        final path = Path()
          ..addPolygon(
            polygon.map((p) => Offset(p.dx * viewModel.scaleFactor, p.dy * viewModel.scaleFactor)).toList(),
            true,
          );
        canvas.drawPath(path, paint);
        if (viewModel.selectedWordIndex == i) {
          final highlightPaint = Paint()
            ..color = Colors.blue.withOpacity(0.3 + 0.3 * viewModel.pulseValue)
            ..style = PaintingStyle.fill;
          canvas.drawPath(path, highlightPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}