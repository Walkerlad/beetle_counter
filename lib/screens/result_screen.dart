// lib/screens/result_screen.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/beetle_detection.dart';
import '../services/roboflow_service.dart';

// ...imports...

class ResultScreen extends StatefulWidget {
  final String imagePath;
  final List<BeetleDetection> beetleDetections;
  final Map<String, dynamic>? rawResponse;

  const ResultScreen({
    Key? key,
    required this.imagePath,
    required this.beetleDetections,
    this.rawResponse,
  }) : super(key: key);

  @override
  _ResultScreenState createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late int _beetleCount;
  bool _isSubmitting = false;
  bool _isUploading = false; // <-- Make sure this is here
  final RoboflowService _roboflowService = RoboflowService();

  @override
  void initState() {
    super.initState();
    _beetleCount = widget.beetleDetections.length;
    print("API Response: ${widget.rawResponse}");
    print("Confidence threshold: 0.09");
    print("Found beetles: ${widget.beetleDetections.length}");
  }

  Future<void> _submitCorrection() async {
    if (_beetleCount == widget.beetleDetections.length) {
      Navigator.pop(context);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final success = await _roboflowService.uploadWithCorrection(
        File(widget.imagePath),
        _beetleCount,
      );
      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Thank you for improving the model!'))
        );
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit correction. Please try again.'))
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'))
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _uploadWithoutCorrection() async {
    setState(() => _isUploading = true);
    try {
      final success = await _roboflowService.uploadToDataset(
        File(widget.imagePath),
        ['beetle_image', 'for_review']
      );
      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image uploaded successfully!'))
        );
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed. Please try again.'))
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'))
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detection Results')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(widget.imagePath), fit: BoxFit.cover),
                  ...widget.beetleDetections.map((detection) {
                    return Positioned(
                      left: detection.x * MediaQuery.of(context).size.width - (detection.width * MediaQuery.of(context).size.width / 2),
                      top: detection.y * MediaQuery.of(context).size.height * 0.4 - (detection.height * MediaQuery.of(context).size.height * 0.4 / 2),
                      width: detection.width * MediaQuery.of(context).size.width,
                      height: detection.height * MediaQuery.of(context).size.height * 0.4,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green, width: 2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Beetles Detected: ${widget.beetleDetections.length}',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 24),
                      Text('Is this count correct?', style: TextStyle(fontSize: 16)),
                      SizedBox(height: 8),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Correct Beetle Count',
                            border: OutlineInputBorder(),
                            hintText: 'Enter the actual number of beetles',
                          ),
                          onChanged: (value) {
                            setState(() {
                              _beetleCount = int.tryParse(value) ?? widget.beetleDetections.length;
                            });
                          },
                        ),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitCorrection,
                        child: _isSubmitting
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(_beetleCount != widget.beetleDetections.length ? 'Submit Correction' : 'Done'),
                      ),
                      SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _isUploading ? null : _uploadWithoutCorrection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: _isUploading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text('Upload Without Correction'),
                      ),
                      if (widget.rawResponse != null) ...[
                        SizedBox(height: 24),
                        ExpansionTile(
                          title: Text('Response Details'),
                          children: [
                            Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                json.encode(widget.rawResponse),
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
