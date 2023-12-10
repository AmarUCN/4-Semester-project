import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CameraController? controller;
  String recognizedText = "";
  XFile? pictureFile;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  void initializeCamera() async {
    final cameras = await availableCameras();

    controller = CameraController(cameras[0], ResolutionPreset.max);
    await controller!.initialize();

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> processImage() async {
    try {
      XFile? file;

      if (pictureFile == null) {
        // If no predefined image, take a picture with the camera
        file = await controller!.takePicture();
      } else {
        // Use the predefined image or image from the gallery
        file = pictureFile;
      }

      final File imageFile = File(file!.path);
      final inputImage = InputImage.fromFilePath(imageFile.path);

      final TextRecognizer textRecognizer = GoogleMlKit.vision.textRecognizer();
      final RecognizedText recognisedText = await textRecognizer.processImage(inputImage);

      // Process the recognized text
      setState(() {
        recognizedText = recognisedText.text;
      });

      textRecognizer.close();
    } catch (e) {
      print("Error processing image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: controller != null && controller!.value.isInitialized
                    ? CameraPreview(controller!)
                    : Container(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: processImage,
                child: const Text("Capture and Recognize Text"),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Load an image from the assets folder
                  final ByteData data = await rootBundle.load('assets/Test.png');
                  final List<int> bytes = data.buffer.asUint8List();
                  final tempFile = File('${(await getTemporaryDirectory()).path}/Test.png');
                  await tempFile.writeAsBytes(bytes);

                  setState(() {
                    pictureFile = XFile(tempFile.path);
                  });
                },
                child: const Text("Use Image from Assets"),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Pick an image from the gallery
                  final image = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() {
                      pictureFile = XFile(image.path);
                    });
                  }
                },
                child: const Text("Pick Image from Gallery"),
              ),
              if (recognizedText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Recognized Text: $recognizedText",
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}