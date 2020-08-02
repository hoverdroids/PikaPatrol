import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pika_joe/styles/colors.dart';
import 'package:pika_joe/styles/styles.dart';
import 'package:shimmer/shimmer.dart';

class PikaPatrolSpash extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: frppBlue,
      child: Center(
        child: Text("Pika Patrol",
            textAlign: TextAlign.center,
            style: goldcoinGreyStyle),
      ),
    );
  }
}

/*Column(
mainAxisAlignment: MainAxisAlignment.spaceEvenly,
crossAxisAlignment: CrossAxisAlignment.start,
children: <Widget>[
Stack(
alignment: Alignment.center,
children: <Widget>[
Container(
padding: EdgeInsets.all(16.0),
child: Text("Pika Patrol",
style: adventureSplashStyle
),
),
Row(
padding: EdgeInsets.all(16.0),
child: Image.asset('assets/img/frppLogo.png')
),
],
),
],
),*/

