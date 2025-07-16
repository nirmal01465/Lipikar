import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:http/http.dart' as http;

class LipikarOcrService {
  static const String baseUrl = 'https://lipikar.cse.iitd.ac.in';

  // Get available detection models
  Future<List<String>> getAvailableDetectionModels() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api-direct/detection/available-models'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['result']['available_models']);
    } else {
      throw Exception('Failed to load detection models: ${response.statusCode}');
    }
  }

  // Get available recognition models
  Future<List<String>> getAvailableRecognitionModels() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api-direct/recognition/available-models'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['result']['available_models']);
    } else {
      throw Exception('Failed to load recognition models: ${response.statusCode}');
    }
  }

  // Perform text detection
  Future<Map<String, dynamic>> detectText(File imageFile, {String? modelId}) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await http.post(
      Uri.parse('$baseUrl/api-direct/detection/infer'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'config': {
          'modelId': modelId ?? 'default',
          'language': 'english',
          'allowPadding': true,
        },
        'image': [
          {'imageContent': base64Image}
        ]
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorResponse = jsonDecode(response.body);
      throw Exception('Detection failed: ${errorResponse['error']}');
    }
  }

  // Perform text recognition
  Future<List<TextBlock>> recognizeText(File imageFile, {String? modelId}) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await http.post(
      Uri.parse('$baseUrl/api-direct/recognition/infer'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'config': {
          'modelId': modelId ?? 'default',
          'modality': 'printed+SceneText',
          'detectionLevel': 'word',
          'languages': [
            {
              'sourceLanguage': 'en',
              'sourceLanguageName': 'English',
              'targetLanguage': 'en',
              'targetLanguageName': 'English'
            }
          ]
        },
        'image': [
          {
            'imageContent': base64Image,
            'imageUri': 'image.jpg'
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<dynamic> outputList = data['output'];

      if (outputList.isEmpty) {
        return [];
      }

      // Parse the first result (assuming we only sent one image)
      final result = outputList[0];

      // Process the result into structured text blocks
      return _processRecognitionResult(result);
    } else {
      try {
        final errorResponse = jsonDecode(response.body);
        throw Exception('Recognition failed: ${errorResponse['error']}');
      } catch (e) {
        throw Exception('Recognition failed: ${response.statusCode}');
      }
    }
  }

  // Process recognition result into structured text blocks
  List<TextBlock> _processRecognitionResult(Map<String, dynamic> result) {
    // This structure may need to be adjusted based on the actual API response format
    // The assumption here is that the API returns text blocks with bounding polygons

    List<TextBlock> blocks = [];

    if (result.containsKey('blocks')) {
      List<dynamic> blockData = result['blocks'];

      for (var blockInfo in blockData) {
        List<TextLine> lines = [];

        if (blockInfo.containsKey('lines')) {
          List<dynamic> lineData = blockInfo['lines'];

          for (var lineInfo in lineData) {
            List<TextElement> elements = [];

            if (lineInfo.containsKey('words')) {
              List<dynamic> wordData = lineInfo['words'];

              for (var wordInfo in wordData) {
                String text = wordInfo['text'] ?? '';
                List<Offset> polygon = _parsePolygon(wordInfo['boundingBox']);

                elements.add(TextElement(
                  text: text,
                  boundingPolygon: polygon,
                  confidence: wordInfo['confidence'] ?? 0.0,
                ));
              }
            }

            String lineText = lineInfo['text'] ?? '';
            List<Offset> linePolygon = _parsePolygon(lineInfo['boundingBox']);

            lines.add(TextLine(
              text: lineText,
              boundingPolygon: linePolygon,
              elements: elements,
            ));
          }
        }

        String blockText = blockInfo['text'] ?? '';
        List<Offset> blockPolygon = _parsePolygon(blockInfo['boundingBox']);

        blocks.add(TextBlock(
          text: blockText,
          boundingPolygon: blockPolygon,
          lines: lines,
        ));
      }
    } else {
      // Fallback for simpler API responses that might only contain raw text
      // Create a single block with the extracted text
      String extractedText = result['source'] ?? '';
      blocks.add(TextBlock(
        text: extractedText,
        boundingPolygon: [],
        lines: [
          TextLine(
            text: extractedText,
            boundingPolygon: [],
            elements: [
              TextElement(
                text: extractedText,
                boundingPolygon: [],
                confidence: 1.0,
              )
            ],
          )
        ],
      ));
    }

    return blocks;
  }

  // Helper method to parse bounding polygons from API response
  List<Offset> _parsePolygon(dynamic boundingBoxData) {
    if (boundingBoxData == null) return [];

    // Parse points depending on the format returned by the API
    // Example: [[x1, y1], [x2, y2], [x3, y3], [x4, y4]]
    try {
      if (boundingBoxData is List) {
        return boundingBoxData.map<Offset>((point) {
          if (point is List && point.length >= 2) {
            return Offset(
              point[0].toDouble(),
              point[1].toDouble(),
            );
          }
          return Offset.zero;
        }).toList();
      }
    } catch (e) {
      print('Error parsing polygon: $e');
    }

    return [];
  }
}

// Models to represent the OCR results
class TextBlock {
  final String text;
  final List<Offset> boundingPolygon;
  final List<TextLine> lines;

  TextBlock({
    required this.text,
    required this.boundingPolygon,
    required this.lines,
  });
}

class TextLine {
  final String text;
  final List<Offset> boundingPolygon;
  final List<TextElement> elements;

  TextLine({
    required this.text,
    required this.boundingPolygon,
    required this.elements,
  });
}

class TextElement {
  final String text;
  final List<Offset> boundingPolygon;
  final double confidence;

  TextElement({
    required this.text,
    required this.boundingPolygon,
    required this.confidence,
  });
}

// Class to represent a full OCR result containing all blocks, lines, and elements
class OcrResult {
  final String text;
  final List<TextBlock> blocks;
  final int width;
  final int height;

  OcrResult({
    required this.text,
    required this.blocks,
    required this.width,
    required this.height,
  });

  // Helper method to get all elements (words) across all blocks and lines
  List<TextElement> getAllElements() {
    List<TextElement> allElements = [];
    for (var block in blocks) {
      for (var line in block.lines) {
        allElements.addAll(line.elements);
      }
    }
    return allElements;
  }
}