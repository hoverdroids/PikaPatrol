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
import 'package:material_themes_widgets/forms/form_fields.dart';
import 'package:material_themes_widgets/fundamental/buttons_media.dart';
import 'package:material_themes_widgets/fundamental/icons.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';
import 'package:material_themes_widgets/fundamental/toggles.dart';
import 'package:pika_joe/model/observation2.dart';
import 'package:pika_joe/screens/training/training_screens_pager.dart';
import 'package:pika_joe/services/firebase_database_service.dart';
import 'package:pika_joe/widget/netflix/audio_content_scroll.dart';
import 'package:pika_joe/widget/netflix/circular_clipper.dart';
import 'package:pika_joe/widget/netflix/content_scroll.dart';
import 'package:pika_joe/widget/netflix/movie_model.dart';
import 'package:provider/provider.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../audio_recorder_dialog.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:assets_audio_player/assets_audio_player.dart';

import 'package:pika_joe/model/user.dart';
import 'package:intl/intl.dart';  //for date format
import 'package:intl/date_symbol_data_local.dart';  //for date locale

class ObservationScreen2 extends StatefulWidget {

  final Observation2 observation;
  bool isEditMode;

  ObservationScreen2(this.observation) {
    //When opening after a user clicks a card, show a previously created observation in viewing mode.
    //When opening after a user clicks the add observation button, show a new observation in edit mode.
    isEditMode = observation.uid == null ? true : false;
  }

  @override
  _ObservationScreen2State createState() => _ObservationScreen2State();
}

class _ObservationScreen2State extends State<ObservationScreen2> with TickerProviderStateMixin {

  EdgeInsets _horzPadding = EdgeInsets.symmetric(horizontal: 20.0);

  ScrollController _scrollController;
  AnimationController _colorAnimationController;
  Animation _colorTween;

  bool needsUpdated = false;

  List<String> imageUrls = [];
  List<String> audioUrls = [];

  final assetsAudioPlayer = AssetsAudioPlayer();
  bool _isAudioLoaded = false;
  bool _isAudioPlaying = false;
  String _currentlyPlayingUrl;

  bool _loading = false;

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

