import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

/// Supported language → recognition model mappings
const Map<String, String> languageToModelId = {
  'English': 'english_iitd',
  'Hindi': 'hindi_iitd',
  'Punjabi': 'punjabi_iitd',
  'Bengali': 'bengali_iitd',
  'Sanskrit': 'sanskrit_iitd',
  'Malayalam': 'malayalam_iitd',
  'Marathi': 'marathi_iitd',
  'Oriya': 'oriya_iitd',
  'Tamil': 'tamil_iitd',
  'Kashmiri': 'kashmiri_iitd',
  'Konkani': 'konkani_iitd',
  'Dogri': 'dogri_iitd',
  'Maithili': 'maithili_iitd',
  'Nepali': 'nepali_iitd',
  'Bodo': 'bodo_iitd',
  'Gujarati': 'gujrati_iitd',
  'Kannada': 'kannada_iitd',
  'Urdu': 'urdu_iitd',
  'Assamese': 'assamese_iitd',
  'Manipuri': 'manipuri_iitd',
  'Santali (Bengali script)': 'santali_bn_iitd',
  'Santali (Assamese script)': 'santali_asa_iitd',
  'Sindhi': 'sindhi_iitd',
  'Kaithi': 'kaithi_iitd',
  'Triplet Hi_Eng_Pa': 'triplet',
  'Triplet Hi_Eng_Te': 'triplet_hi_en_te',
  'English Handwritten': 'eng_hw_iitd',
  'Hindi Handwritten': 'hindi_hw_iitd'
};

/// Bounding box for detected text
class TextBBox {
  final int lineIndex, wordIndex;
  final double xMin, xMax, yMin, yMax;

  TextBBox({
    required this.lineIndex,
    required this.wordIndex,
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
  });

  factory TextBBox.fromJson(Map<String, dynamic> json) => TextBBox(
    lineIndex: json['line_index'],
    wordIndex: json['word_index'],
    xMin: (json['x_min'] as num).toDouble(),
    xMax: (json['x_max'] as num).toDouble(),
    yMin: (json['y_min'] as num).toDouble(),
    yMax: (json['y_max'] as num).toDouble(),
  );
}

class BoundingBox {
  final List<List<double>> polygon;
  final TextBBox textBBox;

  BoundingBox({
    required this.polygon,
    required this.textBBox,
  });

  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    final polygon = (json['polygon'] as List)
        .map((pt) => List<double>.from((pt as List).map((n) => (n as num).toDouble())))
        .toList();
    return BoundingBox(
      polygon: polygon,
      textBBox: TextBBox.fromJson(json['text_bbox']),
    );
  }
}

class RecognitionResult {
  final String text;
  final double confidence;
  final double? angle;

  RecognitionResult({required this.text, required this.confidence, this.angle});

  factory RecognitionResult.fromJson(Map<String, dynamic> json) {
    final source = json['source'];
    if (source is List && source.length >= 2) {
      return RecognitionResult(
        text: source[0].toString(),
        confidence: (source[1] as num).toDouble(),
        angle: json['angle'] != null ? (json['angle'] as num).toDouble() : null,
      );
    } else {
      throw FormatException('Invalid source format in recognition response');
    }
  }
}

/// Request config for detection
class DetectionConfig {
  final String modelId;
  final String language;
  final bool allowPadding;

  DetectionConfig({
    required this.modelId,
    this.language = 'english',
    this.allowPadding = true,
  });

  Map<String, dynamic> toJson() => {
    'modelId': modelId,
    'language': language,
    'allowPadding': allowPadding,
  };
}

/// Language entry for recognition
class LanguageConfig {
  final String sourceLanguage;
  final String sourceLanguageName;
  final String targetLanguage;
  final String targetLanguageName;

  LanguageConfig({
    required this.sourceLanguage,
    required this.sourceLanguageName,
    required this.targetLanguage,
    required this.targetLanguageName,
  });

  Map<String, dynamic> toJson() => {
    'sourceLanguage': sourceLanguage,
    'sourceLanguageName': sourceLanguageName,
    'targetLanguage': targetLanguage,
    'targetLanguageName': targetLanguageName,
  };
}

/// Request config for recognition
class RecognitionConfig {
  final String modelId;
  final String modality;
  final List<LanguageConfig> languages;

