
import 'dart:async';
import 'package:flutter/material.dart';
import 'image_labeler.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';


List<CameraDescription> cameras;

Future<void> main() async {
  // Fetch the available cameras before initializing the app.
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    logError(e.code, e.description);
  }
  runApp(new MaterialApp(
    home: CameraApp(),
  ));
}

void logError(String code, String message) =>
  print('Error: $code\nError Message: $message');

class CameraApp extends StatefulWidget {
  @override
  _CameraAppState createState() => new _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  CameraController controller;
  static const channel = const MethodChannel('channel.ar');
  final ImageLabeler reader = ImageLabeler.instance;
  
  @override
  void initState() {
    super.initState();
    controller = CameraController(cameras[0], ResolutionPreset.medium);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
    reader.addListener(() {
      setState(() {});
    });
    reader.init();
  }
  
  @override
  void dispose() {
    controller?.dispose();
    reader.dispose();
    super.dispose();
  }
  
//  String _imageLabel() {
//
// }
// Just in case.
  
  Future<Null> _sendData() async {
    final response =
      await channel.invokeMethod("receiveData", reader.value);
  }
  
  
  
  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      return const Text(
        'Tap a camera',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: CameraPreview(controller),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SpeakAR'
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              child: Padding(
                padding: const EdgeInsets.all(1.0),
                child: Center(
                  child: _cameraPreviewWidget(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}