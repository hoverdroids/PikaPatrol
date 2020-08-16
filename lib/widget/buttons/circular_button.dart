import 'package:flutter/material.dart';
import 'package:pika_joe/styles/styles.dart';

class CircularImageButton extends StatelessWidget {

  AssetImage assetImage;
  ElementSize elementSize;
  ElementStyle elementStyle;
  Function onButtonTapped;

  CircularImageButton({this.assetImage, this.onButtonTapped, this.elementSize = ElementSize.M, this.elementStyle = ElementStyle.LIGHT_ON_LIGHT});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onButtonTapped,
      child: Container(
        height: 60.0,
        width: 60.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, 2),
              blurRadius: 6.0,
            ),
          ],
          image: DecorationImage(
            image: assetImage,
          ),
        ),
      ),
    );
  }
}