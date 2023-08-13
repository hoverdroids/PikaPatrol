import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/defaults/dimens.dart';
import 'package:material_themes_widgets/fundamental/icons.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';
import 'package:provider/provider.dart';

class ContentScroll extends StatelessWidget {

  final List<String> images;
  final String title;
  final double? imageHeight;
  final double? imageWidth;
  final EdgeInsets padding;
  final List<Widget> icons;
  final List<VoidCallback> iconsClickedCallbacks;
  final String emptyListMessage;
  final Function? onDeleteClickedCallback;

  ContentScroll({
    this.images = const <String>[],
    this.title = "",
    this.imageHeight,
    this.imageWidth,
    this.padding = const EdgeInsets.symmetric(horizontal: 20.0),
    this.icons = const <Widget>[],
    this.iconsClickedCallbacks = const <VoidCallback>[],
    this.emptyListMessage = "",
    this.onDeleteClickedCallback
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        children: <Widget>[
          _buildHeaderRow(),
          if (images.isEmpty) ... [
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
        if (icons.isNotEmpty) ... [
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
        itemCount: images.length,
        itemBuilder: (BuildContext context, int index) {
          return Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 15.0,
            ),
            width: imageWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  offset: Offset(0.0, 4.0),
                  blurRadius: 6.0,
                ),
              ],
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: images[index].contains("https://")
                      ? Image.network(
                    images[index],
                    fit: BoxFit.cover,
                  )
                      : Image.file(
                      File(images[index]),
                      fit: BoxFit.cover),
                ),
                ThemedIconButton(Icons.delete, type: ThemeGroupType.MOI, onPressedCallback: () => {
                    if (onDeleteClickedCallback != null) {
                      onDeleteClickedCallback!(images[index])
                    }
                  }
                )
              ],
            )
          );
        },
      ),
    );
  }
}
