// ignore_for_file: depend_on_referenced_packages
import 'dart:async';
import 'dart:io';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:charcode/charcode.dart';
import 'package:chips_choice/chips_choice.dart';
import 'package:data_connection_checker_nulls/data_connection_checker_nulls.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_themes_widgets/appbars/icon_title_icon_fake_appbar.dart';
import 'package:material_themes_widgets/clippaths/clip_paths.dart';
import 'package:material_themes_widgets/defaults/dimens.dart';
import 'package:material_themes_widgets/forms/form_fields.dart';
import 'package:material_themes_widgets/forms/loading.dart';
import 'package:material_themes_widgets/fundamental/buttons_media.dart';
import 'package:material_themes_widgets/fundamental/icons.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';
import 'package:material_themes_widgets/fundamental/toggles.dart';
import 'package:material_themes_widgets/utils/ui_utils.dart';
import 'package:material_themes_widgets/utils/validators.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:pika_patrol/model/app_user.dart';
import 'package:pika_patrol/model/local_observation.dart';
import 'package:pika_patrol/model/observation.dart';
import 'package:pika_patrol/screens/training_screens_pager.dart';
import 'package:pika_patrol/services/firebase_database_service.dart';
import 'package:pika_patrol/widgets/audio_content_scroll.dart';
import 'package:pika_patrol/widgets/circular_clipper.dart';
import 'package:pika_patrol/widgets/content_scroll.dart';
import 'package:pika_patrol/utils/geo_utils.dart';
import 'package:pika_patrol/widgets/audio_recorder_dialog.dart';
import 'package:intl/intl.dart';  //for date format
// import 'package:flutter_audio_recorder3/flutter_audio_recorder3.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as developer;

import '../utils/observation_utils.dart';

// ignore: must_be_immutable
class ObservationScreen extends StatefulWidget {

  final Observation observation;
  late bool isEditMode;

  ObservationScreen(this.observation, {super.key}) {
    //When opening after a user clicks a card, show a previously created observation in viewing mode.
    //When opening after a user clicks the add observation button, show a new observation in edit mode.
    isEditMode = observation.uid == null ? true : false;
  }

  @override
  ObservationScreenState createState() => ObservationScreenState();
}

class ObservationScreenState extends State<ObservationScreen> with TickerProviderStateMixin {

  final _formKey = GlobalKey<FormState>();

  final EdgeInsets _horzPadding = const EdgeInsets.symmetric(horizontal: 20.0);

  late ScrollController _scrollController;
  late AnimationController _colorAnimationController;
  late Animation<Color?> _colorTween;

  bool needsUpdated = false;

  bool justKeepToggling = true;

  var assetsAudioPlayer = AssetsAudioPlayer();
  PlayerState _playerState = PlayerState.stop;

  bool _isUploading = false;

  bool _hideGeoFields = false;
  final bool _hideDateFields = false;

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
    _colorAnimationController = AnimationController(vsync: this, duration: const Duration(seconds: 0));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    final user = Provider.of<AppUser?>(context);

    _colorTween = ColorTween(
        begin: context.watch<MaterialThemesManager>().colorPalette().secondary, //Colors.transparent,
        end: context.watch<MaterialThemesManager>().colorPalette().secondary)
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

