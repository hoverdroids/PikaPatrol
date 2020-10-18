import 'package:flutter/material.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/fundamental/buttons_media.dart';
import 'package:material_themes_widgets/fundamental/icons.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';
import 'package:material_themes_widgets/defaults/dimens.dart';
import 'package:provider/provider.dart';
import 'dart:io' show File;

class AudioContentScroll extends StatelessWidget {

  final List<String> urls;
  final String title;
  final double imageHeight;
  final double imageWidth;
  final EdgeInsets padding;
  final List<Widget> icons;
  final List<Function> iconsClickedCallbacks;
  final String emptyListMessage;

  AudioContentScroll({
    this.urls,
    this.title = "",
    this.imageHeight,
    this.imageWidth,
    this.padding = const EdgeInsets.symmetric(horizontal: 20.0),
    this.icons,
    this.iconsClickedCallbacks,
    this.emptyListMessage = ""
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        children: <Widget>[
          _buildHeaderRow(),
          if (urls == null || urls.isEmpty) ... [
            miniTransparentDivider,
            _buildEmptyRow(context),
          ] else ... [
            _buildGridView(),
          ]
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      children: [
        ThemedSubTitle(title, type: ThemeGroupType.POM),
        if (icons != null) ... [
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: icons,
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildEmptyRow(BuildContext context) {
    return Card(
      color: context.watch<MaterialThemesManager>().getTheme(ThemeGroupType.MOM).cardTheme.color,
      child: Container(
        width: double.infinity,
        height: imageHeight,
        child: Center(
          child: ThemedTitle(emptyListMessage, type:ThemeGroupType.MOM),
        ),
      ),
    );
  }

  Widget _buildGridView() {
    return Container(
      height: imageHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        itemBuilder: (BuildContext context, int index) {
          return Container(
            margin: EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 15.0,
            ),
            width: imageWidth,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black54,
                  offset: Offset(0.0, 4.0),
                  blurRadius: 6.0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: Center(
                child:ThemedPlayButton(onPressed: () {  },)
              )
            ),
          );
        },
      ),
    );
  }
}
