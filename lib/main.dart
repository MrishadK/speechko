import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image-to-Speech Tool',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ImageToSpeechScreen(),
    );
  }
}

class ImageToSpeechScreen extends StatefulWidget {
  @override
  _ImageToSpeechScreenState createState() => _ImageToSpeechScreenState();
}

class _ImageToSpeechScreenState extends State<ImageToSpeechScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isProcessing = false;
  String _extractedText = '';

  @override
  void initState() {
    super.initState();
    _pickImageFromCamera(); // Automatically open the camera when the app starts
  }

  Future<void> _pickImageFromCamera() async {
    final XFile? imageFile = await _imagePicker.pickImage(source: ImageSource.camera);

    if (imageFile == null) {
      setState(() {
        _isProcessing = false;
        _extractedText = 'No image captured.';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _extractedText = ''; // Clear previous text
    });

    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final textRecognizer = TextRecognizer();
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      textRecognizer.close();

      setState(() {
        _extractedText = recognizedText.text;
        _isProcessing = false;
      });

      if (_extractedText.isNotEmpty) {
        _detectLanguageAndSpeak(_extractedText);
      } else {
        _speakText('No readable text found. Please try again.');
      }
    } catch (e) {
      print('Error recognizing text: $e');
      setState(() {
        _isProcessing = false;
        _extractedText = 'Error processing image. Please try again.';
      });
    }
  }

  Future<void> _detectLanguageAndSpeak(String text) async {
    try {
      // Detect the language code based on text
      final languageCode = await _detectLanguageCode(text);
      print('Detected language: $languageCode');

      // Set TTS language
      await _flutterTts.setLanguage(languageCode);

      // Speak the text
      _speakText(text);
    } catch (e) {
      print('Error detecting language or speaking: $e');
      _speakText('Error detecting language. Speaking in default language.');
    }
  }

  Future<String> _detectLanguageCode(String text) async {
    // Use regular expressions to detect Malayalam or default to English
    if (RegExp(r'[\u0D00-\u0D7F]').hasMatch(text)) {
      return 'ml-IN'; // Malayalam
    }
    return 'en-US'; // Default to English
  }

  void _speakText(String text) async {
    await _flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image-to-Speech Tool'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _isProcessing
                ? CircularProgressIndicator()
                : Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Text(
                _extractedText.isNotEmpty
                    ? _extractedText
                    : 'Captured text will appear here after processing.',
                style: TextStyle(fontSize: 16.0, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}
