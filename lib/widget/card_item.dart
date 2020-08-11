
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pika_joe/mock/data.dart';
import 'package:pika_joe/styles/colors.dart';
import 'package:pika_joe/styles/styles.dart';
import 'package:pika_joe/widget/buttons.dart';
import 'dart:math';

import 'card_title.dart';

class CardItem extends StatelessWidget {

  final String title;
  final int delta;
  final double start;
  final bool isOnRight;
  final String img;

  CardItem({this.title, this.delta, this.start, this.isOnRight, this.img});

  @override
  Widget build(BuildContext context) {

    return Positioned.directional(
      top: cardScrollWidgetPadding + cardScrollWidgetVerticalInset * max(-delta, 0.0),
      bottom: cardScrollWidgetPadding + cardScrollWidgetVerticalInset * max(-delta, 0.0),
      start: start,
      textDirection: TextDirection.rtl,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cardBorderRadius),
        child: Container(
          decoration: BoxDecoration(
            color: cardDecorationColor,
            boxShadow: [ cardShadow ],
          ),
          child: AspectRatio(
            aspectRatio: cardAspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Image.asset(img, fit: BoxFit.cover),//TODO - need to not assume the image is local
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      CardTitle(title: title),
                      cardTitleSpacer,
                      Padding(
                        padding: EdgeInsets.only(left: cardButtonInsetLeft, bottom: cardButtonInsetBottom),
                        child: ButtonType1(text: "View Observation", textColor: cardButtonTextColor, bgColor: cardButtonColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}