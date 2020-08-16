
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pika_joe/styles/colors.dart';
import 'package:pika_joe/styles/styles.dart';

class MenuTitleProfileAppBar extends AppBar {

  final String appName;
  Function openMenuCallback;
  Function openProfileCallback;

  MenuTitleProfileAppBar({this.appName, this.openMenuCallback, this.openProfileCallback}) : super(
    backgroundColor: Colors.transparent,
    title: Text(appName),//TODO - apply a style
    centerTitle: true,
    elevation: 0.0,
    leading: IconButton(
      //padding: EdgeInsets.only(left: appbarIconMargin),
      onPressed: openMenuCallback,
      icon: Icon(Icons.menu),
      iconSize: appbarIconSize,
      color: iconDarkBgColor,
    ),
    actions: <Widget>[
      IconButton(
        //padding: EdgeInsets.only(right: appbarIconMargin),
        onPressed: openProfileCallback,
        icon: Icon(Icons.account_circle),
        iconSize: appbarIconSize,
        color: iconDarkBgColor,
      ),
    ],
  );
}