// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/defaults/dimens.dart';
import 'package:material_themes_widgets/fundamental/buttons_media.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart';

enum AudioPlaybackState { stop, play, pause }

// The player/playback state is owned by the parent (ObservationScreenState) and passed in, rather
// than this widget having its own audio player - it used to, and the observation screen's own
// "big" play button had a second, separate player with separate state. The two never synced with
// each other: pressing one didn't update the other's icon, and both held their own native player
// resources without either being aware of the other.
class AudioContentScroll extends StatelessWidget {

  final List<String> urls;
  final String title;
  final double? imageHeight;
  final double? imageWidth;
  final EdgeInsets padding;
  final List<Widget> icons;
  final List<VoidCallback> iconsClickedCallbacks;
  final String emptyListMessage;
  final AudioPlaybackState playerState;
  final int playingIndex;
  final void Function(int index) onToggle;

  const AudioContentScroll({
    super.key,
    this.urls = const <String>[],
    this.title = "",
    this.imageHeight,
    this.imageWidth,
    this.padding = const EdgeInsets.symmetric(horizontal: 20.0),
    this.icons = const <Widget>[],
    this.iconsClickedCallbacks = const <VoidCallback>[],
    this.emptyListMessage = "",
    this.playerState = AudioPlaybackState.stop,
    this.playingIndex = -1,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        children: <Widget>[
          _buildHeaderRow(),
          if (urls.isEmpty) ... [
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
        itemCount: urls.length,
        itemBuilder: (BuildContext context, int index) {
          return Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 15.0,
            ),
            width: imageWidth,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.0),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  offset: Offset(0.0, 4.0),
                  blurRadius: 6.0,
                ),
              ],
            ),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Stack(
                  children: <Widget>[
                    Center(
                        child:ThemedPlayButton(
                          isPlaying: playerState == AudioPlaybackState.play && playingIndex == index,
                          onPressed: () => onToggle(index),
                        )
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(paddingMini),
                        child: ThemedTitle(basenameWithoutExtension(urls[index]), type:ThemeGroupType.MOM),
                      ),
                    ),
                  ],
                )
            ),
          );
        },
      ),
    );
  }
}
