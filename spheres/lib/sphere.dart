import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart';

class Sphere { // TODO
  final String name;
  final Color color;
  final double radius;
  final double degreesPerSecond;
  final Vector3 position;

  late final Uint8List texture;

  Sphere({
    required this.name,
    required this.color,
    required this.radius,
    required this.degreesPerSecond,
    required this.position
  });

  Future<ArCoreRotatingNode> getNode() async {
    final texture = (await rootBundle.load('assets/$name.jpg')).buffer.asUint8List();

    final material = ArCoreMaterial(
      color: color,
      roughness: 1,
      reflectance: 0,
      textureBytes: texture
    );

    final sphere = ArCoreSphere(
      materials: [material],
      radius: radius,
    );

    final node = ArCoreRotatingNode(
      degreesPerSecond: degreesPerSecond,
      position: position,
      shape: sphere
    );

    return node;
  }
}