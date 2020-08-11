
import 'package:flutter/cupertino.dart';
import 'package:pika_joe/styles/styles.dart';

class ButtonType1 extends StatelessWidget {

  final String text;
  final Color textColor;
  final Color bgColor;

  ButtonType1({this.text, this.textColor, this.bgColor});

  @override
  Widget build(BuildContext context) {//TODO - use the material buttons instead
    return Container(
        padding: EdgeInsets.symmetric(
            horizontal: buttonStyle1PaddingHorz,
            vertical: buttonStyle1PaddingVert),
        decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(buttonStyle1BorderRadius)),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: buttonStyle1FontSize,
            fontFamily: buttonStyle1Font,
          )),
      );
  }
}