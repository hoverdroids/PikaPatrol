import 'package:flutter/material.dart';
import 'package:pika_joe/styles/styles.dart';

class Page1 extends Container{

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
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
                  style: goldcoinGreyStyle,
                ),
                Text(
                  "Skip",
                  style: goldcoinGreyStyle,
                ),
              ],
            ),
          ),
          Image.asset("assets/img/firstImage.png"),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              // mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "Online",
                  style: greyStyle,
                ),
                Text(
                  "Gambling",
                  style: boldStyle,
                ),
                SizedBox(
                  height: 20.0,
                ),
                Text(
                  "Temporibus autem aut\n"
                      "officiis debitis aut rerum\n"
                      "necessitatibus",
                  style: descriptionGreyStyle,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}