import 'package:flutter/material.dart';
import 'dart:io';

import 'package:pika_patrol/primitives/overlay_mode.dart';

class UniversalImage extends StatelessWidget {

  static const DEFAULT_COLOR = Colors.black;

  final String path;
  final String emptyAssetPath;

  final OverlayMode overlayMode;
  final Color colorWhenImageNotShowing;
  final Color overlayColor;
  final double overlayOpacity;
  final BlendMode blendMode;

  final double height;
  final double width;
  final BoxFit boxFit;

  const UniversalImage(
    this.path,
    {
      super.key,
      this.emptyAssetPath = "assets/images/pika4.jpg",
      this.overlayMode = OverlayMode.sometimes,
      this.colorWhenImageNotShowing = DEFAULT_COLOR,
      this.overlayColor = DEFAULT_COLOR,
      this.overlayOpacity = 0.33,
      this.blendMode = BlendMode.srcOver,
      this.height = 300.0,
      this.width = double.infinity,
      this.boxFit = BoxFit.cover
    }
  );

  @override
  Widget build(BuildContext context) {
    var sometimes = path.isEmpty || _isAssetImage(path);
    var showOverlay = overlayMode == OverlayMode.always || (overlayMode == OverlayMode.sometimes && sometimes);
    var resolvedPath = path.isEmpty ? emptyAssetPath : path;

    if (showOverlay) {
      return _buildImageWithCoverOverlay(resolvedPath);
    }
    return _buildImageWithoutCoverOverlay(resolvedPath);
  }

  Widget _buildImageWithCoverOverlay(String path) {
    ImageProvider imageProvider;
    if(path.isEmpty || _isAssetImage(path)) {
      imageProvider = AssetImage(path);
    } else if(_isNetworkImage(path)) {
      imageProvider = NetworkImage(path);
    } else {
      imageProvider = FileImage(File(path));
    }

    return Container(
      decoration: _buildColorOverlay(imageProvider, colorWhenImageNotShowing, overlayColor, overlayOpacity, blendMode, boxFit),
      height: height,
      width: width,
    );
  }

  Widget _buildImageWithoutCoverOverlay(String path) {
    if(path.isEmpty || _isAssetImage(path)) {
      return Image(
        height: height,
        width: width,
        fit: boxFit,
        image: AssetImage(path),
      );
    } else if(_isNetworkImage(path)) {
      return Image.network(
        path,
        height: height,
        width: width,
        fit: boxFit,
      );
    } else {
      return Image.file(
        File(path),
        height: height,
        width: width,
        fit: boxFit,
      );
    }
  }

  BoxDecoration _buildColorOverlay(
    ImageProvider image,
    Color color,
    Color overlayColor,
    double opacity,
    BlendMode blendMode,
    BoxFit boxFit,
  ) {
    return BoxDecoration(
      color: colorWhenImageNotShowing,
      image: DecorationImage(
        fit: boxFit,
        colorFilter: ColorFilter.mode(overlayColor.withOpacity(opacity), blendMode),
        image: image,
      ),
    );
  }

  bool _isAssetImage(String path) => path.contains("assets/images");
  bool _isNetworkImage(String path) => path.contains("https://");
}