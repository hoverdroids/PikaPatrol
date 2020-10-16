import 'package:flutter/material.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/appbars/icon_title_icon_fake_appbar.dart';
import 'package:material_themes_widgets/clippaths/clip_paths.dart';
import 'package:material_themes_widgets/defaults/dimens.dart';
import 'package:material_themes_widgets/fundamental/icons.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';
import 'package:pika_joe/widget/netflix/circular_clipper.dart';
import 'package:pika_joe/widget/netflix/content_scroll.dart';
import 'package:pika_joe/widget/netflix/movie_model.dart';
import 'package:provider/provider.dart';

class ObservationScreen2 extends StatefulWidget {

  final Movie movie;

  ObservationScreen2({this.movie});

  @override
  _ObservationScreen2State createState() => _ObservationScreen2State();
}

class _ObservationScreen2State extends State<ObservationScreen2> {

  bool isEditMode = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: _buildAppbar(),
      /*extendBodyBehindAppBar: true,
      extendBody: true,*/
      backgroundColor: context.watch<MaterialThemesManager>().getTheme(ThemeGroupType.MOM).scaffoldBackgroundColor,
      body: Stack(
        children: <Widget>[
          SingleChildScrollView(
            child: Column(
              children: [
                _buildHeaderImage(),
                _buildHeader(),
                _buildFields(),
                _buildImages(),
                _buildAudioRecordings(),
              ],
            ),
          ),
          _buildAppbar(),
        ],
      ),
    );
  }

  Widget _buildAppbar() {
    return IconTitleIconFakeAppBar(
      title: 'Make Observation',
      titleType: ThemeGroupType.MOI,
      leftIcon: Icons.arrow_back,
      leftIconType: ThemeGroupType.MOI,
      leftIconClickedCallback: () => Navigator.pop(context),
      rightIcon: Icons.edit,
      rightIconType: ThemeGroupType.MOI,
      rightIconClickedCallback: () => print("TODO - toggle between edit/view mode when not a new observation"),
    );
  }

  Widget _buildHeaderImage() {
    return Stack(
      children: <Widget>[
        Container(
          //color: Colors.red,
          //transform: Matrix4.translationValues(0.0, -50.0, 0.0),
          child: Hero(
            tag: widget.movie.imageUrl,
            child: ClipShadowPath(
              clipper: SimpleClipPath(
                type: ClipPathType.ROUNDED_DOWN,
                bottomLeftPercentOfHeight: 75,
                bottomRightPercentOfHeight: 75
              ),
              shadow: Shadow(blurRadius: 20.0),
              child: Image(
                height: 300.0,
                width: double.infinity,
                fit: BoxFit.cover,
                image: AssetImage(widget.movie.imageUrl),
              ),
            ),
          ),
        ),
        Positioned.fill(
          top: 0.0,
          child: Align(
            //alignment: Alignment.bottomCenter,
            child: RawMaterialButton(
              padding: EdgeInsets.all(10.0),
              elevation: 12.0,
              onPressed: () => print('Play Video'),
              shape: CircleBorder(),
              fillColor: Colors.white,
              child: Icon(
                Icons.play_arrow,
                size: 60.0,
                color: Colors.brown,
              ),
            ),
          ),
        ),
        Positioned(
            bottom: 0.0,
            left: 00.0,
            child: ThemedIconButton(
              Icons.add_location,
              iconSize: IconSize.MEDIUM,
              onPressedCallback: () => print('Allow user to manually select a geo point'),
            )
        ),
        Positioned(
          bottom: 0.0,
          right: 0.0,
          child: ThemedIconButton(
            Icons.help,
            iconSize: IconSize.MEDIUM,
            onPressedCallback: () => print('Share'),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          ThemedH5("OBSERVATION NAME", type: ThemeGroupType.POM, emphasis: Emphasis.HIGH),
          miniTransparentDivider,
          ThemedSubTitle("Location Name", type: ThemeGroupType.MOM),
          //smallTransparentDivider,
          //ThemedTitle('⭐ ⭐ ⭐ ⭐', type: ThemeGroupType.SOM),//TODO - hide until we allow jo
          smallTransparentDivider,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Column(
                children: <Widget>[
                  Text(
                    'Year',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 16.0,
                    ),
                  ),
                  SizedBox(height: 2.0),
                  Text(
                    widget.movie.year.toString(),
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                children: <Widget>[
                  Text(
                    'Country',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 16.0,
                    ),
                  ),
                  SizedBox(height: 2.0),
                  Text(
                    widget.movie.country.toUpperCase(),
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                children: <Widget>[
                  Text(
                    'Length',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 16.0,
                    ),
                  ),
                  SizedBox(height: 2.0),
                  Text(
                    '${widget.movie.length} min',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        mediumTransparentDivider,
        ThemedSubTitle("Habitat Description", type: ThemeGroupType.POM),
        miniTransparentDivider,
        Container(
          height: 120.0,
          child: SingleChildScrollView(
            child: Text(
              widget.movie.description,
              style: TextStyle(
                color: Colors.black54,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImages() {
    return ContentScroll(
      images: widget.movie.screenshots,
      title: 'Images',
      imageHeight: 200.0,
      imageWidth: 250.0,
    );
  }

  Widget _buildAudioRecordings() {
    return ContentScroll(
      images: widget.movie.screenshots,
      title: 'Audio Recordings',
      imageHeight: 200.0,
      imageWidth: 250.0,
    );
  }
}