  Widget _buildAppbar(AppUser? user) {
    return AnimatedBuilder(
        animation: _colorAnimationController,
        builder: (context, child) =>
            IconTitleIconFakeAppBar(
              shape: const StadiumBorder(),
              backgroundColor: _colorTween.value,
              title: 'Make Observation',
              titleType: ThemeGroupType.MOS,
              leftIcon: Icons.arrow_back,
              leftIconType: ThemeGroupType.MOS,
              leftIconClickedCallback: () => Navigator.pop(context),
              rightIcon: widget.isEditMode ? Icons.check : Icons.edit,
              showRightIcon: widget.isEditMode || widget.observation.dbId != null || (user != null && widget.observation.observerUid == user.uid),//Widget will only be in edit mode if new observation
              rightIconType: ThemeGroupType.MOS,
              rightIconClickedCallback: () async {
                if(!widget.isEditMode) {
                  setState(() {
                    widget.isEditMode = true;
                  });
                } else {
                  if (_formKey.currentState?.validate() == true) {
                    _formKey.currentState?.save();

                    await saveLocalObservation(widget.observation);

                    //TODO - CHRIS - probably worth moving to the saveObservationon method
                    var hasConnection = await DataConnectionChecker().hasConnection;
                    if(!hasConnection) {
                      showToast("No connection found.\nObservation saved locally.");
                    } else if (user != null) {
                      setState((){
                        _isUploading = true;
                      });

                      //If the observation was made when the user was not logged in, then edited after logging in, the user
                      //id can be null. So update it now. This allows local observations to be uploaded when online.
                      widget.observation.observerUid = user.uid;

                      //Share with others
                      await saveObservation(user, widget.observation);

                      setState(() {
                        _isUploading = false;
                        widget.isEditMode = false;
                      });
                    } else {
                      showToast("You must login to upload an observation.\nObservation saved locally.");
                    }
                  }
                }
              },
            )
    );
  }