    final user = Provider.of<User>(context);

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
            _buildAppbar(user),
          ],
        ),
      ),
    );
  }

  Widget _buildAppbar(User user) {
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
          rightIcon: widget.isEditMode ? Icons.save : Icons.edit,
          rightIconType: ThemeGroupType.MOI,
          rightIconClickedCallback: () async {
            //If the observation ID is null, then it's a new observation and edit mode is always the state.
            //This means the save button should be showing

            //If the observation ID is not null, we can be in edit or view mode.
            setState((){
              _loading = true;
              widget.isEditMode = !widget.isEditMode;
            });

            dynamic result = await FirebaseDatabaseService(uid: user.uid).updateObservation(widget.observation);
            print("Your id is" + widget.observation.uid);
          },
        )
    );
  }

  Widget _buildHeaderImage() {
    return GestureDetector(
      onTap: () => _openFileExplorer(true, FileType.image, []),
      child: Container(
        height: 330,
        child: Stack(
          children: <Widget>[
            Container(
              child: Hero(
                tag: "observationCoverImage",
                child: ClipShadowPath(
                  clipper: SimpleClipPath(
                      type: ClipPathType.ROUNDED_DOWN,
                      bottomLeftPercentOfHeight: 80,
                      bottomRightPercentOfHeight: 80
                  ),
                  shadow: Shadow(blurRadius: 20.0),
                  child: _buildImage(),
                ),
              ),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: RawMaterialButton(
                  //padding: EdgeInsets.all(0.0),
                  //elevation: 12.0,
                  onPressed: () => print('Play Video'),
                  shape: CircleBorder(),
                  fillColor: Colors.white,
                  child:ThemedPlayButton(
                    pauseIcon: Icon(
                        Icons.pause,
                        color: context.watch<MaterialThemesManager>().colorPalette().primary,
                        size: 48),
                    playIcon: Icon(Icons.mic,
                        color: context.watch<MaterialThemesManager>().colorPalette().primary,
                        size: 48),
                    onPressed: () => {
                      audioUrls.isNotEmpty
                          ? _playAudio(audioUrls[0])
                          : _openAudioRecorder()
                    },
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
                                        MaterialPageRoute(builder: (BuildContext context) => ObservationScreen2(widget.observation))
                                    )
                            )
                        )
                    )
                  }
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _playAudio(String audioUrl) {
    if (!_isAudioLoaded) {
      _isAudioPlaying = true;
      _isAudioLoaded = true;
      assetsAudioPlayer.open(Audio.file(audioUrl));
      assetsAudioPlayer.play();
      
    } else if (_isAudioPlaying) {
      _isAudioPlaying = false;
      assetsAudioPlayer.pause();
      
    } else {
      _isAudioPlaying = true;
      assetsAudioPlayer.play();
    }
  }

  Widget _buildImage() {
    return imageUrls.isNotEmpty
      ? Image.file(
        File(imageUrls[0]),
          height: 300.0,
          width: double.infinity,
          fit: BoxFit.cover,
        )
      : Image(
          height: 300.0,
          width: double.infinity,
          fit: BoxFit.cover,
          image: AssetImage("assets/images/add_image.png"),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: _horzPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          smallTransparentDivider,
          if(widget.isEditMode) ... [
            ThemedEditableLabelValue(
              showLabel: false,
              text: widget.observation.name.toUpperCase(),
              textType: ThemeGroupType.POM,
              hintText: "Observation Name",
              onStringChangedCallback: (value) => { widget.observation.name = value.toUpperCase() },
              //validator: validator
            )
          ] else ... [
            ThemedH5(widget.observation.name.toUpperCase(), type: ThemeGroupType.POM, emphasis: Emphasis.HIGH),
          ],
          miniTransparentDivider,
          if(widget.isEditMode) ... [
            ThemedEditableLabelValue(
              showLabel: false,
              text: widget.observation.location,
              textType: ThemeGroupType.POM,
              hintText: "Site Location Name",
              //hintTextType: hintTextType,
              //hintTextEmphasis: hintTextEmphasis,
              //backgroundType: textFieldBackgroundType,
              onStringChangedCallback: (value) => { widget.observation.location = value },
              //validator: validator
            )
          ] else ... [
            ThemedSubTitle(widget.observation.location, type: ThemeGroupType.MOM),
          ],
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
                  ThemedTitle(new DateFormat.yMMMMd('en_US').format(widget.observation.date).split(" ")[0], type: ThemeGroupType.MOM, emphasis: Emphasis.HIGH)
                ],
              ),
              Column(
                children: <Widget>[
                  ThemedSubTitle("Day", type: ThemeGroupType.MOM),
                  tinyTransparentDivider,
                  ThemedTitle(widget.observation.date.day.toString(), type: ThemeGroupType.MOM, emphasis: Emphasis.HIGH)
                ],
              ),
              Column(
                children: <Widget>[
                  ThemedSubTitle("Year", type: ThemeGroupType.MOM),
                  tinyTransparentDivider,
                  ThemedTitle(widget.observation.date.year.toString(), type: ThemeGroupType.MOM, emphasis: Emphasis.HIGH)
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
          _buildOtherAnimalsPresent(),
          _buildSiteHistory(),
          _buildComments()
        ],
      ),
    );
  }

  Widget _buildImages(Color color1, Color color2) {

    var icons = !widget.isEditMode ? <Widget>[] : [
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
    ];

    return ContentScroll(
      images: imageUrls,
      title: 'Images',
      emptyListMessage: "No Images",
      imageHeight: 200.0,
      imageWidth: 250.0,
      icons: icons,
    );
  }

  Widget _buildAudioRecordings() {

    var icons = !widget.isEditMode ? <Widget>[] : [
      ThemedIconButton(Icons.audiotrack, onPressedCallback: () => _openFileExplorer(true, FileType.audio, [])),//TODO - should be allowed to set ['mp3']
      ThemedIconButton(Icons.mic, onPressedCallback: () => { _openAudioRecorder() })
    ];

    return AudioContentScroll(
      urls: audioUrls,
      title: 'Audio Recordings',
      emptyListMessage: "No Audio Recordings",
      imageHeight: 200.0,
      imageWidth: 250.0,
      icons: icons,
    );
  }

  void _openAudioRecorder() async {
    try {
      //Always check for permission. It will ask for permission if not already granted
      if (await FlutterAudioRecorder.hasPermissions) {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AudioRecorderDialog();
            }
        ).then((value) => {
          setState((){
            if (value != null && (value as String).isNotEmpty) {
              audioUrls.add(value);
            }
          })
        });
      } else {
        Fluttertoast.showToast(
            msg: "Could not open recorder.\nYou must accept audio permissions.",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.teal,//TODO - need to use Toast with context to link to the primary color
            textColor: Colors.white,
            fontSize: 16.0
        );
      }
    } catch (e) {
      print(e);
    }
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
        //if (_paths.isNotEmpty) {

          setState(() {
            _paths.forEach((key, value) {
              imageUrls.add(value);
            });
            needsUpdated = true;
          });

        //}
      } else {
        _paths = null;
        _path = await FilePicker.getFilePath(
          type: pickingType,
          allowedExtensions: allowedExtensions
        );
        //if(_path.isNotEmpty) {

          setState(() {
            imageUrls.add(_path);
            needsUpdated = true;
          });
        //}
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

  Widget _buildSignsChoices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        smallTransparentDivider,
        ThemedSubTitle("Signs", type: ThemeGroupType.POM),
        ChipsChoice<String>.multiple(
          padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
          value: widget.observation.signs,
          onChanged: (val) => {
            if (widget.isEditMode) {
              setState(() => widget.observation.signs = val)
            }
          },
          choiceItems: C2Choice.listFrom<String, String>(
            source: ["Saw Pika", "Heard Pika Calls", "HayPile: Old", "HayPile: New", "HayPile: Other", "Scat: Old", "Scat: New", "Scat: Other"],
            value: (i, v) => v,
            label: (i, v) => v,
            tooltip: (i, v) => v,
          ),
        )
      ],
    );
  }

  Widget _buildCountChoices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        smallTransparentDivider,
        ThemedSubTitle("Pikas Detected", type: ThemeGroupType.POM),
        ChipsChoice<String>.single(
          padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
          value: widget.observation.pikasDetected,
          onChanged: (val) => {
            if (widget.isEditMode) {
              setState(() => widget.observation.pikasDetected = val)
            }
          },
          choiceItems: C2Choice.listFrom<String, String>(
            source: ["0", "1", "2", "3", "4", "5", ">5", ">10", "Unsure. More than 1"],
            value: (i, v) => v,
            label: (i, v) => v,
            tooltip: (i, v) => v,
          )
        )
      ],
    );
  }

  Widget _buildDistanceChoices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        smallTransparentDivider,
        ThemedSubTitle("Distance to Closest Pika", type: ThemeGroupType.POM),
        ChipsChoice<String>.single(
            padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
            value: widget.observation.distanceToClosestPika,
            onChanged: (val) => {
              if (widget.isEditMode) {
                setState(() => widget.observation.distanceToClosestPika = val)
              }
            },
            choiceItems: C2Choice.listFrom<String, String>(
              source: ["<10ft", "10 - 30 ft", "30 - 100 ft", ">100 ft"],
              value: (i, v) => v,
              label: (i, v) => v,
              tooltip: (i, v) => v,
            )
        )
      ],
    );
  }

  Widget _buildSearchDurationChoices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        smallTransparentDivider,
        ThemedSubTitle("Search Duration", type: ThemeGroupType.POM),
        ChipsChoice<String>.single(
            padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
            value: widget.observation.searchDuration,
            onChanged: (val) => {
              if (widget.isEditMode) {
                setState(() => widget.observation.searchDuration = val)
              }
            },
            choiceItems: C2Choice.listFrom<String, String>(
              source: ["<5 min", "5 - 10 min", "10 - 20 min", "20 - 30 min", ">30 min"],
              value: (i, v) => v,
              label: (i, v) => v,
              tooltip: (i, v) => v,
            )
        )
      ],
    );
  }

  bool showTalusAreaHints = false;
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
        ChipsChoice<String>.single(
            padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
            value: widget.observation.talusArea,
            onChanged: (val) => {
              if (widget.isEditMode) {
                setState(() => widget.observation.talusArea = val)
              }
            },
            choiceItems: C2Choice.listFrom<String, String>(
              source: showTalusAreaHints ? hints : areas,
              value: (i, v) => v,
              label: (i, v) => v,
              tooltip: (i, v) => showTalusAreaHints ? areas[i] : hints[i],
            )
        )
      ],
    );
  }

  Widget _buildTemperatureChoices() {
    var degF = String.fromCharCode($deg) + "F";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        smallTransparentDivider,
        ThemedSubTitle("Temperature", type: ThemeGroupType.POM),
        ChipsChoice<String>.single(
            padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
            value: widget.observation.temperature,
            onChanged: (val) => {
              if (widget.isEditMode) {
                setState(() => widget.observation.temperature = val)
              }
            },
            choiceItems: C2Choice.listFrom<String, String>(
              source: ["Cold: <45" + degF , "Cool: 45 - 60" + degF, "Warm: 60 - 75" + degF, "Hot: >75" + degF],
              value: (i, v) => v,
              label: (i, v) => v,
              tooltip: (i, v) => v,
            )
        )
      ],
    );
  }

  Widget _buildSkiesChoices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        smallTransparentDivider,
        ThemedSubTitle("Skies", type: ThemeGroupType.POM),
        ChipsChoice<String>.single(
            padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
            value: widget.observation.skies,
            onChanged: (val) => {
              if (widget.isEditMode) {
                setState(() => widget.observation.skies = val)
              }
            },
            choiceItems: C2Choice.listFrom<String, String>(
              source: ["Clear", "Partly Cloudy", "Overcast", "Rain/Drizzle", "Snow"],
              value: (i, v) => v,
              label: (i, v) => v,
              tooltip: (i, v) => v,
            )
        )
      ],
    );
  }

  Widget _buildWindChoices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        smallTransparentDivider,
        ThemedSubTitle("Wind", type: ThemeGroupType.POM),
        ChipsChoice<String>.single(
            padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
            value: widget.observation.wind,
            onChanged: (val) => {
              if (widget.isEditMode) {
                setState(() => widget.observation.wind = val)
              }
            },
            choiceItems: C2Choice.listFrom<String, String>(
              source: ["Low: Bends Grasses", "Medium: Bends Branches", "High: Bends Trees"],
              value: (i, v) => v,
              label: (i, v) => v,
              tooltip: (i, v) => v,
            )
        )
      ],
    );
  }

  Widget _buildOtherAnimalsPresent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        smallTransparentDivider,
        ThemedSubTitle("Other Animals Present", type: ThemeGroupType.POM),
        ChipsChoice<String>.multiple(
          padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
          value: widget.observation.otherAnimalsPresent,
          onChanged: (val) => {
            if (widget.isEditMode) {
              setState(() => widget.observation.otherAnimalsPresent = val)
            }
          },
          choiceItems: C2Choice.listFrom<String, String>(
            source: ["Marmots", "Weasels", "Woodrats", "Mountain Goats", "Cattle", "Ptarmigans", "Raptors", "Brown Capped Rosy Finch", "Bats", "Other"],
            value: (i, v) => v,
            label: (i, v) => v,
            tooltip: (i, v) => v,
          ),
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
          if(widget.isEditMode) ... [
            ThemedEditableLabelValue(
              showLabel: false,
              text: widget.observation.siteHistory,
              textType: ThemeGroupType.POM,
              hintText: "Note any history you've had with this site",
              //hintTextType: hintTextType,
              //hintTextEmphasis: hintTextEmphasis,
              //backgroundType: textFieldBackgroundType,
              onStringChangedCallback: (value) => { widget.observation.siteHistory = value },
              //validator: validator
            )
          ] else ... [
            Container(
              height: 120.0,
              child: SingleChildScrollView(
                child: ThemedBody(
                  widget.observation.siteHistory,
                  type: ThemeGroupType.MOM,
                ),
              ),
            )
          ]
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
          if(widget.isEditMode) ... [
            ThemedEditableLabelValue(
              showLabel: false,
              text: widget.observation.comments,
              textType: ThemeGroupType.POM,
              hintText: "Any additional observations",
              //hintTextType: hintTextType,
              //hintTextEmphasis: hintTextEmphasis,
              //backgroundType: textFieldBackgroundType,
              onStringChangedCallback: (value) => { widget.observation.comments = value },
              //validator: validator
            )
          ] else ... [
            Container(
              height: 120.0,
              child: SingleChildScrollView(
                child: ThemedBody(
                  widget.observation.comments,
                  type: ThemeGroupType.MOM,
                ),
              ),
            )
          ]
        ],
      ),
    );
  }
}