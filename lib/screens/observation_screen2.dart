import 'package:flutter/material.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/appbars/icon_title_icon_fake_appbar.dart';
import 'package:material_themes_widgets/clippaths/clip_paths.dart';
import 'package:material_themes_widgets/defaults/dimens.dart';
import 'package:material_themes_widgets/fundamental/icons.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';
import 'package:pika_joe/screens/training/training_screens_pager.dart';
import 'package:pika_joe/widget/netflix/circular_clipper.dart';
import 'package:pika_joe/widget/netflix/content_scroll.dart';
import 'package:pika_joe/widget/netflix/movie_model.dart';
import 'package:provider/provider.dart';
import 'package:chips_choice/chips_choice.dart';

class ObservationScreen2 extends StatefulWidget {

  final Movie movie;

  ObservationScreen2({this.movie});

  @override
  _ObservationScreen2State createState() => _ObservationScreen2State();
}

class _ObservationScreen2State extends State<ObservationScreen2> {

  EdgeInsets _horzPadding = EdgeInsets.symmetric(horizontal: 20.0);
  bool isEditMode = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    return Container(
      height: 330,
      child: Stack(
        children: <Widget>[
          Container(
            child: Hero(
              tag: widget.movie.imageUrl,
              child: ClipShadowPath(
                clipper: SimpleClipPath(
                    type: ClipPathType.ROUNDED_DOWN,
                    bottomLeftPercentOfHeight: 80,
                    bottomRightPercentOfHeight: 80
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
          child: Align(
            alignment: Alignment.bottomCenter,
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
              bottom: 10.0,
              left: 10.0,
              child: ThemedIconButton(
                Icons.add_location,
                iconSize: IconSize.MEDIUM,
                onPressedCallback: () => print('Allow user to manually select a geo point'),
              )
          ),
          Positioned(
            bottom: 10.0,
            right: 10.0,
            child: ThemedIconButton(
              Icons.help,
              iconSize: IconSize.MEDIUM,
              onPressedCallback: () => {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (BuildContext context) =>
                      TrainingScreensPager(
                          backClickedCallback: () =>
                              Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (BuildContext context) => ObservationScreen2(movie: movies[0]))//TODO - ensure the previous state isn't override when a user gets help
                              )
                      )
                  )
                )
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: _horzPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          smallTransparentDivider,
          ThemedH5("OBSERVATION NAME", type: ThemeGroupType.POM, emphasis: Emphasis.HIGH),
          miniTransparentDivider,
          ThemedSubTitle("Location Name", type: ThemeGroupType.MOM),
          smallTransparentDivider,
          ThemedTitle('⭐ ⭐ ⭐ ⭐', type: ThemeGroupType.SOM),//TODO - hide until we allow jo
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
    return Padding(
      padding: _horzPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          smallTransparentDivider,
          ThemedSubTitle("Habitat Description", type: ThemeGroupType.POM),
          miniTransparentDivider,
          Container(
            height: 120.0,
            child: SingleChildScrollView(
              child: ThemedBody(
                widget.movie.description,
                type: ThemeGroupType.MOM,
              ),
            ),
          ),
          smallTransparentDivider,
          ThemedSubTitle("Detectable Signs", type: ThemeGroupType.POM),
          _buildDetectableSigns(),
          smallTransparentDivider,
          ThemedSubTitle("Pikas Detected", type: ThemeGroupType.POM),
        ],
      ),
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

  // single choice value
  int tag = 1;

  // multiple choice value
  List<String> tags = [];

  // list of string options
  List<String> options = [
    'News', 'Entertainment', 'Politics',
    'Automotive', 'Sports', 'Education',
    'Fashion', 'Travel', 'Food', 'Tech',
    'Science',
  ];

  Widget _buildDetectableSigns() {
    return // available configuration for single choice
      Content(
        title: 'Scrollable List Single Choice',
        child: ChipsChoice<int>.single(
          value: tag,
          onChanged: (val) => setState(() => tag = val),
          choiceItems: C2Choice.listFrom<int, String>(
            source: options,
            value: (i, v) => i,
            label: (i, v) => v,
            tooltip: (i, v) => v,
          ),
        ),
      );
  }
}


class Content extends StatefulWidget {

  final String title;
  final Widget child;

  Content({
    Key key,
    @required this.title,
    @required this.child,
  }) : super(key: key);

  @override
  _ContentState createState() => _ContentState();
}

class _ContentState extends State<Content> with AutomaticKeepAliveClientMixin<Content>  {

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(5),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            color: Colors.blueGrey[50],
            child: Text(
              widget.title,
              style: const TextStyle(
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.w500
              ),
            ),
          ),
          Flexible(
              fit: FlexFit.loose,
              child: widget.child
          ),
        ],
      ),
    );
  }
}