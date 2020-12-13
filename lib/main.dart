import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:tflite/tflite.dart';
import 'dart:math' as math;
import 'camera.dart';
import 'bndbox.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MaterialApp(
      title: 'TensorFlow object detection',
      theme: ThemeData(
        brightness: Brightness.dark,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage();

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<CameraDescription> _cameras;
  List<dynamic> _recognitions;
  int _imageHeight = 0;
  int _imageWidth = 0;
  bool isInitialized = false;
  bool isDetecting = false;

  @override
  void initState() {
    _init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size screen = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          if (isInitialized) ...[
            Camera(_cameras, _onImageCapture),
            BndBox(_recognitions == null ? [] : _recognitions, math.max(_imageHeight, _imageWidth), math.min(_imageHeight, _imageWidth), screen.height, screen.width),
          ] else ...[
            Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  _onImageCapture(CameraImage image) async {
    if (!isDetecting) {
      isDetecting = true;

      final recognitions = await Tflite.detectObjectOnFrame(
        bytesList: image.planes.map((plane) => plane.bytes).toList(),
        model: "YOLO",
        imageHeight: image.height,
        imageWidth: image.width,
        imageMean: 0,
        imageStd: 255.0,
        numResultsPerClass: 1,
        threshold: 0.2,
      );

      setState(() {
        _recognitions = recognitions;
        _imageHeight = image.height;
        _imageWidth = image.width;
        isDetecting = false;
      });
    }
  }

  _init() async {
    try {
      _cameras = await availableCameras();
    } on CameraException catch (e) {
      print('Error: ${e.code}\nError Message: ${e.description}');
    }

    await Tflite.loadModel(
      model: "assets/yolov2_tiny.tflite",
      labels: "assets/yolov2_tiny.txt",
    );

    setState(() {
      isInitialized = true;
    });
  }
}