  RecognitionConfig({
    required this.modelId,
    this.modality = 'printed+SceneText',
    required this.languages,
  });

  Map<String, dynamic> toJson() => {
    'modelId': modelId,
    'modality': modality,
    'languages': languages.map((l) => l.toJson()).toList(),
  };
}

/// Model for a polygon + its extracted text
class BoxText {
  final List<Offset> polygon;
  final TextBBox textBBox;
  final String text;

  BoxText({required this.polygon, required this.textBBox, required this.text});
}

/// Wrapper for full OCR
class OcrResult {
  final List<BoxText> results;
  final String language;

  OcrResult({required this.results, required this.language});
}

/// Generic API response
class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  ApiResponse.success(this.data) : error = null, isSuccess = true;
  ApiResponse.error(this.error) : data = null, isSuccess = false;
}

/// LipiKAR HTTP client
class LipikarService {
  static const String _base = 'https://lipikar.cse.iitd.ac.in/api-direct';
  final http.Client _client;
  final Duration _timeout;

  LipikarService({http.Client? client, Duration? timeout})
      : _client = client ?? http.Client(),
        _timeout = timeout ?? const Duration(seconds: 30);

  Future<ApiResponse<List<BoundingBox>>> detectText({
    required DetectionConfig config,
    required List<String> base64Images,
  }) async {
    final uri = Uri.parse('$_base/detection/infer');
    final payload = {
      'config': config.toJson(),
      'image': base64Images.map((b) => {'imageContent': b}).toList(),
    };

    try {
      final resp = await _client
          .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload))
          .timeout(_timeout);

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        if (body.containsKey('error')) return ApiResponse.error('API error: ${body['error']}');
        final output = body['output'] as List<dynamic>?;
        if (output == null || output.isEmpty) {
          return ApiResponse.error('Missing output in detection response');
        }
        final detections = output[0]['detections'] as Map<String, dynamic>?;
        final bboxes = detections?['bboxes'] as List<dynamic>?;
        if (bboxes == null) return ApiResponse.error('No bounding boxes returned');
        final boxes =
        bboxes.map((j) => BoundingBox.fromJson(j as Map<String, dynamic>)).toList();
        return ApiResponse.success(boxes);
      }
      return ApiResponse.error('HTTP ${resp.statusCode}: ${resp.body}');
    } on TimeoutException {
      return ApiResponse.error('Detection request timed out after ${_timeout.inSeconds} seconds');
    } catch (e) {
      return ApiResponse.error('Detection error: $e');
    }
  }

  Future<ApiResponse<List<RecognitionResult>>> recognizeText({
    required RecognitionConfig config,
    required List<String> base64Images,
  }) async {
    final uri = Uri.parse('$_base/recognition/infer');
    final payload = {
      'config': config.toJson(),
      'image': base64Images.map((b) => {'imageContent': b}).toList(),
    };

    try {
      final resp = await _client
          .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload))
          .timeout(_timeout);

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        if (body.containsKey('error')) return ApiResponse.error('API error: ${body['error']}');
        final output = body['output'] as List<dynamic>?;
        if (output == null) return ApiResponse.error('Missing output in recognition response');
        final results =
        output.map((j) => RecognitionResult.fromJson(j as Map<String, dynamic>)).toList();
        return ApiResponse.success(results);
      }
      return ApiResponse.error('HTTP ${resp.statusCode}: ${resp.body}');
    } on TimeoutException {
      return ApiResponse.error(
          'Recognition request timed out after ${_timeout.inSeconds} seconds');
    } catch (e) {
      return ApiResponse.error('Recognition error: $e');
    }
  }

  Future<ApiResponse<OcrResult>> performOcr({
    required String base64Image,
    required String language,
    required String parser,
  }) async {
    try {
      final detectionModelId = parser == 'Tesseract v5 (Word-Level)'
          ? 'tess_word_level'
          : (parser == 'FocusFormer Line Level' ? 'focusformer_line_level' : 'focusformer');
      final recognitionModelId = languageToModelId[language] ?? 'english_iitd';
      final langCode = _languageToCode(language);

      final detectResp = await detectText(
        config: DetectionConfig(
          modelId: detectionModelId,
          language: language.toLowerCase(),
        ),
        base64Images: [base64Image],
      );
      if (!detectResp.isSuccess) return ApiResponse.error('Detection failed: ${detectResp.error}');
      final boxes = detectResp.data!;
      if (boxes.isEmpty) return ApiResponse.error('No text regions detected');

      final imageBytes = base64Decode(base64Image);
      final image = img.decodeImage(imageBytes);
      if (image == null) return ApiResponse.error('Failed to decode image');

      final croppedBase64Images = <String>[];
      for (var box in boxes) {
        final xMin = box.textBBox.xMin.clamp(0, image.width - 1);
        final xMax = box.textBBox.xMax.clamp(0, image.width - 1);
        final yMin = box.textBBox.yMin.clamp(0, image.height - 1);
        final yMax = box.textBBox.yMax.clamp(0, image.height - 1);
        final x = xMin.toInt();
        final y = yMin.toInt();
        final width = (xMax - xMin + 1).toInt();
        final height = (yMax - yMin + 1).toInt();
        if (width > 0 && height > 0) {
          final cropped = img.copyCrop(image, x: x, y: y, width: width, height: height);
          final jpegBytes = img.encodeJpg(cropped);
          croppedBase64Images.add(base64Encode(jpegBytes));
        }
      }

      if (croppedBase64Images.isEmpty) {
        return ApiResponse.error('No valid cropped images for recognition');
      }

      final recogResp = await recognizeText(
        config: RecognitionConfig(
          modelId: recognitionModelId,
          modality: 'printed+SceneText',
          languages: [
            LanguageConfig(
              sourceLanguage: langCode,
              sourceLanguageName: language,
              targetLanguage: langCode,
              targetLanguageName: language,
            )
          ],
        ),
        base64Images: croppedBase64Images,
      );
      if (!recogResp.isSuccess) {
        return ApiResponse.error('Recognition failed: ${recogResp.error}');
      }
      final recognitions = recogResp.data!;

      final results = <BoxText>[];
      for (var i = 0; i < boxes.length && i < recognitions.length; i++) {
        final box = boxes[i];
        final text = recognitions[i].text;
        if (text.isNotEmpty) {
          final pts = box.polygon.map((pt) => Offset(pt[0], pt[1])).toList();
          results.add(BoxText(
            polygon: pts,
            textBBox: box.textBBox,
            text: text,
          ));
        }
      }

      return ApiResponse.success(OcrResult(results: results, language: language));
    } catch (e) {
      return ApiResponse.error('OCR error: $e');
    }
  }

  Future<String> fileToBase64(File file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  String _languageToCode(String language) {
    const langCodes = {
      'English': 'en',
      'Hindi': 'hi',
      'Punjabi': 'pa',
      'Bengali': 'bn',
      'Sanskrit': 'sa',
      'Malayalam': 'ml',
      'Marathi': 'mr',
      'Oriya': 'or',
      'Tamil': 'ta',
      'Kashmiri': 'ks',
      'Konkani': 'kok',
      'Dogri': 'doi',
      'Maithili': 'mai',
      'Nepali': 'ne',
      'Bodo': 'brx',
      'Gujarati': 'gu',
      'Kannada': 'kn',
      'Urdu': 'ur',
      'Assamese': 'as',
      'Manipuri': 'mni',
      'Sindhi': 'sd',
    };
    return langCodes[language] ?? 'en';
  }

  void dispose() => _client.close();
}

class PolygonPainter extends CustomPainter {
  final List<Offset> points;
  final bool isHighlighted;
  final Color highlightColor;
  final Color borderColor;
  final double strokeWidth;

  PolygonPainter({
    required this.points,
    this.isHighlighted = false,
    this.highlightColor = Colors.amber,
    this.borderColor = Colors.teal,
    this.strokeWidth = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final path = Path()..addPolygon(points, true);
    if (isHighlighted) {
      final fillPaint = Paint()
        ..color = highlightColor.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);
    }
    final borderPaint = Paint()
      ..color = isHighlighted ? highlightColor : borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant PolygonPainter oldDelegate) {
    return oldDelegate.isHighlighted != isHighlighted ||
        oldDelegate.points != points ||
        oldDelegate.highlightColor != highlightColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
