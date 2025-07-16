import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import '../services/ocr_service.dart';
import '../utils/lipikar_ocr_service.dart';

class TextElement {
  final String text;
  final List<Offset> boundingPolygon;
  final Offset center;

  TextElement({required this.text, required this.boundingPolygon})
      : center = _calculateCenter(boundingPolygon);

  static Offset _calculateCenter(List<Offset> polygon) {
    if (polygon.isEmpty) return Offset.zero;
    double sumX = 0;
    double sumY = 0;
    for (var p in polygon) {
      sumX += p.dx;
      sumY += p.dy;
    }
    return Offset(sumX / polygon.length, sumY / polygon.length);
  }
}

class OcrViewModel extends ChangeNotifier {
  // Image properties
  late File imageFile;
  double imageWidth = 0;
  double imageHeight = 0;

  // Text content
  String fullText = '';
  List<TextElement> wordElements = [];

  // UI state
  int? selectedWordIndex;
  double scaleFactor = 1.0;
  double splitRatio = 0.5;
  double verticalZoomScale = 1.0;
  double pulseValue = 0.0;
  bool lockScroll = true;

  // Enhanced polygons for display
  List<List<Offset>?> enhancedPolygons = [];

  OcrViewModel(File image) {
    imageFile = image;
    _initViewModel();
  }

  Future<void> _initViewModel() async {
    final imageInfo = await _getImageInfo(imageFile);
    imageWidth = imageInfo.width.toDouble();
    imageHeight = imageInfo.height.toDouble();
    await _processOcr();
    notifyListeners();
  }

  Future<ui.Image> _getImageInfo(File imageFile) async {
    final data = await imageFile.readAsBytes();
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(data, (ui.Image img) {
      completer.complete(img);
    });
    return completer.future;
  }

  Future<void> _processOcr() async {
    try {
      final ocrService = LipikarService();
      final base64Image = await ocrService.fileToBase64(imageFile);
      final detectionConfig = DetectionConfig(
        modelId: languageToModelId['Tamil']!,
        language: 'Tamil',
        allowPadding: true,
      );
      final recognitionConfig = RecognitionConfig(
        modelId: languageToModelId['Tamil']!,
        modality: 'Printed+SceneText',
        languages: [LanguageConfig(sourceLanguage: 'ta', sourceLanguageName: 'Tamil', targetLanguage: '', targetLanguageName: '')],
      );

      final detectionResult = await ocrService.detectText(
        config: detectionConfig,
        base64Images: [base64Image],
      );
      final recognitionResult = await ocrService.recognizeText(
        config: recognitionConfig,
        base64Images: [base64Image],
      );

      if (detectionResult.isSuccess && recognitionResult.isSuccess) {
        final boxes = detectionResult.data!;
        // final texts = recognitionResult.data!.map((r) => r.source.toString()).toList();
        final texts = recognitionResult.data!.map((r) => r.toString()).toList();
        if (boxes.length != texts.length) {
          throw Exception('Mismatch between detected boxes (${boxes.length}) and recognized texts (${texts.length})');
        }
        wordElements = boxes.asMap().entries.map((entry) {
          final idx = entry.key;
          final box = entry.value;
          return TextElement(
            text: texts[idx],
            boundingPolygon: box.polygon.map((pt) => Offset(pt[0], pt[1])).toList(),
          );
        }).toList();
        fullText = texts.join('\n');
        enhancedPolygons = List.generate(
          wordElements.length,
              (i) => _enhancePolygon(wordElements[i].boundingPolygon),
        );
      } else {
        throw Exception(detectionResult.error ?? recognitionResult.error);
      }
    } catch (e) {
      print('OCR processing error: $e');
      fullText = 'Error processing OCR: $e';
    }
  }

  List<Offset>? _enhancePolygon(List<Offset> polygon) {
    if (polygon.isEmpty) return null;
    if (polygon.length < 4) {
      double minX = double.infinity;
      double minY = double.infinity;
      double maxX = 0;
      double maxY = 0;
      for (var point in polygon) {
        minX = minX < point.dx ? minX : point.dx;
        minY = minY < point.dy ? minY : point.dy;
        maxX = maxX > point.dx ? maxX : point.dx;
        maxY = maxY > point.dy ? maxY : point.dy;
      }
      return [
        Offset(minX, minY),
        Offset(maxX, minY),
        Offset(maxX, maxY),
        Offset(minX, maxY),
      ];
    }
    return polygon;
  }

  void selectWord(int index) {
    selectedWordIndex = index;
    notifyListeners();
  }

  void toggleScrollLock() {
    lockScroll = !lockScroll;
    notifyListeners();
  }

  void updateSplitRatio(double ratio) {
    splitRatio = ratio;
    notifyListeners();
  }

  void updateVerticalZoom(double zoom) {
    verticalZoomScale = zoom;
    notifyListeners();
  }

  void updatePulseValue(double value) {
    pulseValue = value;
    notifyListeners();
  }

  String? get selectedText {
    if (selectedWordIndex != null &&
        selectedWordIndex! >= 0 &&
        selectedWordIndex! < wordElements.length) {
      return wordElements[selectedWordIndex!].text;
    }
    return null;
  }

  Offset? get selectedTextPosition {
    if (selectedWordIndex != null &&
        selectedWordIndex! >= 0 &&
        selectedWordIndex! < wordElements.length) {
      return wordElements[selectedWordIndex!].center;
    }
    return null;
  }
}