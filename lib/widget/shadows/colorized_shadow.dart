import 'package:flutter/material.dart';

class ColorizedShadow extends StatelessWidget {

  final Widget child;
  final double height;
  final bool isCircular;
  final Color color;

  ColorizedShadow({
    @required this.child,
    @required this.height,
    this.isCircular = false,
    this.color = Colors.black
  }) : assert(child != null);

  @override
  Widget build(BuildContext context) {



    return Container(
      height: this.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(this.height / 2)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: height / 5,
            offset: Offset(0, height / 5),
          ),
        ],
      ),
      child: this.child,
    );
  }
}