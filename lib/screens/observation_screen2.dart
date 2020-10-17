import 'dart:async';
import 'dart:io';
import 'package:charcode/charcode.dart';
import 'package:chips_choice/chips_choice.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/appbars/icon_title_icon_fake_appbar.dart';
import 'package:material_themes_widgets/clippaths/clip_paths.dart';
import 'package:material_themes_widgets/defaults/dimens.dart';
import 'package:material_themes_widgets/fundamental/icons.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';
import 'package:material_themes_widgets/fundamental/toggles.dart';
import 'package:pika_joe/screens/training/training_screens_pager.dart';
import 'package:pika_joe/widget/netflix/circular_clipper.dart';
import 'package:pika_joe/widget/netflix/content_scroll.dart';
import 'package:pika_joe/widget/netflix/movie_model.dart';
import 'package:provider/provider.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class ObservationScreen2 extends StatefulWidget {

  final Movie movie;

  ObservationScreen2({this.movie});

  @override
  _ObservationScreen2State createState() => _ObservationScreen2State();
}

class _ObservationScreen2State extends State<ObservationScreen2> with TickerProviderStateMixin {

  EdgeInsets _horzPadding = EdgeInsets.symmetric(horizontal: 20.0);
  bool isEditMode = true;

  ScrollController _scrollController;
  AnimationController _colorAnimationController;
  Animation _colorTween;

  bool _scrollListener(ScrollNotification scrollInfo) {
    if (scrollInfo.metrics.axis == Axis.vertical) {
      _colorAnimationController.animateTo(scrollInfo.metrics.pixels / 350);
      return true;
    } else {
      return false;
    }
  }

