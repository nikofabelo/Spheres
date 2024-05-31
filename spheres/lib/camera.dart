import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gal/gal.dart';
import 'package:image/image.dart';
import 'package:screenshot/screenshot.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:vibration/vibration.dart';

import 'sphere.dart';

typedef CameraState = _CameraState;

class Camera extends StatefulWidget {
  const Camera({super.key});

  @override
  CameraState createState() => CameraState();
}

class _CameraState extends State<Camera> {
  late ArCoreController arCoreController;
  final screenshotController = ScreenshotController();

  double whiteRectOpacity = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Screenshot(
          controller: screenshotController,
          child: ArCoreView(
            onArCoreViewCreated: _onArCoreViewCreated
          )
        ),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: whiteRectOpacity,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle
            )
          )
        ),
        Positioned(
          bottom: 90,
          left: (MediaQuery.of(context).size.width - 62) / 2,
          child: GestureDetector(
            onTap: _captureScreenshot,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 3.6
                ),
                shape: BoxShape.circle
              ),
              height: 62,
              width: 62,
              child: Center(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle
                  ),
                  height: 40,
                  width: 40
                )
              )
            )
          )
        )
      ]
    );
  }

  @override
  void dispose() {
    arCoreController.dispose();
    super.dispose();
  }

  void _onArCoreViewCreated(ArCoreController controller) {
    arCoreController = controller;
    _addSpheres();
  }

  Future<void> _captureScreenshot() async {
    if (!await Gal.hasAccess(toAlbum: true)) {
      if (!await Gal.requestAccess(toAlbum: true)) {
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate();
        }

        Fluttertoast.showToast(
          backgroundColor: Colors.red,
          gravity: ToastGravity.TOP,
          msg: GalExceptionType.accessDenied.message,
          toastLength: Toast.LENGTH_LONG
        );

        return;
      }
    }

    AudioPlayer().play(AssetSource('camera.mp3'));

    setState(() {
      whiteRectOpacity = 0.8;
    });
    await Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        whiteRectOpacity = 0;
      });
    });

    final capture = await screenshotController.capture();

    if (capture != null) {
      final image = decodePng(capture);

      bool isBlack = true;

      for (int x = 0; x < image!.width; x++) {
        for (int y = 0; y < image.height; y++) {
          final pixel = image.getPixel(x, y);

          if (pixel.r != 0 || pixel.g != 0 || pixel.b != 0) {
            isBlack = false;
          }
        }
      }

      if (isBlack)
      {
        Fluttertoast.showToast(
          backgroundColor: Colors.red,
          gravity: ToastGravity.TOP,
          msg: GalExceptionType.unexpected.message,
          toastLength: Toast.LENGTH_LONG
        );

        return;
      }

      final filename = DateTime.now().millisecondsSinceEpoch.toString();

      try {
        await Gal.putImageBytes(capture, album: 'Spheres', name: filename);
      } on GalException catch (e) {
        Fluttertoast.showToast(
          backgroundColor: Colors.red,
          gravity: ToastGravity.TOP,
          msg: e.type.message,
          toastLength: Toast.LENGTH_LONG
        );

        return;
      }

      Fluttertoast.showToast(
        backgroundColor: Colors.green,
        gravity: ToastGravity.TOP,
        msg: 'Image saved, beautiful! 🥰',
        toastLength: Toast.LENGTH_SHORT
      );
    } else {
      Fluttertoast.showToast(
        backgroundColor: Colors.red,
        gravity: ToastGravity.TOP,
        msg: GalExceptionType.unexpected.message,
        toastLength: Toast.LENGTH_LONG
      );
    }
  }

  Future<void> _addSpheres() async { // TODO
    const names = [
      'sun', 'mercury', 'venus', 'earth', 'moon',
      'mars', 'jupiter', 'uranus', 'neptune'
    ];

    const colors = [
      Colors.yellow, Colors.brown, Colors.orange, Colors.blue, Colors.grey,
      Colors.deepOrange, Colors.brown, Colors.blue, Colors.blue
    ];

    const radiuses = [
      // Sun
      1.0,
      // Mercury
      // 0.024,
      0.048,
      // Venus
      // 0.061,
      0.122,
      // Earth
      // 0.064,
      0.128,
      // Moon
      // 0.017,
      0.034,
      // Mars
      // 0.034,
      0.068,
      // Jupiter
      0.80,
      // Uranus
      0.25,
      // Neptune
      0.24
    ];

    const degreesPerSecond = [
      1.0,  // Sun
      3.0,  // Mercury
      4.0,  // Venus
      5.0,  // Earth
      10.0, // Moon
      2.0,  // Mars
      0.5,  // Jupiter
      0.2,  // Uranus
      0.1   // Neptune
    ];

    final positions = [
      // Sun
      vector.Vector3(0, 0, 0),
      // Mercury
      vector.Vector3(0, 0, 1.20),
      // Venus
      vector.Vector3(-1.20, 0, 1.30),
      // Earth
      vector.Vector3(1.20, 0, 1.30),
      // Moon
      vector.Vector3(1.20, 0, 1.32),
      // Mars
      vector.Vector3(0, 0, -1.20),
      // Jupiter
      vector.Vector3(-2.5, 0, 0),
      // Uranus
      vector.Vector3(0, 0, 1.40),
      // Neptune
      vector.Vector3(-1.20, 0, -1.20)
    ];

    for (int i = 0; i < names.length; i++) {
      final node = await Sphere(
        name: names[i],
        color: colors[i],
        radius: radiuses[i],
        degreesPerSecond: degreesPerSecond[i],
        position: positions[i]
      ).getNode();

      arCoreController.addArCoreNode(node);
    }
  }
}