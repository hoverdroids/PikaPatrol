import 'package:flutter/material.dart';
import 'package:pika_joe/styles/styles.dart';

class Page2 extends Container {

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFF55006c),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  "GoldCoin",
                  style: goldCoinWhiteStyle,
                ),
                Text(
                  "Skip",
                  style: goldCoinWhiteStyle,
                ),
              ],
            ),
          ),
          Image.asset("assets/img/secondImage.png"),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "Online",
                  style: whiteStyle,
                ),
                Text(
                  "Gaming",
                  style: boldStyle,
                ),
                SizedBox(
                  height: 20.0,
                ),
                Text(
                  "Excepteur sint occaecat cupidatat\n"
                      "non proident, sunt in\n"
                      "culpa qui officia",
                  style: descriptionWhiteStyle,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}