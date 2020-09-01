
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_themes_widgets/fundamental/icons.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';
import 'package:pika_joe/styles/colors.dart';
import 'package:pika_joe/styles/styles.dart';
import 'package:material_themes_manager/material_themes_manager.dart';

class MenuTitleProfileAppBar extends AppBar {

  final String appName;
  final Function openMenuCallback;
  final Function openProfileCallback;

  MenuTitleProfileAppBar({this.appName, this.openMenuCallback, this.openProfileCallback}) : super(
    backgroundColor: Colors.transparent,
    title: ThemedTitle(appName, type: ThemeGroupType.MOP, emphasis: Emphasis.HIGH),
    centerTitle: true,
    elevation: 0.0,
    leading: IconButton(// TODO - migrate to ThemedIconButton
      onPressed: openMenuCallback,
      icon: ThemedIcon(Icons.menu, type: ThemeGroupType.MOP, emphasis: Emphasis.HIGH),
      //iconSize: appbarIconSize,
      //color: iconDarkBgColor,
    ),
    actions: <Widget>[
      IconButton(// TODO - migrate to ThemedIconButton
        onPressed: openProfileCallback,
        icon: ThemedIcon(Icons.account_circle, type: ThemeGroupType.MOP, emphasis: Emphasis.HIGH),
        //iconSize: appbarIconSize,//TODO
        //color: iconDarkBgColor,//TODO
      ),
    ],
  );
}