  @override
  void initState() {
    _scrollController = ScrollController();
    _colorAnimationController = AnimationController(vsync: this, duration: Duration(seconds: 0));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    _colorTween = ColorTween(
        begin: Colors.transparent,
        end: context.watch<MaterialThemesManager>().colorPalette().primary)
        .animate(_colorAnimationController);

    return Scaffold(
      backgroundColor: context.watch<MaterialThemesManager>().getTheme(ThemeGroupType.MOM).scaffoldBackgroundColor,
      body: NotificationListener<ScrollNotification>(
        onNotification: _scrollListener,
        child: Stack(
          children: <Widget>[
            SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  _buildHeaderImage(),
                  _buildHeader(),
                  _buildFields(),
                  smallTransparentDivider,
                  _buildImages(
                      context.watch<MaterialThemesManager>().colorPalette().primary,
                      context.watch<MaterialThemesManager>().colorPalette().primary
                  ),
                  smallTransparentDivider,
                  _buildAudioRecordings(),
                ],
              ),
            ),
            _buildAppbar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppbar() {
    return AnimatedBuilder(
      animation: _colorAnimationController,
      builder: (context, child) =>
        IconTitleIconFakeAppBar(
          shape: StadiumBorder(),
          backgroundColor: _colorTween.value,
          title: 'Make Observation',
          titleType: ThemeGroupType.MOI,
          leftIcon: Icons.arrow_back,
          leftIconType: ThemeGroupType.MOI,
          leftIconClickedCallback: () => Navigator.pop(context),
          rightIcon: Icons.edit,
          rightIconType: ThemeGroupType.MOI,
          rightIconClickedCallback: () => print("TODO - toggle between edit/view mode when not a new observation"),
        )
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
          /*Positioned( //TODO
              bottom: 10.0,
              left: 10.0,
              child: ThemedIconButton(
                Icons.add_location,
                iconSize: IconSize.MEDIUM,
                onPressedCallback: () => print('Allow user to manually select a geo point'),
              )
          ),*/
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
          //TODO - smallTransparentDivider,
          //TODO - ThemedTitle('⭐ ⭐ ⭐ ⭐', type: ThemeGroupType.SOM),//TODO - hide until we allow jo
          smallTransparentDivider,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Column(
                children: <Widget>[
                  ThemedSubTitle("Month", type: ThemeGroupType.MOM),
                  tinyTransparentDivider,
                  ThemedTitle("June", type: ThemeGroupType.MOM, emphasis: Emphasis.HIGH)
                ],
              ),
              Column(
                children: <Widget>[
                  ThemedSubTitle("Day", type: ThemeGroupType.MOM),
                  tinyTransparentDivider,
                  ThemedTitle("6", type: ThemeGroupType.MOM, emphasis: Emphasis.HIGH)
                ],
              ),
              Column(
                children: <Widget>[
                  ThemedSubTitle("Year", type: ThemeGroupType.MOM),
                  tinyTransparentDivider,
                  ThemedTitle("2020", type: ThemeGroupType.MOM, emphasis: Emphasis.HIGH)
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
          _buildSignsChoices(),
          _buildCountChoices(),
          _buildDistanceChoices(),
          _buildSearchDurationChoices(),
          _buildTalusAreaChoices(),
          _buildTemperatureChoices(),
          _buildSkiesChoices(),
          _buildWindChoices(),
          _buildSiteHistory(),
          _buildComments()
        ],
      ),
    );
  }

  List<String> imageUrls = [];
  Widget _buildImages(Color color1, Color color2) {
    return ContentScroll(
      images: imageUrls,
      title: 'Images',
      emptyListMessage: "No Images",
      imageHeight: 200.0,
      imageWidth: 250.0,
      icons:  [
        ThemedIconButton(Icons.image, onPressedCallback: () => _openFileExplorer(true, FileType.image, [])),
        ThemedIconButton(Icons.camera_alt, onPressedCallback: () => {
          _takePictureAndCrop(
            context.read<MaterialThemesManager>().colorPalette().primary,
            context.read<MaterialThemesManager>().colorPalette().primary,
            context.read<MaterialThemesManager>().getTheme(ThemeGroupType.MOP, emphasis: Emphasis.HIGH).iconTheme.color,
            context.read<MaterialThemesManager>().colorPalette().primary,
            context.read<MaterialThemesManager>().colorPalette().primary,
            context.read<MaterialThemesManager>().colorPalette().primary,
            context.read<MaterialThemesManager>().colorPalette().primary,
            context.read<MaterialThemesManager>().colorPalette().primary,
            2,
            6,
            6
          )
        })
      ],
    );
  }

  List<String> audioUrls = [];
  Widget _buildAudioRecordings() {
    return ContentScroll(
      images: audioUrls,
      title: 'Audio Recordings',
      emptyListMessage: "No Audio Recordings",
      imageHeight: 200.0,
      imageWidth: 250.0,
      icons:  [
        ThemedIconButton(Icons.audiotrack, onPressedCallback: () => _openFileExplorer(true, FileType.audio, [])),//TODO - should be allowed to set ['mp3']
        ThemedIconButton(Icons.mic, onPressedCallback: () => {

        })
      ],
    );
  }

  bool _loadingPath = false;
  String _path;
  Map<String, String> _paths;
  String _fileName;
  void _openFileExplorer(bool isMultiPick, FileType pickingType, List<String> allowedExtensions) async {
    setState(() => _loadingPath = true);
    try {
      if (isMultiPick) {
        _path = null;
        _paths = await FilePicker.getMultiFilePath(
          type: pickingType,
          allowedExtensions: allowedExtensions
        );
        _paths.forEach((key, value) {
          imageUrls.add(value);
        });
      } else {
        _paths = null;
        _path = await FilePicker.getFilePath(
          type: pickingType,
          allowedExtensions: allowedExtensions
        );
      }
    } on PlatformException catch (e) {
      print("Unsupported operation" + e.toString());
    }
    if (!mounted) return;
    setState(() {
      _loadingPath = false;
      _fileName = _path != null
          ? _path.split('/').last
          : _paths != null ? _paths.keys.toString() : '...';
    });
  }

  Future<void> _takePictureAndCrop(
    Color toolbarColor,
    Color statusBarColor,
    Color toolbarWidgetColor,
    Color backgroundColor,
    Color activeControlsWidgetColor,
    Color dimmedLayerColor,
    Color cropFrameColor,
    Color cropGridColor,
    int cropFrameStrokeWidth,
    int cropGridRowCount,
    int cropGridColumnCount
  ) async {

    //Take picture with camera ...
    File selected = await ImagePicker.pickImage(source: ImageSource.camera);

    //Crop Image ...
    File cropped = await ImageCropper.cropImage(
      sourcePath: selected.path,
      androidUiSettings: AndroidUiSettings(
        toolbarColor: toolbarColor,
        statusBarColor: statusBarColor,
        toolbarWidgetColor: toolbarWidgetColor,
        backgroundColor: backgroundColor,
        activeControlsWidgetColor: activeControlsWidgetColor,
        dimmedLayerColor: dimmedLayerColor,
        cropFrameColor: cropFrameColor,
        cropGridColor: cropGridColor,
        cropFrameStrokeWidth: 12,
        cropGridRowCount: 10,
        cropGridColumnCount: 6
      ),
    );

    setState(() {
      imageUrls.add(cropped?.path ?? selected.path);
    });
  }

  List<String> signs = [];
  Widget _buildSignsChoices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        smallTransparentDivider,
        ThemedSubTitle("Signs", type: ThemeGroupType.POM),
        ChipsChoice<String>.multiple(
          padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
          value: signs,
          onChanged: (val) => {
            if (isEditMode) {
              setState(() => signs = val)
            }
          },
          choiceItems: C2Choice.listFrom<String, String>(
            source: ["Saw Pika", "Heard Pika Calls", "HayPile: Old", "HayPile: New", "HayPile: Other"],
            value: (i, v) => v,
            label: (i, v) => v,
            tooltip: (i, v) => v,
          ),
        )
      ],
    );
  }

  int countOrdinal;
  Widget _buildCountChoices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        smallTransparentDivider,
        ThemedSubTitle("Pikas Detected", type: ThemeGroupType.POM),
        ChipsChoice<int>.single(
          padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
          value: countOrdinal,
          onChanged: (val) => setState(() => countOrdinal = val),
          choiceItems: C2Choice.listFrom<int, String>(
            source: ["0", "1", "2", "3", "4", "5", ">5", ">10", "Unsure. More than 1"],
            value: (i, v) => i,
            label: (i, v) => v,
            tooltip: (i, v) => v,
          )
        )
      ],
    );
  }

  int distanceOrdinal;
  Widget _buildDistanceChoices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        smallTransparentDivider,
        ThemedSubTitle("Distance to Closest Pika", type: ThemeGroupType.POM),
        ChipsChoice<int>.single(
            padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
            value: distanceOrdinal,
            onChanged: (val) => setState(() => distanceOrdinal = val),
            choiceItems: C2Choice.listFrom<int, String>(
              source: ["<10ft", "10 - 30 ft", "30 - 100 ft", ">100 ft"],
              value: (i, v) => i,
              label: (i, v) => v,
              tooltip: (i, v) => v,
            )
        )
      ],
    );
  }

  int searchDurationOrdinal;
  Widget _buildSearchDurationChoices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        smallTransparentDivider,
        ThemedSubTitle("Search Duration", type: ThemeGroupType.POM),
        ChipsChoice<int>.single(
            padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
            value: searchDurationOrdinal,
            onChanged: (val) => setState(() => searchDurationOrdinal = val),
            choiceItems: C2Choice.listFrom<int, String>(
              source: ["<5 min", "5 - 10 min", "10 - 20 min", "20 - 30 min", ">30 min"],
              value: (i, v) => i,
              label: (i, v) => v,
              tooltip: (i, v) => v,
            )
        )
      ],
    );
  }

  bool showTalusAreaHints = false;
  int talusAreaOrdinal;
  Widget _buildTalusAreaChoices() {
    var hints = ["Smaller than Tennis Court", "Tennis Court to Baseball Infield", "Baseball Infield to Football Field", "Larger than Football Field"];
    var areas = ["<3,000 ft\u00B2", "3,000 - 10,000 ft\u00B2", "10,000 - 50,000 ft\u00B2", "> 1 acre"];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //smallTransparentDivider, //TODO - add this after fixing the ThemedIconButton styling in ThemesManager
        Row(
          children: [
            ThemedSubTitle(showTalusAreaHints ? "Search Area" : "Talus Area", type: ThemeGroupType.POM),
            Expanded(
              flex: 1,
              child: ThemedCaption("Show Hints", type: ThemeGroupType.MOM, textAlign: TextAlign.end),
            ),
            ThemedSwitch(
              value: showTalusAreaHints,
                onChanged: (boolVal) {
                  setState(() => showTalusAreaHints = boolVal);
                }
            )
          ],
        ),
        ChipsChoice<int>.single(
            padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
            value: talusAreaOrdinal,
            onChanged: (val) => setState(() => talusAreaOrdinal = val),
            choiceItems: C2Choice.listFrom<int, String>(
              source: showTalusAreaHints ? hints : areas,
              value: (i, v) => i,
              label: (i, v) => v,
              tooltip: (i, v) => showTalusAreaHints ? areas[i] : hints[i],
            )
        )
      ],
    );
  }

  int temperatureOrdinal;
  Widget _buildTemperatureChoices() {
    var degF = String.fromCharCode($deg) + "F";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        smallTransparentDivider,
        ThemedSubTitle("Temperature", type: ThemeGroupType.POM),
        ChipsChoice<int>.single(
            padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
            value: temperatureOrdinal,
            onChanged: (val) => setState(() => temperatureOrdinal = val),
            choiceItems: C2Choice.listFrom<int, String>(
              source: ["Cold: <45" + degF , "Cool: 45 - 60" + degF, "Warm: 60 - 75" + degF, "Hot: >75" + degF],
              value: (i, v) => i,
              label: (i, v) => v,
              tooltip: (i, v) => v,
            )
        )
      ],
    );
  }

  int skiesOrdinal;
  Widget _buildSkiesChoices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        smallTransparentDivider,
        ThemedSubTitle("Skies", type: ThemeGroupType.POM),
        ChipsChoice<int>.single(
            padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
            value: skiesOrdinal,
            onChanged: (val) => setState(() => skiesOrdinal = val),
            choiceItems: C2Choice.listFrom<int, String>(
              source: ["Clear", "Partly Cloudy", "Overcast", "Rain/Drizzle", "Snow"],
              value: (i, v) => i,
              label: (i, v) => v,
              tooltip: (i, v) => v,
            )
        )
      ],
    );
  }

  int windOrdinal;
  Widget _buildWindChoices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        smallTransparentDivider,
        ThemedSubTitle("Wind", type: ThemeGroupType.POM),
        ChipsChoice<int>.single(
            padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
            value: windOrdinal,
            onChanged: (val) => setState(() => windOrdinal = val),
            choiceItems: C2Choice.listFrom<int, String>(
              source: ["Low: Bends Grasses", "Medium: Bends Branches", "High: Bends Trees"],
              value: (i, v) => i,
              label: (i, v) => v,
              tooltip: (i, v) => v,
            )
        )
      ],
    );
  }

  Widget _buildSiteHistory() {
    return NotificationListener<ScrollNotification>(
      onNotification: (boolVal) { return true; },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          smallTransparentDivider,
          ThemedSubTitle("Site History", type: ThemeGroupType.POM),
          miniTransparentDivider,
          Container(
            height: 120.0,
            child: SingleChildScrollView(
              child: ThemedBody(
                widget.movie.description,
                type: ThemeGroupType.MOM,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildComments() {
    return NotificationListener<ScrollNotification>(
      onNotification: (boolVal) { return true; },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          smallTransparentDivider,
          ThemedSubTitle("Comments", type: ThemeGroupType.POM),
          miniTransparentDivider,
          Container(
            height: 120.0,
            child: SingleChildScrollView(
              child: ThemedBody(
                widget.movie.description,
                type: ThemeGroupType.MOM,
              ),
            ),
          )
        ],
      ),
    );
  }
}