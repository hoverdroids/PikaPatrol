import 'package:flutter/material.dart';

class CenterBounceIn extends PageRouteBuilder {

  final Widget widget;

  CenterBounceIn({this.widget}) : super (
    transitionDuration: Duration(seconds: 1),
    transitionsBuilder: (BuildContext context, Animation<double> animation, Animation<double> secAnimation, Widget child) {
      animation = CurvedAnimation(parent: animation, curve: Curves.elasticInOut);
      return ScaleTransition(alignment: Alignment.center, scale: animation, child: child);
    },
    pageBuilder: ((BuildContext context, Animation<double> animation, Animation<double> secAnimation){
      return widget;
    })
  );
}