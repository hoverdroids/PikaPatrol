

import 'package:flutter/cupertino.dart';
import 'package:pika_joe/styles/colors.dart';
import 'package:pika_joe/styles/styles.dart';

class CardTitle extends StatelessWidget {

  final String title;

  CardTitle({this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: cardTitleInsetLeft, vertical: cardTitleInsetBottom),
      child: Text(
        title,
        style: TextStyle(
          color: cardTitleColor,
          fontSize: heading1FontSize,
          fontFamily: heading1Font,
        ),
      ),
    );
  }
}