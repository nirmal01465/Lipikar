import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/ocr_overview_model.dart';

class TextContentView extends StatelessWidget {
  final ScrollController scrollController;

  const TextContentView({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Consumer<OcrViewModel>(
      builder: (context, vm, __) {
        final scaleFactor = vm.scaleFactor;
        final zoomScale = vm.verticalZoomScale;
        return Container(
          width: MediaQuery.of(context).size.width,
          height: vm.imageHeight * scaleFactor * zoomScale,
          color: Colors.white.withOpacity(0.1), // Optional background for visibility
          child: Stack(
            children: vm.wordElements.map((element) {
              final pos = element.center;
              return Positioned(
                left: pos.dx * scaleFactor,
                top: pos.dy * scaleFactor * zoomScale,
                child: Text(
                  element.text,
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}