  Box? box;
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
      onTap: () => widget.isEditMode ? _openFileExplorer(true, FileType.image, [], true) : {},
      child: SizedBox(
        height: 330,
        child: Stack(
          children: <Widget>[
            Hero(
              tag: "observationCoverImage",
              child: ClipShadowPath(
                clipper: SimpleClipPath(
                    type: ClipPathType.ROUNDED_DOWN,
                    bottomLeftPercentOfHeight: 80,
                    bottomRightPercentOfHeight: 80
                ),
                shadow: const Shadow(blurRadius: 20.0),
                child: _buildImage(),
              ),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: RawMaterialButton(
                  //padding: EdgeInsets.all(0.0),
                  //elevation: 12.0,
                  onPressed: () => developer.log('Play Video'),
                  shape: const CircleBorder(),
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
                onPressedCallback: () => developoer.log('Allow user to manually select a geo point'),
              )
          ),*/
            if(widget.isEditMode) ... [
              Positioned(
                bottom: 10.0,
                left: 10.0,
                child: ThemedIconButton(
                    Icons.my_location,
                    iconSize: IconSize.MEDIUM,
                    onPressedCallback: () => { _getCurrentPositionAndUpdateUi() },
                    type: ThemeGroupType.SOM,
                ),
              ),
            ],
            Positioned(
              bottom: 10.0,
              right: 10.0,
              child: ThemedIconButton(
                  Icons.help,
                  iconSize: IconSize.MEDIUM,
                  type: ThemeGroupType.SOM,
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
          color: context.watch<MaterialThemesManager>().colorPalette().secondary,
          size: 48),
      playIcon: Icon(Icons.play_arrow,
          color: context.watch<MaterialThemesManager>().colorPalette().secondary,
          size: 48),
      onPressed: () {
        var audioUrls = widget.observation.audioUrls;
        if (audioUrls != null && audioUrls.isNotEmpty) {
          _playAudio(audioUrls[0]);
        } else {
          showToast("No recordings to play");
        }
      },
    );
  }

  Widget _buildRecordButton() {
    return ThemedPlayButton(
      playIcon: Icon(Icons.mic,
          color: context.watch<MaterialThemesManager>().colorPalette().secondary,
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
    var imageUrls = widget.observation.imageUrls ?? <String>[];
    if(imageUrls.isEmpty) {
      return const Image(
        height: 300.0,
        width: double.infinity,
        fit: BoxFit.cover,
        image: AssetImage("assets/images/add_image.png"),
      );
    } else if(imageUrls[0].contains("https://")) {
      return Image.network(
        imageUrls[0],
        height: 300.0,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else {
      return Image.file(
        File(imageUrls[0]),
        height: 300.0,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }
  }

  Widget _buildLatLonAltitude() {
    String latitude = widget.observation.latitude?.toStringAsFixed(3) ?? "";
    String editLatitude = widget.observation.latitude?.toString() ?? "";
    String longitude = widget.observation.longitude?.toStringAsFixed(3) ?? "";
    String editLongitude = widget.observation.longitude?.toString() ?? "";
    String altitude = widget.observation.altitude?.toStringAsFixed(2) ?? "";
    String editAltitude = widget.observation.altitude?.toString() ?? "";

    return Row(
      children: <Widget>[
        Flexible(
          flex: 1,
          child: Align(
            alignment: Alignment.centerRight,
            child:Column(
              children: <Widget>[
                ThemedSubTitle("Latitude", type: ThemeGroupType.POM),
                tinyTransparentDivider,
                if (_hideGeoFields) ... [
                  //A hack state because geo fields not updating from self location button
                  //Don't add another ThemedEditableLabelValue here; it'll just create the same issue of not updating
                  ThemedTitle(latitude, type: ThemeGroupType.MOM, emphasis: Emphasis.HIGH),
                ]
                else if (widget.isEditMode) ...[
                  ThemedEditableLabelValue(
                    showLabel: false,
                    text: editLatitude,
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
        Flexible(
          flex: 1,
          child: Align(
            alignment: Alignment.center,
            child: Column(
              children: <Widget>[
                ThemedSubTitle("Longitude", type: ThemeGroupType.POM),
                tinyTransparentDivider,
                if (_hideGeoFields) ... [
                  //A hack state because geo fields not updating from self location button
                  //Don't add another ThemedEditableLabelValue here; it'll just create the same issue of not updating
                  ThemedTitle(longitude, type: ThemeGroupType.MOM, emphasis: Emphasis.HIGH),
                ] else if (widget.isEditMode) ...[
                  ThemedEditableLabelValue(
                    showLabel: false,
                    text: editLongitude,
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
                  ThemedTitle(altitude, type: ThemeGroupType.MOM, emphasis: Emphasis.HIGH),
                ] else if (widget.isEditMode) ...[
                  ThemedEditableLabelValue(
                    showLabel: false,
                    text: editAltitude,
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
    showToast("Fetching location ...");

    await checkPermissionsAndGetCurrentPosition()
      .then((Position position) {
        String lat = position.latitude.toStringAsFixed(2);
        String lon = position.longitude.toStringAsFixed(2);
        String alt = position.altitude.toStringAsFixed(2);
        showToast("Location:\n$lat $lon $alt");

        setState(() {
          widget.observation.latitude = position.latitude;
          widget.observation.longitude = position.longitude;
          widget.observation.altitude = position.altitude;

          _hideGeoFields = true;
          resetHideGeoFields();
        });
      })
      .catchError((e) {
        showToast("$e");
      });
  }

  resetHideGeoFields() async {
    await Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _hideGeoFields = false;
      });
    });
  }

  Widget _buildHeader() {
    var date = widget.observation.date;
    String month = date == null ? "" : DateFormat.yMMMMd('en_US').format(date).split(" ")[0];
    String day = date == null ? "" : date.day.toString();
    String year = date == null ? "" : date.year.toString();

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
              text: widget.observation.name?.toUpperCase() ?? "",
              textType: ThemeGroupType.POM,
              hintText: "Observation Name",
              onStringChangedCallback: (value) => { widget.observation.name = value.toUpperCase() },
              validator: (value) => nonEmptyValidator(value, "Observation Name", true),
            )
          ] else ... [
            ThemedH5(widget.observation.name?.toUpperCase(), type: ThemeGroupType.POM, emphasis: Emphasis.HIGH),
          ],
          miniTransparentDivider,
          if(widget.isEditMode) ... [
            ThemedEditableLabelValue(
              showLabel: false,
              text: widget.observation.location ?? "",
              textType: ThemeGroupType.POM,
              hintText: "Site Location Name",
              onStringChangedCallback: (value) => { widget.observation.location = value },
              validator: (value) => nonEmptyValidator(value, "Site Location Name", true),
            )
          ] else ... [
            ThemedSubTitle(widget.observation.location, type: ThemeGroupType.MOM),
          ],
          //TODO - smallTransparentDivider,
          //TODO - ThemedTitle('⭐ ⭐ ⭐ ⭐', type: ThemeGroupType.SOM),//TODO - hide until we allow jo
          smallTransparentDivider,
          Row(
            children: <Widget>[
              if(widget.isEditMode) ... [
                ThemedIconButton(
                    Icons.date_range,
                    iconSize: IconSize.MEDIUM,
                    onPressedCallback: () => { _selectDate(context) },
                    type: ThemeGroupType.SOM,
                ),
              ],
              Flexible(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerRight,
                  child:Column(
                    children: <Widget>[
                      ThemedSubTitle("Month", type: ThemeGroupType.POM),
                      tinyTransparentDivider,
                      if (_hideDateFields) ... [
                        //A hack state because geo fields not updating from self location button
                        //Don't add another ThemedTitle here; it'll just create the same issue of not updating
                      ] else ... [
                        ThemedTitle(month, type: ThemeGroupType.MOM, emphasis: Emphasis.HIGH),
                      ],
                    ],
                  ),
                ),
              ),
              Flexible(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.center,
                    child: Column(
                      children: <Widget>[
                        ThemedSubTitle("Day", type: ThemeGroupType.POM),
                        tinyTransparentDivider,
                        if (_hideDateFields) ... [
                          //A hack state because geo fields not updating from self location button
                          //Don't add another ThemedTitle here; it'll just create the same issue of not updating
                        ] else ... [
                          ThemedTitle(day, type: ThemeGroupType.MOM, emphasis: Emphasis.HIGH),
                        ],
                      ],
                    ),
                  ),
              ),
              Flexible(
                  flex: 1,
                  child: Container(
                    alignment: Alignment.centerLeft,
                    child:Column(
                      children: <Widget>[
                        ThemedSubTitle("Year", type: ThemeGroupType.POM),
                        tinyTransparentDivider,
                        if (_hideDateFields) ... [
                          //A hack state because geo fields not updating from self location button
                          //Don't add another ThemedTitle here; it'll just create the same issue of not updating
                        ] else ... [
                          ThemedTitle(year, type: ThemeGroupType.MOM, emphasis: Emphasis.HIGH),
                        ],
                      ],
                    ),
                  ),
              ),
              if(widget.isEditMode) ... [
                ThemedIconButton(
                    null,
                    iconSize: IconSize.MEDIUM,
                    onPressedCallback: () => { }
                ),
              ],
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
            context.read<MaterialThemesManager>().getTheme(ThemeGroupType.MOP, emphasis: Emphasis.HIGH).iconTheme.color ?? Colors.white,
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
      images: widget.observation.imageUrls ?? <String>[],
      title: 'Images',
      emptyListMessage: "No Images",
      imageHeight: 200.0,
      imageWidth: 250.0,
      icons: icons,
      onDeleteClickedCallback: (value) => { _removeImage(value) }
    );
  }

  _removeImage(path) {
    setState(() {
      //remove image from the observation
      widget.observation.imageUrls?.remove(path);
      needsUpdated = true;
    });

    showToast("Delete $path");
  }

  Widget _buildAudioRecordings() {

    var icons = !widget.isEditMode ? <Widget>[] : [
      ThemedIconButton(Icons.audiotrack, onPressedCallback: () => _openFileExplorer(true, FileType.custom, ['3gp','aa','aac','aax','act','aiff','alac','amr','ape','au','awb','dss','dvf','flac','gsm','iklax','kvs','m4a','m4b','m4p','mmf','movpkg','mp3','mpc','msv','nmf','ogg','oga','mogg','opus','ra','rm','raw','rf64','sln','tta','voc','vox','wav','wma','wv','webm','8svx','cda'], false)),
      ThemedIconButton(Icons.mic, onPressedCallback: () => { _openAudioRecorder() })
    ];

    return AudioContentScroll(
      urls: widget.observation.audioUrls ?? <String>[],
      title: 'Audio Recordings',
      emptyListMessage: "No Audio Recordings",
      imageHeight: 200.0,
      imageWidth: 250.0,
      icons: icons,
    );
  }

  void showAudioRecorderDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        developer.log("AudioUrl...");
        return const AudioRecorderDialog();
      }
    ).then((value) => {
      setState(() {
        if (value != null && (value as String).isNotEmpty) {
          developer.log("AudioUrls value: $value");
          widget.observation.audioUrls?.add(value);
          justKeepToggling = !justKeepToggling;
          developer.log("AudioUrls: ${widget.observation.audioUrls}");
        }
      })
    });
  }

  void _openAudioRecorder() async {
    try {
      //Always check for permission. It will ask for permission if not already granted
      //NOTE: FlutterAudioRecorder3.hasPermissions requests the permission by showing the dialog to the user,
      //but hasPermissions is always false. So, don't use it. Keeping this here as a reminder.
      //bool hasPermission = await FlutterAudioRecorder3.hasPermissions ?? false;

      if (await Permission.microphone.request().isGranted) {
        showAudioRecorderDialog();
      } else {
        showToast("Could not open recorder.\nYou must accept audio permissions.");
      }
    } catch (e) {
      developer.log(e.toString());
    }
  }

  void _addMediaUrlsToObservations(List<String> filePaths, bool addImages) {
    setState(() {
      for (var filePath in filePaths) {
        if (addImages) {
          if (widget.observation.imageUrls?.contains(filePath) == true) {
            showToast("Did not add image. It is already in list.");
          } else {
            widget.observation.imageUrls?.add(filePath);
          }
        } else if (widget.observation.audioUrls?.contains(filePath) == true) {
          showToast("Did not add audio. It is already in list.");
        } else {
          widget.observation.audioUrls?.add(filePath);
        }
      }

      needsUpdated = filePaths.isNotEmpty;
    });
  }

  Future<void> _pickMultipleFiles(FileType pickingType, List<String> allowedExtensions, bool addImages) async {

    FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: pickingType,
        allowedExtensions: allowedExtensions,
        allowMultiple: true
    );

    // Result is null if user cancelled
    List<String> filePaths = result?.paths.whereType<String>().toList() ?? <String>[];
    //List<File> files = filePaths.map((path) => File(path)).toList();

    /*if (mounted && filePaths.isNotEmpty) {
      developer.log("File paths:$filePaths");
    }*/

    _addMediaUrlsToObservations(filePaths, addImages);
  }

  Future<void> _pickSingleFile(FileType pickingType, List<String> allowedExtensions, bool addImages) async {

    FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: pickingType,
        allowedExtensions: allowedExtensions
    );

    // Result is null if user cancelled
    var filePath = result?.files.single.path ?? "";
    //File file = File(filePath);

    /*if (mounted && filePath.isNotEmpty) {
      developer.log("File path:$filePath name:${ filePath.split('/').last }");
    }*/

    if (filePath.isNotEmpty) {
      _addMediaUrlsToObservations([filePath], addImages);
    }
  }
  
  void _openFileExplorer(bool isMultiPick, FileType pickingType, List<String> allowedExtensions, bool addImages) async {
    try {
      var isAndroid = Platform.isAndroid;
      var isIos = Platform.isIOS;

      if (isAndroid || isIos) {
        var isCameraPermissionGranted = await Permission.camera.request().isGranted;
        if (!isCameraPermissionGranted) {
          showToast("Could not open file picker.\nYou must accept camera permissions.");
          return;
        }
        var isPhotosPermissionGranted = await Permission.photos.request().isGranted;
        if (!isPhotosPermissionGranted) {
          showToast("Could not open file picker.\nYou must accept photos permissions.");
          return;
        }

        var isStoragePermissionGranted = await Permission.storage.request().isGranted;
        if (!isStoragePermissionGranted) {
          showToast("Could not open file picker.\nYou must accept storage permissions.");
          return;
        }
      }

      if (isAndroid) {
        var isMediaLocationPermissionGranted = await Permission.accessMediaLocation.request().isGranted;
        if (!isMediaLocationPermissionGranted) {
          showToast("Could not open file picker.\nYou must accept media location permissions.");
          return;
        }

        var isManageExternalStoragePermissionGranted = await Permission.manageExternalStorage.request().isGranted;
        if (!isManageExternalStoragePermissionGranted) {
          showToast("Could not open file picker.\nYou must accept external storage permissions.");
          return;
        }

        var isVideosPermissionGranted = await Permission.videos.request().isGranted;
        if (!isVideosPermissionGranted) {
          showToast("Could not open file picker.\nYou must accept videos permissions.");
          return;
        }
      }

      if (isIos) {
        var isMediaLibraryPermissionGranted = await Permission.mediaLibrary.request().isGranted;
        if (!isMediaLibraryPermissionGranted) {
          showToast("Could not open file picker.\nYou must accept media library permissions.");
          return;
        }
      }

      if (isMultiPick) {
        await _pickMultipleFiles(pickingType, allowedExtensions, addImages);
      } else {
        await _pickSingleFile(pickingType, allowedExtensions, addImages);
      }
    } on PlatformException catch (e) {
      developer.log("Unsupported operation$e");
    }
  }

  Future<void> _cropImage(
    String sourcePath,
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
    
    CroppedFile? cropped = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      uiSettings: [
        AndroidUiSettings(
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
      ]
    );
    
    var croppedPath = cropped?.path;
    
    if (croppedPath == null) {
      showToast("Error when trying to crop image");
    }

    setState(() {
      widget.observation.imageUrls?.add(croppedPath ?? sourcePath);
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

    var isPermissionGranted = await Permission.camera.request().isGranted;
    if (!isPermissionGranted) {
      showToast("Could not open camera.\nYou must accept camera permissions.");
      return;
    }

    //Take picture with camera ...
    var imagePicker = ImagePicker();
    XFile? selected = await imagePicker.pickImage(source: ImageSource.camera);

    var selectedPath = selected?.path;
    
    if (selectedPath == null) {
      showToast("Error when trying to take picture");
    } else {
      _cropImage(
          selectedPath,
          toolbarColor,
          statusBarColor,
          toolbarWidgetColor,
          backgroundColor,
          activeControlsWidgetColor,
          dimmedLayerColor,
          cropFrameColor,
          cropGridColor,
          cropFrameStrokeWidth,
          cropGridRowCount,
          cropGridColumnCount
      ); 
    }
  }

  Widget _buildSignsChoices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        smallTransparentDivider,
        ThemedSubTitle("Signs", type: ThemeGroupType.POM),
        ChipsChoice<String>.multiple(
          padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
          value: widget.observation.signs ?? <String>[],
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
            padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
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
            padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
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
            padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
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
            padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
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
    var degF = "${String.fromCharCode($deg)}F";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        smallTransparentDivider,
        ThemedSubTitle("Temperature", type: ThemeGroupType.POM),
        ChipsChoice<String>.single(
            padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
            value: widget.observation.temperature,
            onChanged: (val) => {
              if (widget.isEditMode) {
                setState(() => widget.observation.temperature = val)
              }
            },
            choiceItems: C2Choice.listFrom<String, String>(
              source: ["Cold: <45$degF" , "Cool: 45 - 60$degF", "Warm: 60 - 75$degF", "Hot: >75$degF"],
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
            padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
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
            padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
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
          padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
          value: widget.observation.otherAnimalsPresent ?? <String>[],
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
              text: widget.observation.siteHistory ?? "",
              textType: ThemeGroupType.POM,
              hintText: "Note any history you've had with this site",
              //hintTextType: hintTextType,
              //hintTextEmphasis: hintTextEmphasis,
              //backgroundType: textFieldBackgroundType,
              onStringChangedCallback: (value) => { widget.observation.siteHistory = value },
              //validator: validator
            )
          ] else ... [
            SizedBox(
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
              text: widget.observation.comments ?? "",
              textType: ThemeGroupType.POM,
              hintText: "Any additional observations",
              //hintTextType: hintTextType,
              //hintTextEmphasis: hintTextEmphasis,
              //backgroundType: textFieldBackgroundType,
              onStringChangedCallback: (value) => { widget.observation.comments = value },
              //validator: validator
            )
          ] else ... [
            SizedBox(
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.observation.date ?? DateTime.now(),
      firstDate: DateTime.fromMicrosecondsSinceEpoch(0),
      lastDate: DateTime.now()
    );
    if (picked != null && picked != widget.observation.date) {
      setState((){
        widget.observation.date = picked;
      });
    }
  }
}