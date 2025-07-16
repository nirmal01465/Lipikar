import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import '../services/ocr_service.dart';
import 'scan_result_page.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({Key? key}) : super(key: key);

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with TickerProviderStateMixin {
  final _scanner = FlutterDocScanner();
  final _picker = ImagePicker();
  bool _busy = false;
  String _selectedLanguage = 'English';
  String _selectedParser = 'FocusFormer';

  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  static const List<String> _languages = [
    'English', 'Hindi', 'Punjabi', 'Bengali', 'Sanskrit', 'Malayalam',
    'Marathi', 'Oriya', 'Tamil', 'Kashmiri', 'Konkani', 'Dogri',
    'Maithili', 'Nepali', 'Bodo', 'Gujarati', 'Kannada', 'Urdu',
    'Assamese', 'Manipuri', 'Santali (Bengali script)', 'Santali (Assamese script)', 'Sindhi',
  ];

  static const List<String> _parsers = [
    'Tesseract v5 (Word-Level)',
    'FocusFormer',
    'FocusFormer Line Level',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: 30,),
                          _buildWelcomeCard(),
                          const SizedBox(height: 24),
                          _buildSettingsCard(),
                          const SizedBox(height: 32),
                          _buildActionButtons(),
                          if (_busy) ...[
                            const SizedBox(height: 32),
                            _buildLoadingIndicator(),
                          ],
                          const SizedBox(height: 32),
                          _buildFeaturesList(),
                          const SizedBox(height: 24),
                          _buildAboutCard(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 90,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            color: Colors.transparent
          ),
          child: const SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20,vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 30),
                    child: Text(
                      'Lipikar',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.lightBlue,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Scan, recognize, and digitize text',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4FACFE),
            Color(0xFF00F2FE),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4FACFE).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.document_scanner,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ready to Scan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose your language and start scanning documents',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.settings,
                  size: 20,
                  color: Color(0xFF667EEA),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'OCR Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildDropdownField(
            label: 'Language',
            icon: Icons.language,
            value: _selectedLanguage,
            items: _languages,
            onChanged: _busy ? null : (v) => setState(() => _selectedLanguage = v!),
          ),
          const SizedBox(height: 20),
          _buildDropdownField(
            label: 'Recognition Model',
            icon: Icons.psychology,
            value: _selectedParser,
            items: _parsers,
            onChanged: _busy ? null : (v) => setState(() => _selectedParser = v!),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A5568),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFF667EEA), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: const TextStyle(
              color: Color(0xFF2D3748),
              fontSize: 16,
            ),
            dropdownColor: Colors.white,
            items: items.map((item) => DropdownMenuItem(
              value: item,
              child: Text(item),
            )).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.camera_alt,
            label: 'Scan Document',
            onTap: _scanDocument,
            gradient: const LinearGradient(
              colors: [Color(0xFF4FACFE),
                Color(0xFF00F2FE),],
            ),
            isEnabled: !_busy,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(
            icon: Icons.photo_library,
            label: 'From Gallery',
            onTap: _pickFromGallery,
            gradient: const LinearGradient(
              colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
            ),
            isEnabled: !_busy,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required LinearGradient gradient,
    required bool isEnabled,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: isEnabled ? gradient : null,
        color: isEnabled ? null : Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isEnabled ? [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    _pulseController.repeat(reverse: true);

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const CircularProgressIndicator(
                    color: Color(0xFF667EEA),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Processing your document...',
                  style: TextStyle(
                    color: Color(0xFF2D3748),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait while we extract text from your image',
                  style: TextStyle(
                    color: const Color(0xFF4A5568).withOpacity(0.8),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      {
        'icon': Icons.translate,
        'title': 'Multi-language Support',
        'subtitle': 'Supports 23+ Indian languages',
        'color': const Color(0xFF10B981),
      },
      {
        'icon': Icons.speed,
        'title': 'Fast Processing',
        'subtitle': 'Quick and accurate text recognition',
        'color': const Color(0xFF3B82F6),
      },
      {
        'icon': Icons.share,
        'title': 'Easy Sharing',
        'subtitle': 'Copy, save, and share recognized text',
        'color': const Color(0xFF8B5CF6),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Key Features',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 16),
        ...features.map((feature) => _buildFeatureItem(
          icon: feature['icon'] as IconData,
          title: feature['title'] as String,
          subtitle: feature['subtitle'] as String,
          color: feature['color'] as Color,
        )),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF4A5568).withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4FACFE),
            Color(0xFF00F2FE),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'About This App',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Advanced OCR technology for Indian languages. Scan documents, extract text, and digitize your content with high accuracy.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.language,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  'Selected: $_selectedLanguage',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Keep all the existing methods for functionality
  Future<void> _scanDocument() async {
    setState(() => _busy = true);
    try {
      final res = await _scanner.getScannedDocumentAsImages();
      if (res == null || res.isEmpty) {
        throw Exception('Scan cancelled by user');
      }

      print('Scanner result type: ${res.runtimeType}');
      print('Scanner result: $res');

      List<String> imagePaths = _extractImagePaths(res);

      if (imagePaths.isEmpty) {
        throw Exception('No valid image paths found in scan result');
      }

      print('Extracted paths: $imagePaths');

      for (String imagePath in imagePaths) {
        await _processImagePath(imagePath);
      }
    } catch (e) {
      print('Scan error: $e');
      _showSnack('Error: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  List<String> _extractImagePaths(dynamic res) {
    List<String> imagePaths = [];

    try {
      if (res is Map) {
        if (res.containsKey('Uri')) {
          final uriData = res['Uri'];
          if (uriData is List) {
            for (var item in uriData) {
              String path = _extractPathFromPageObject(item);
              if (path.isNotEmpty) {
                imagePaths.add(path);
              }
            }
          } else if (uriData is String) {
            final uris = uriData.split(',');
            for (var uri in uris) {
              String path = _extractPathFromPageObject(uri.trim());
              if (path.isNotEmpty) {
                imagePaths.add(path);
              }
            }
          }
        } else if (res.containsKey('imageUri')) {
          String path = _extractPathFromUri(res['imageUri'].toString());
          if (path.isNotEmpty) {
            imagePaths.add(path);
          }
        }
      } else if (res is List) {
        for (var item in res) {
          if (item is String) {
            String path = _extractPathFromPageObject(item);
            if (path.isNotEmpty) {
              imagePaths.add(path);
            }
          } else if (item is Map && item.containsKey('imageUri')) {
            String path = _extractPathFromUri(item['imageUri'].toString());
            if (path.isNotEmpty) {
              imagePaths.add(path);
            }
          }
        }
      } else if (res is String) {
        String path = _extractPathFromPageObject(res);
        if (path.isNotEmpty) {
          imagePaths.add(path);
        }
      }
    } catch (e) {
      print('Error extracting image paths: $e');
    }

    return imagePaths;
  }

  String _extractPathFromPageObject(dynamic pageObject) {
    String pageStr = pageObject.toString();

    if (pageStr.contains('imageUri=file://')) {
      RegExp regex = RegExp(r'imageUri=file://([^}]+)');
      Match? match = regex.firstMatch(pageStr);
      if (match != null) {
        return match.group(1) ?? '';
      }
    }

    if (pageStr.startsWith('file://')) {
      return pageStr.replaceFirst('file://', '');
    }

    if (pageStr.startsWith('/')) {
      return pageStr;
    }

    return '';
  }

  String _extractPathFromUri(String uri) {
    return uri.replaceFirst(RegExp(r'^file://'), '');
  }

  Future<void> _processImagePath(String imagePath) async {
    try {
      print('Processing file: $imagePath');

      final file = File(imagePath);

      if (!await file.exists()) {
        print('File not found, checking alternative paths...');

        List<String> alternativePaths = [
          imagePath,
          imagePath.replaceAll(RegExp(r'^/+'), '/'),
          imagePath.replaceAll(' ', ''),
        ];

        File? validFile;
        for (String altPath in alternativePaths) {
          final altFile = File(altPath);
          if (await altFile.exists()) {
            validFile = altFile;
            print('Found file at: $altPath');
            break;
          }
        }

        if (validFile == null) {
          throw Exception('Image file not found at any location: $imagePath');
        }

        final bytes = await validFile.readAsBytes();
        await _processFile(bytes, validFile);
      } else {
        final bytes = await file.readAsBytes();
        await _processFile(bytes, file);
      }
    } catch (e) {
      print('Error processing image path $imagePath: $e');
      _showSnack('Error processing image: $e');
    }
  }

  Future<File> _writeTempFile(Uint8List bytes) async {
    final dir = Directory.systemTemp;
    final file = File(p.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg'));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> _processFile(Uint8List bytes, File file) async {
    final service = LipikarService();
    try {
      final b64 = base64Encode(bytes);
      final resp = await service.performOcr(
        base64Image: b64,
        language: _selectedLanguage,
        parser: _selectedParser,
      );
      if (!resp.isSuccess) {
        _showSnack('OCR failed: ${resp.error}');
        return;
      }

      final result = resp.data!;
      if (result.results.isEmpty) {
        _showSnack('No text recognized');
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScanResultPage(
            scannedImage: file,
            detectedLanguage: _selectedLanguage,
            results: result.results,
          ),
        ),
      );
    } catch (e) {
      _showSnack('Error processing image: $e');
    } finally {
      service.dispose();
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() => _busy = true);
    try {
      final pick = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
      );
      if (pick == null) throw Exception('No image selected');
      final file = File(pick.path);
      final bytes = await file.readAsBytes();
      await _processFile(bytes, file);
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF667EEA),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}