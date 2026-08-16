import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'models/invoice_data.dart';
import 'services/ai_service.dart';
import 'services/line_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Invoice Flex Sender',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Invoice to Line Flex'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ImagePicker _picker = ImagePicker();
  final AiService _aiService = AiService();
  final LineService _lineService = LineService();

  File? _selectedImage;
  InvoiceData? _extractedData;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _extractedData = null; // Reset data when new image is picked
      });
    }
  }

  Future<void> _extractData() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
    });

    final data = await _aiService.extractInvoiceData(_selectedImage!);

    setState(() {
      _extractedData = data;
      _isLoading = false;
    });

    if (data == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to extract data. Please try again.')),
      );
    }
  }

  Future<void> _sendLineMessage() async {
    if (_extractedData == null) return;

    setState(() {
      _isLoading = true;
    });

    final success = await _lineService.sendInvoiceFlexMessage(_extractedData!);

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Line message sent successfully!' : 'Failed to send Line message.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (_selectedImage != null)
                Image.file(
                  _selectedImage!,
                  height: 300,
                  fit: BoxFit.contain,
                )
              else
                const Text('No image selected.'),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Pick Receipt/Screenshot'),
              ),
              const SizedBox(height: 20),
              if (_selectedImage != null && _extractedData == null)
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _extractData,
                  icon: const Icon(Icons.analytics),
                  label: const Text('Extract Information'),
                ),
              if (_isLoading) ...[
                const SizedBox(height: 20),
                const CircularProgressIndicator(),
              ],
              if (_extractedData != null) ...[
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Extracted Data:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 10),
                        Text('Date: ${_extractedData!.date}'),
                        Text('Price: ¥${_extractedData!.price}'),
                        Text('Purpose: ${_extractedData!.purpose}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _sendLineMessage,
                  icon: const Icon(Icons.send),
                  label: const Text('Send via Line Flex'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
