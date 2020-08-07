import 'package:flutter/material.dart';
import 'package:pika_joe/styles/styles.dart';

class SidebarItem extends StatelessWidget {

  final String text;
  final IconData iconData;
  final double height;
  final double size;

  SidebarItem({this.text, this.iconData, this.height, this.size});

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Icon(
            iconData,
            color: Colors.black45,
          ),
          SizedBox(
            width: 10,
          ),
          Text(
            text,
            style: sidebarItemStyle
          ),
        ],
      ),
      onPressed: () {},
    );
  }
}