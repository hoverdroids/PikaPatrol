
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/defaults/dimens.dart';
import 'package:material_themes_widgets/fundamental/buttons_media.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart';

class AudioContentScroll extends StatefulWidget {

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

  _AudioContentScrollState createState() => _AudioContentScrollState();
}

class _AudioContentScrollState extends State<AudioContentScroll>{

  AssetsAudioPlayer assetsAudioPlayer = AssetsAudioPlayer();

  PlayerState _playerState = PlayerState.stop;
  int _playingIndex = -1;

  @override
  void dispose() {
    assetsAudioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: Column(
        children: <Widget>[
          _buildHeaderRow(),
          if (widget.urls == null || widget.urls.isEmpty) ... [
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
        ThemedSubTitle(widget.title, type: ThemeGroupType.POM),
        if (widget.icons != null) ... [
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: widget.icons,
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
        height: widget.imageHeight,
        child: Center(
          child: ThemedTitle(widget.emptyListMessage, type:ThemeGroupType.MOM),
        ),
      ),
    );
  }

  Widget _buildGridView() {
    return Container(
      height: widget.imageHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.urls.length,
        itemBuilder: (BuildContext context, int index) {
          return Container(
            margin: EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 15.0,
            ),
            width: widget.imageWidth,
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
              child: Stack(
                children: <Widget>[
                  Center(
                      child:ThemedPlayButton(
                        isPlaying: _playerState == PlayerState.play && _playingIndex == index,
                        onPressed: () {
                          if (_playerState == PlayerState.stop || _playingIndex != index) {

                            if (_playerState != PlayerState.stop) {
                              //Release the currently loaded file
                              assetsAudioPlayer.stop();
                            }

                            assetsAudioPlayer = AssetsAudioPlayer();//create a new player after the current file has stopped

                            assetsAudioPlayer.playlistAudioFinished.listen((Playing playing){
                              setState(() {
                                _playerState = PlayerState.stop;
                                _playingIndex = -1;
                              });
                            });

                            var url = widget.urls[index];
                            assetsAudioPlayer.open(url.contains("http") ? Audio.network(url) : Audio.file(url));
                            assetsAudioPlayer.play();

                            setState(() {
                              _playingIndex = index;
                              _playerState = PlayerState.play;
                            });

                          } else if (_playerState == PlayerState.play) {
                            assetsAudioPlayer.pause();
                            setState(() {
                              _playerState = PlayerState.pause;
                            });

                          } else {
                            assetsAudioPlayer.play();
                            setState(() {
                              _playerState = PlayerState.play;
                            });
                          }
                        },
                      )
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.all(paddingMini),
                      child: ThemedTitle(basenameWithoutExtension(widget.urls[index]), type:ThemeGroupType.MOM),
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
