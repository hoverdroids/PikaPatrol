import 'dart:async';
import 'dart:io';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:charcode/charcode.dart';
import 'package:chips_choice/chips_choice.dart';
import 'package:data_connection_checker/data_connection_checker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';  //for date format
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/appbars/icon_title_icon_fake_appbar.dart';
import 'package:material_themes_widgets/clippaths/clip_paths.dart';
import 'package:material_themes_widgets/defaults/dimens.dart';
import 'package:material_themes_widgets/forms/form_fields.dart';
import 'package:material_themes_widgets/forms/loading.dart';
import 'package:material_themes_widgets/fundamental/buttons_media.dart';
import 'package:material_themes_widgets/fundamental/icons.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';
import 'package:material_themes_widgets/fundamental/toggles.dart';
import 'package:material_themes_widgets/utils/validators.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pika_patrol/model/app_user.dart';
import 'package:pika_patrol/model/local_observation.dart';
import 'package:pika_patrol/model/observation.dart';
import 'package:pika_patrol/screens/training_screens_pager.dart';
import 'package:pika_patrol/services/firebase_database_service.dart';
import 'package:pika_patrol/widgets/audio_content_scroll.dart';
import 'package:pika_patrol/widgets/audio_recorder_dialog.dart';
import 'package:pika_patrol/widgets/circular_clipper.dart';
import 'package:pika_patrol/widgets/content_scroll.dart';
import 'package:pika_patrol/utils/geo_utils.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class ObservationScreen extends StatefulWidget {

  final Observation observation;
  bool isEditMode;

  ObservationScreen(this.observation) {
    //When opening after a user clicks a card, show a previously created observation in viewing mode.
    //When opening after a user clicks the add observation button, show a new observation in edit mode.
    isEditMode = observation.uid == null ? true : false;
  }

  @override
  _ObservationScreenState createState() => _ObservationScreenState();
}

class _ObservationScreenState extends State<ObservationScreen> with TickerProviderStateMixin {

  final _formKey = GlobalKey<FormState>();

  EdgeInsets _horzPadding = EdgeInsets.symmetric(horizontal: 20.0);

  ScrollController _scrollController;
  AnimationController _colorAnimationController;
  Animation _colorTween;

  bool needsUpdated = false;

  bool justKeepToggling = true;

  var assetsAudioPlayer = AssetsAudioPlayer();
  PlayerState _playerState = PlayerState.stop;

  bool _isUploading = false;

  bool _hideGeoFields = false;

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

