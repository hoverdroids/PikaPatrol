import 'package:flutter/material.dart';
import 'dart:io';

class UniversalImage extends StatelessWidget {

  final String path;
  final String emptyAssetPath;

  const UniversalImage(this.path, {super.key,  this.emptyAssetPath = "assets/images/add_image.png" });

  @override
  Widget build(BuildContext context) {
    if(path.isEmpty) {
      return Image(
        height: 300.0,
        width: double.infinity,
        fit: BoxFit.cover,
        image: AssetImage(emptyAssetPath),
      );
    } else if(path.contains("https://")) {
      return Image.network(
        path,
        height: 300.0,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else {
      return Image.file(
        File(path),
        height: 300.0,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }
  }
}