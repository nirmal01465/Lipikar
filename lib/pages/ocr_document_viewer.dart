// Updated OcrDocumentViewerPage
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/finances_colors.dart';
import '../widgets/ocr_overview_model.dart';
import 'ocr_scan_implementation.dart';

class OcrDocumentViewerPage extends StatefulWidget {
  final File scannedImage;

  const OcrDocumentViewerPage({
    Key? key,
    required this.scannedImage,
  }) : super(key: key);

  @override
  State<OcrDocumentViewerPage> createState() => _OcrDocumentViewerPageState();
}

class _OcrDocumentViewerPageState extends State<OcrDocumentViewerPage> {
  bool _isProcessing = true;
  String _errorMessage = '';
  OcrViewModel? _viewModel;

  @override
  void initState() {
    super.initState();
    _initializeOcr();
  }

  Future<void> _initializeOcr() async {
    try {
      _viewModel = OcrViewModel(widget.scannedImage);
      _viewModel!.addListener(_handleViewModelUpdate);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error initializing OCR: $e';
        _isProcessing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error processing OCR: $e')));
      }
    }
  }

  void _handleViewModelUpdate() {
    if (_viewModel != null && _viewModel!.wordElements.isNotEmpty) {
      setState(() {
        _isProcessing = false;
      });
      _viewModel!.removeListener(_handleViewModelUpdate);
    }
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_handleViewModelUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isProcessing
          ? Container(
        color: DocAppColors.lightPurple,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: DocAppColors.purple),
              const SizedBox(height: 16),
              Text(
                'Processing OCR...',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Detecting text and generating polygons',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white.withOpacity(0.8)),
              ),
            ],
          ),
        ),
      )
          : _errorMessage.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'OCR Processing Error',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: DocAppColors.purple),
              child: const Text('Go Back'),
            ),
          ],
        ),
      )
          : _viewModel != null
          ? ChangeNotifierProvider.value(
        value: _viewModel!,
        child: const SynchronizedOcrViewer(),
      )
          : const Center(child: Text('Failed to process image. Please try again.')),
    );
  }
}