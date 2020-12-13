import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:math' as math;

typedef void Callback(CameraImage image);

class Camera extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Callback onImageCapture;

  Camera(this.cameras, this.onImageCapture);

  @override
  _CameraState createState() => _CameraState();
}

class _CameraState extends State<Camera> {
  CameraController controller;

  @override
  void initState() {
    super.initState();

    if (widget.cameras != null && widget.cameras.length >= 1) {
      controller = CameraController(
        widget.cameras[0],
        ResolutionPreset.ultraHigh,
      );
      controller.initialize().then((_) {
        if (mounted) {
          controller.startImageStream((CameraImage image) => widget.onImageCapture(image));
        }
      });
    } else {
      print('No camera is found');
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller.value.isInitialized) {
      return Container();
    }

    var tmp = MediaQuery.of(context).size;
    var screenH = math.max(tmp.height, tmp.width);
    var screenW = math.min(tmp.height, tmp.width);
    tmp = controller.value.previewSize;
    var previewH = math.max(tmp.height, tmp.width);
    var previewW = math.min(tmp.height, tmp.width);
    var screenRatio = screenH / screenW;
    var previewRatio = previewH / previewW;

    return OverflowBox(
      maxHeight: screenRatio > previewRatio ? screenH : screenW / previewW * previewH,
      maxWidth: screenRatio > previewRatio ? screenH / previewH * previewW : screenW,
      child: CameraPreview(controller),
    );
  }
}
