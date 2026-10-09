// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/defaults/dimens.dart';
import 'package:material_themes_widgets/fundamental/icons.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';
import 'package:pika_patrol/primitives/overlay_mode.dart';
import 'package:pika_patrol/widgets/universal_image.dart';
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
  final bool showDeleteButtonOnCard;

  const ContentScroll({
    super.key,
    this.images = const <String>[],
    this.title = "",
    this.imageHeight,
    this.imageWidth,
    this.padding = const EdgeInsets.symmetric(horizontal: 20.0),
    this.icons = const <Widget>[],
    this.iconsClickedCallbacks = const <VoidCallback>[],
    this.emptyListMessage = "",
    this.onDeleteClickedCallback,
    this.showDeleteButtonOnCard = false
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
      child: SizedBox(
        width: double.infinity,
        height: imageHeight,
        child: Center(
          child: ThemedTitle(emptyListMessage, type:ThemeGroupType.MOM),
        ),
      ),
    );
  }

  Widget _buildGridView() {
    return SizedBox(
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
                // Fills the whole card, cropping the photo instead of stretching it or leaving bars
                Positioned.fill(
                  child: ClipRRect(
                    clipBehavior: Clip.antiAlias,
                    borderRadius: BorderRadius.circular(10.0),
                    child: UniversalImage(
                      images[index],
                      overlayMode: OverlayMode.never,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
                if (showDeleteButtonOnCard)...[
                  Align(
                    alignment: Alignment.topRight,
                    child: ThemedOverlayIconButton(Icons.delete, onPressedCallback: () {
                      onDeleteClickedCallback?.call(images[index]);
                    }),
                  )
                ]
              ],
            )
          );
        },
      ),
    );
  }
}