    final user = Provider.of<AppUser>(context);

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
              child: Form(
                key: _formKey,
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
            ),
            _buildAppbar(user),
            if(_isUploading) ... [
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.white.withOpacity(0.70),
                child: Loading(),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildAppbar(AppUser user) {
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
              showRightIcon: widget.isEditMode || widget.observation.dbId != null || (user != null && widget.observation.observerUid == user.uid),//Widget will only be in edit mode if new observation
              rightIconType: ThemeGroupType.MOI,
              rightIconClickedCallback: () async {
                if(!widget.isEditMode) {
                  setState(() {
                    widget.isEditMode = true;
                  });
                } else {
                  if (_formKey.currentState.validate()) {
                    _formKey.currentState.save();

                    var hasConnection = await DataConnectionChecker().hasConnection;
                    saveLocalObservation();
                    if(!hasConnection) {
                      Fluttertoast.showToast(
                          msg: "No connection found.\nObservation saved locally.",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.CENTER,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.red,//TODO - need to use Toast with context to link to the primary color
                          textColor: Colors.white,
                          fontSize: 16.0
                      );
                    } else if (user != null) {
                      setState((){
                        _isUploading = true;
                      });

                      //If the observation was made when the user was not logged in, then edited after loggin in, the user
                      //id can be null. So update it now. This allows local observations to be uploaded when online.
                      widget.observation.observerUid = user.uid;

                      //Share with others
                      await saveObservation(user);
                    } else {
                      Fluttertoast.showToast(
                          msg: "You must login to upload an observation.\nObservation saved locally.",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.CENTER,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.red,//TODO - need to use Toast with context to link to the primary color
                          textColor: Colors.white,
                          fontSize: 16.0
                      );
                    }
                  }
                }
              },
            )
    );
  }

  Future saveObservation(AppUser user) async {

    var databaseService = FirebaseDatabaseService(uid: user != null ? user.uid : null);
    widget.observation.imageUrls = await databaseService.uploadFiles(widget.observation.imageUrls, true);
    print("ImageUrls: ${widget.observation.imageUrls.toString()}");

    widget.observation.audioUrls = await databaseService.uploadFiles(widget.observation.audioUrls, false);
    print("AudioUrls: ${widget.observation.audioUrls.toString()}");

    dynamic result = await FirebaseDatabaseService(uid: user != null ? user.uid : null).updateObservation(widget.observation);

    setState(() {
      _isUploading = false;
      widget.isEditMode = false;
    });
  }

  void saveLocalObservation() {
    var box = Hive.box<LocalObservation>('observations');

    //The observation screen can be opened from an online observation, which means that the dbId can be null.
    //So, make sure we associate the dbId if there's a local copy so that we don't duplicate local copies
    Map<dynamic, dynamic> raw = box.toMap();
    List list = raw.values.toList();
    var localObservations = <Observation>[];
    list.forEach((element) {
      LocalObservation localObservation = element;
      if(localObservation.uid == widget.observation.uid) {
        widget.observation.dbId = localObservation.key;
      }
    });

    var localObservation = LocalObservation(
        uid: widget.observation.uid ?? "",
        observerUid: widget.observation.observerUid ?? "",
        altitude: widget.observation.altitude ?? 0.0,
        longitude: widget.observation.longitude ?? 0.0,
        latitude: widget.observation.latitude ?? 0.0,
        name: widget.observation.name ?? "",
        location: widget.observation.location ?? "",
        date: widget.observation.date?.toString() ?? "",
        signs: widget.observation.signs ?? <String>[],
        pikasDetected: widget.observation.pikasDetected ?? "",
        distanceToClosestPika: widget.observation.distanceToClosestPika ?? "",
        searchDuration: widget.observation.searchDuration ?? "",
        talusArea: widget.observation.talusArea ?? "",
        temperature: widget.observation.temperature ?? "",
        skies: widget.observation.skies ?? "",
        wind: widget.observation.wind ?? "",
        otherAnimalsPresent: widget.observation.otherAnimalsPresent ?? <String>[],
        siteHistory: widget.observation.siteHistory ?? "",
        comments: widget.observation.comments ?? "",
        imageUrls: widget.observation.imageUrls ?? <String>[],
        audioUrls: widget.observation.audioUrls ?? <String>[]
    );

    if(widget.observation.dbId == null) {
      box.add(localObservation);

      //If the user remains on the observation page, they can edit/save again. In that case, they need
      //to use the same database ID instead of adding a new entry each time
      widget.observation.dbId = localObservation.key;
    } else {
      box.put(widget.observation.dbId, localObservation);
    }

    setState(() {
      _isUploading = false;
      widget.isEditMode = false;
    });
  }

  Box box;
  Future openBox() async {
    var dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
    box = await Hive.openBox('data');
    return;
  }

  getAllData() async {
    await openBox();
  }

  Widget _buildHeaderImage() {
    return GestureDetector(
      onTap: () => widget.isEditMode ? _openFileExplorer(true, FileType.image, [], true) : print(""),
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
                  child: widget.isEditMode ? _buildRecordButton() : _buildPlayButton(),
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
              left: 10.0,
              child: ThemedIconButton(
                  Icons.my_location,
                  iconSize: IconSize.MEDIUM,
                  onPressedCallback: () => { _getCurrentPositionAndUpdateUi() }
              ),
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
                                        MaterialPageRoute(builder: (BuildContext context) => ObservationScreen(widget.observation))
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

  Widget _buildPlayButton() {
    return ThemedPlayButton(
      isPlaying: _playerState == PlayerState.play,
      pauseIcon: Icon(
          Icons.pause,
          color: context.watch<MaterialThemesManager>().colorPalette().primary,
          size: 48),
      playIcon: Icon(Icons.play_arrow,
          color: context.watch<MaterialThemesManager>().colorPalette().primary,
          size: 48),
      onPressed: () => {
        widget.observation.audioUrls.isNotEmpty
            ? _playAudio(widget.observation.audioUrls[0])
            : Fluttertoast.showToast(
            msg: "No recordings to play",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.teal,//TODO - need to use Toast with context to link to the primary color
            textColor: Colors.white,
            fontSize: 16.0
        )
      },
    );
  }

  Widget _buildRecordButton() {
    return ThemedPlayButton(
      playIcon: Icon(Icons.mic,
          color: context.watch<MaterialThemesManager>().colorPalette().primary,
          size: 48),
      onPressed: () => { _openAudioRecorder() },
    );
  }

  void _playAudio(String audioUrl) {
    if (_playerState == PlayerState.stop) {
      setState(() {
        _playerState = PlayerState.play;
      });
      assetsAudioPlayer = AssetsAudioPlayer();//apparently the audio player needs to be re-instantiated once stopped
      assetsAudioPlayer.playlistAudioFinished.listen((Playing playing){
        setState(() {
          _playerState = PlayerState.stop;
        });
      });
      assetsAudioPlayer.open(audioUrl.contains("http") ? Audio.network(audioUrl) : Audio.file(audioUrl));
      assetsAudioPlayer.play();

    } else if (_playerState == PlayerState.play) {
      setState(() {
        _playerState = PlayerState.pause;
      });
      assetsAudioPlayer.pause();

    } else {
      setState(() {
        _playerState = PlayerState.play;
      });
      assetsAudioPlayer.play();
    }
  }

  Widget _buildImage() {
    if(widget.observation.imageUrls.isEmpty) {
      return Image(
        height: 300.0,
        width: double.infinity,
        fit: BoxFit.cover,
        image: AssetImage("assets/images/add_image.png"),
      );
    } else if(widget.observation.imageUrls[0].contains("https://")) {
      return Image.network(
        widget.observation.imageUrls[0],
        height: 300.0,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else {
      return Image.file(
        File(widget.observation.imageUrls[0]),
        height: 300.0,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }
  }

  Widget _buildLatLonAltitude() {
    double lat = widget.observation.latitude;
    double lon = widget.observation.longitude;
    double alt = widget.observation.altitude;

    String latitude = lat == null ? "" : widget.observation.latitude.toStringAsFixed(2);
    String longitude = lon == null ? "" : widget.observation.longitude.toStringAsFixed(2);
    String altitude = alt == null ? "" : widget.observation.altitude.toStringAsFixed(2);

    Fluttertoast.showToast(
        msg: "Build lat:$latitude lon:$longitude alt:$altitude",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,//TODO - need to use Toast with context to link to the primary color
        textColor: Colors.white,
        fontSize: 16.0
    );
    return Row(
      children: <Widget>[
        Flexible(
          flex: 1,
          child: Container(
            child: Align(
              alignment: Alignment.centerRight,
              child:Column(
                children: <Widget>[
                  ThemedSubTitle("Latitude", type: ThemeGroupType.POM),
                  tinyTransparentDivider,
                  if (_hideGeoFields) ... [
                    //A hack state because geo fields not updating from self location button
                    //Don't add another ThemedEditableLabelValue here; it'll just create the same issue of not updating
                  ]
                  else if (widget.isEditMode) ...[
                    ThemedEditableLabelValue(
                      showLabel: false,
                      text: latitude,
                      textType: ThemeGroupType.POM,
                      hintText: "0.0",
                      onStringChangedCallback: (value) => { widget.observation.latitude = double.parse(value) },
                      validator: (value) => isValidGeo(value, "Latitude"),
                    ),
                  ] else ... [
                    ThemedTitle(latitude, type: ThemeGroupType.MOM, emphasis: Emphasis.HIGH),
                  ]
                ],
              ),
            ),
          ),
        ),
        Flexible(
          flex: 1,
          child: Container(
              child: Align(
                alignment: Alignment.center,
                child: Column(
                  children: <Widget>[
                    ThemedSubTitle("Longitude", type: ThemeGroupType.POM),
                    tinyTransparentDivider,
                    if (_hideGeoFields) ... [
                      //A hack state because geo fields not updating from self location button
                      //Don't add another ThemedEditableLabelValue here; it'll just create the same issue of not updating
                    ] else if (widget.isEditMode) ...[
                      ThemedEditableLabelValue(
                        showLabel: false,
                        text: longitude,
                        textType: ThemeGroupType.POM,
                        hintText: "0.0",
                        onStringChangedCallback: (value) => { widget.observation.longitude = double.parse(value) },
                        validator: (value) => isValidGeo(value, "Longitude"),
                      ),
                    ] else ... [
                      ThemedTitle(longitude, type: ThemeGroupType.MOM, emphasis: Emphasis.HIGH),
                    ]
                  ],
                ),
              )
          ),
        ),
        Flexible(
          flex: 1,
          child: Container(
            alignment: Alignment.centerLeft,
            child:Column(
              children: <Widget>[
                ThemedSubTitle("Altitude", type: ThemeGroupType.POM),
                tinyTransparentDivider,
                if (_hideGeoFields) ... [
                  //A hack state because geo fields not updating from self location button
                  //Don't add another ThemedEditableLabelValue here; it'll just create the same issue of not updating
                ] else if (widget.isEditMode) ...[
                  ThemedEditableLabelValue(
                    showLabel: false,
                    text: altitude,
                    textType: ThemeGroupType.POM,
                    hintText: "0.0",
                    onStringChangedCallback: (value) => { widget.observation.altitude = double.parse(value) },
                    validator: (value) => isValidGeo(value, "Altitude"),
                  )
                ] else ...[
                  ThemedTitle(altitude, type: ThemeGroupType.MOM, emphasis: Emphasis.HIGH),
                ]
              ],
            ),
          )
        )
      ],
    );
  }

  _getCurrentPositionAndUpdateUi() async {
    Fluttertoast.showToast(
        msg: "Fetching location ...",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,//TODO - need to use Toast with context to link to the primary color
        textColor: Colors.white,
        fontSize: 16.0
    );

    await checkPermissionsAndGetCurrentPosition()
        .then((Position position) {
          String lat = position.latitude.toStringAsFixed(2);
          String lon = position.longitude.toStringAsFixed(2);
          String alt = position.altitude.toStringAsFixed(2);
            Fluttertoast.showToast(
                msg: "Location:\n$lat $lon $alt",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.red,//TODO - need to use Toast with context to link to the primary color
                textColor: Colors.white,
                fontSize: 16.0
            );
          setState(() {
            widget.observation.latitude = position.latitude;
            widget.observation.longitude = position.longitude;
            widget.observation.altitude = position.altitude;

            _hideGeoFields = true;
            resetHideGeoFields();
          });
        })
        .catchError((e) {
          Fluttertoast.showToast(
              msg: "$e",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.red,//TODO - need to use Toast with context to link to the primary color
              textColor: Colors.white,
              fontSize: 16.0
          );
        });
  }

  resetHideGeoFields() async {
    await Future.delayed(const Duration(milliseconds: 10), () {
      setState(() {
        _hideGeoFields = false;
      });
    });
  }

  Widget _buildHeader() {
    return Padding(
      padding: _horzPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          _buildLatLonAltitude(),
          smallTransparentDivider,
          if(widget.isEditMode) ... [
            ThemedEditableLabelValue(
              showLabel: false,
              text: widget.observation.name.toUpperCase(),
              textType: ThemeGroupType.POM,
              hintText: "Observation Name",
              onStringChangedCallback: (value) => { widget.observation.name = value.toUpperCase() },
              validator: (value) => nonEmptyValidator(value, "Observation Name"),
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
              onStringChangedCallback: (value) => { widget.observation.location = value },
              validator: (value) => nonEmptyValidator(value, "Site Location Name"),
            )
          ] else ... [
            ThemedSubTitle(widget.observation.location, type: ThemeGroupType.MOM),
          ],
          //TODO - smallTransparentDivider,
          //TODO - ThemedTitle('⭐ ⭐ ⭐ ⭐', type: ThemeGroupType.SOM),//TODO - hide until we allow jo
          smallTransparentDivider,
          Row(
            children: <Widget>[
              Flexible(
                flex: 1,
                child: Container(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child:Column(
                      children: <Widget>[
                        ThemedSubTitle("Month", type: ThemeGroupType.MOM),
                        tinyTransparentDivider,
                        ThemedTitle(new DateFormat.yMMMMd('en_US').format(widget.observation.date).split(" ")[0], type: ThemeGroupType.MOM, emphasis: Emphasis.HIGH)
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                  child: Align(
                    alignment: Alignment.center,
                    child: Column(
                      children: <Widget>[
                        ThemedSubTitle("Day", type: ThemeGroupType.MOM),
                        tinyTransparentDivider,
                        ThemedTitle(widget.observation.date.day.toString(), type: ThemeGroupType.MOM, emphasis: Emphasis.HIGH)
                      ],
                    ),
                  )
              ),
              Flexible(
                  flex: 1,
                  child: Container(
                    alignment: Alignment.centerLeft,
                    child:Column(
                      children: <Widget>[
                        ThemedSubTitle("Year", type: ThemeGroupType.MOM),
                        tinyTransparentDivider,
                        ThemedTitle(widget.observation.date.year.toString(), type: ThemeGroupType.MOM, emphasis: Emphasis.HIGH)
                      ],
                    ),
                  )
              )
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
      ThemedIconButton(Icons.image, onPressedCallback: () => _openFileExplorer(true, FileType.image, [], true)),
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
      images: widget.observation.imageUrls,
      title: 'Images',
      emptyListMessage: "No Images",
      imageHeight: 200.0,
      imageWidth: 250.0,
      icons: icons,
    );
  }

  Widget _buildAudioRecordings() {

    var icons = !widget.isEditMode ? <Widget>[] : [
      ThemedIconButton(Icons.audiotrack, onPressedCallback: () => _openFileExplorer(true, FileType.audio, [], false)),//TODO - should be allowed to set ['mp3']
      ThemedIconButton(Icons.mic, onPressedCallback: () => { _openAudioRecorder() })
    ];

    return AudioContentScroll(
      urls: widget.observation.audioUrls,
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
              print("AudioUrl...");
              return AudioRecorderDialog();
            }
        ).then((value) => {
          setState((){
            if (value != null && (value as String).isNotEmpty) {
              print("AudioUrls value: " + value);
              widget.observation.audioUrls.add(value);
              justKeepToggling = !justKeepToggling;
              print("AudioUrls: " + widget.observation.audioUrls.toString());
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
  void _openFileExplorer(bool isMultiPick, FileType pickingType, List<String> allowedExtensions, bool addImages) async {
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
            if (addImages) {
              widget.observation.imageUrls.add(value);
            } else {
              widget.observation.audioUrls.add(value);
            }
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
          widget.observation.imageUrls.add(_path);
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
    File cropped = await ImageCropper().cropImage(
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
      widget.observation.imageUrls.add(cropped?.path ?? selected.path);
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