// ignore_for_file: depend_on_referenced_packages
import 'dart:async';
import 'dart:io';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:chips_choice/chips_choice.dart';
import 'package:data_connection_checker_nulls/data_connection_checker_nulls.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_themes_widgets/appbars/icon_title_icon_fake_appbar.dart';
import 'package:material_themes_widgets/clippaths/clip_paths.dart';
import 'package:material_themes_widgets/defaults/dimens.dart';
import 'package:material_themes_widgets/forms/form_fields.dart';
import 'package:material_themes_widgets/forms/loading.dart';
import 'package:material_themes_widgets/dialogs/text_entry_dialog.dart';
import 'package:material_themes_widgets/fundamental/buttons_media.dart';
import 'package:material_themes_widgets/fundamental/icons.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';
import 'package:material_themes_widgets/fundamental/toggles.dart';
import 'package:material_themes_widgets/utils/collection_utils.dart';
import 'package:material_themes_widgets/utils/ui_utils.dart';
import 'package:material_themes_widgets/utils/validators.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:pika_patrol/model/app_user.dart';
import 'package:pika_patrol/model/observation.dart';
import 'package:pika_patrol/screens/training_screens_pager.dart';
import 'package:pika_patrol/widgets/audio_content_scroll.dart';
import 'package:pika_patrol/widgets/circular_clipper.dart';
import 'package:pika_patrol/widgets/content_scroll.dart';
import 'package:pika_patrol/utils/geo_utils.dart';
import 'package:pika_patrol/widgets/audio_recorder_dialog.dart';
import 'package:intl/intl.dart';  //for date format
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as developer;

import '../data/pika_species.dart';
import '../l10n/translations.dart';
import '../services/google_sheets_service.dart';
import '../utils/observation_utils.dart';
import 'home_with_drawer.dart';

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

  late Translations translations;

  @override
  void initState() {
    _scrollController = ScrollController();
    _colorAnimationController = AnimationController(vsync: this, duration: const Duration(seconds: 0));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    translations = Provider.of<Translations>(context);

    final user = Provider.of<AppUser?>(context);

    _colorTween = ColorTween(
        begin: context.watch<MaterialThemesManager>().colorPalette().secondary, //Colors.transparent,
        end: context.watch<MaterialThemesManager>().colorPalette().secondary)
        .animate(_colorAnimationController);

    // Show delete button even when not editing
    var canEdit = user != null && (widget.observation.observerUid == user.uid || user.isAdmin);
    var isNewObservation = widget.observation.uid == null && widget.observation.dbId == null;
    var showDeleteButton = canEdit && !isNewObservation;

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
                    _buildHeaderImage(context),
                    _buildHeader(),
                    _buildFields(),
                    smallTransparentDivider,
                    _buildImages(
                        context.watch<MaterialThemesManager>().colorPalette().primary,
                        context.watch<MaterialThemesManager>().colorPalette().primary
                    ),
                    smallTransparentDivider,
                    _buildAudioRecordings(),
                    if (showDeleteButton) ... [
                      _buildDeleteButtonForForm()
                    ],
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
                child: const Loading(),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildAppbar(AppUser? user) => AnimatedBuilder(
    animation: _colorAnimationController,
    builder: (context, child) {

      var isUsersObservationOrAdmin = user != null && (widget.observation.observerUid == user.uid || user.isAdmin);
      var showRightIcon = widget.isEditMode || widget.observation.dbId != null || isUsersObservationOrAdmin;

      return IconTitleIconFakeAppBar(
        shape: const StadiumBorder(),
        backgroundColor: _colorTween.value,
        title: translations.makeObservation,
        titleType: ThemeGroupType.MOS,
        leftIcon: Icons.arrow_back,
        leftIconType: ThemeGroupType.MOS,
        leftIconClickedCallback: () => Navigator.pop(context),
        rightIcon: widget.isEditMode ? Icons.check : Icons.edit,
        showRightIcon: showRightIcon,
        //Widget will only be in edit mode if new observation
        rightIconType: ThemeGroupType.MOS,
        rightIconClickedCallback: () async {
          if (!widget.isEditMode) {
            setState(() {
              widget.isEditMode = true;
            });
          } else {
            if (_formKey.currentState?.validate() == true) {
              _formKey.currentState?.save();

              widget.observation.dateUpdatedInGoogleSheets = DateTime.now();

              var isInitialObservation = widget.observation.uid == null;//always save a new observation locally
              var isUsersObservation = user != null && user.uid == widget.observation.observerUid;//don't save another user's observations locally; can happen when admin edits
              if (isInitialObservation || isUsersObservation) {
                widget.observation.isUploaded = false;//The observation was updated and not yet uploaded; ensure that's reflected in case !hasConnection
                var localObservation = await saveLocalObservation(widget.observation);//TODO - CHRIS - I don't like the save local, save, save local approach
              }

              //TODO - CHRIS - probably worth moving to the saveObservationon method
              var hasConnection = await DataConnectionChecker().hasConnection;
              if (!hasConnection) {
                showToast(translations.noConnectionFoundObservationSavedLocally);
              } else if (user != null) {
                setState(() {
                  _isUploading = true;
                });

                //If the observation was made when the user was not logged in, then edited after logging in, the user
                //id can be null. So update it now. This allows local observations to be uploaded when online.
                // However, if it's not null, then an admin could be editing it; so, don't override the original owner's ID
                widget.observation.observerUid ??= user.uid;

                //Share with others
                if (context.mounted) {
                  await saveObservation(context, widget.observation);
                }

                setState(() {
                  _isUploading = false;
                });
              } else {
                showToast(translations.youMustLoginToUploadAnObservationObservationSavedLocally);
              }
              setState(() {
                widget.isEditMode = false;
              });
            }
          }
        },
      );
    }
  );

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

  Widget _buildHeaderImage(BuildContext context) => GestureDetector(
    onTap: () => widget.isEditMode ? _openFileExplorer(true, FileType.image, [], true) : {},
    child: SizedBox(
      height: 330,
      child: Stack(
        children: <Widget>[
          Hero(
            tag: "observationCoverImage",
            child: ClipShadowPath(
              clipper: const SimpleClipPath(
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

  Widget _buildPlayButton() => ThemedPlayButton(
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
        showToast(translations.noRecordingsToPlay);
      }
    },
  );

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
    String editLatitude = widget.observation.latitude?.toStringAsFixed(5) ?? "";
    String longitude = widget.observation.longitude?.toStringAsFixed(3) ?? "";
    String editLongitude = widget.observation.longitude?.toStringAsFixed(5) ?? "";

    double? altMeters = widget.observation.altitudeInMeters;
    String altitudeInMeters = altMeters != null ? metersToFeet(altMeters).toStringAsFixed(2) : "";//Display altitude is shortened
    String editAltitudeInMeters = altMeters != null ? metersToFeet(altMeters).toStringAsFixed(2) : "";    //Editable altitude is full length

    return Row(
      children: <Widget>[
        Flexible(
          flex: 1,
          child: Align(
            alignment: Alignment.centerRight,
            child:Column(
              children: <Widget>[
                ThemedSubTitle(translations.latitude, type: ThemeGroupType.POM),
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
                    validator: (value) => isValidGeo(value, translations.latitude),
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
                ThemedSubTitle(translations.longitude, type: ThemeGroupType.POM),
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
                    validator: (value) => isValidGeo(value, translations.longitude),
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
                ThemedSubTitle(translations.altitude, type: ThemeGroupType.POM),
                tinyTransparentDivider,
                if (_hideGeoFields) ... [
                  //A hack state because geo fields not updating from self location button
                  //Don't add another ThemedEditableLabelValue here; it'll just create the same issue of not updating
                  ThemedTitle(altitudeInMeters, type: ThemeGroupType.MOM, emphasis: Emphasis.HIGH),
                ] else if (widget.isEditMode) ...[
                  ThemedEditableLabelValue(
                    showLabel: false,
                    text: editAltitudeInMeters,
                    textType: ThemeGroupType.POM,
                    hintText: "0.0",
                    onStringChangedCallback: (value) {
                      var altitudeInFeet = double.parse(value);
                      widget.observation.altitudeInMeters = feetToMeters(altitudeInFeet);
                    },
                    validator: (value) => isValidGeo(value, translations.altitude),
                  )
                ] else ...[
                  ThemedTitle(altitudeInMeters, type: ThemeGroupType.MOM, emphasis: Emphasis.HIGH),
                ]
              ],
            ),
          )
        )
      ],
    );
  }

  _getCurrentPositionAndUpdateUi() async {
    showToast(translations.fetchingLocation);

    await checkPermissionsAndGetCurrentPosition(translations)
      .then((Position position) {
        String lat = position.latitude.toStringAsFixed(2);
        String lon = position.longitude.toStringAsFixed(2);
        String alt = position.altitude.toStringAsFixed(2);
        showToast("${translations.location}:\n$lat $lon $alt");

        setState(() {
          widget.observation.latitude = position.latitude;
          widget.observation.longitude = position.longitude;
          widget.observation.altitudeInMeters = position.altitude;

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
              text: widget.observation.location ?? "",
              textType: ThemeGroupType.POM,
              hintText: translations.siteName,
              onStringChangedCallback: (value) => { widget.observation.location = value },
              validator: (value) => nonEmptyValidator(value, translations.siteName, true),
            )
          ] else ... [
            ThemedH5(widget.observation.location?.toUpperCase(), type: ThemeGroupType.POM, emphasis: Emphasis.HIGH),
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
                      ThemedSubTitle(translations.month, type: ThemeGroupType.POM),
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
                        ThemedSubTitle(translations.day, type: ThemeGroupType.POM),
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
                        ThemedSubTitle(translations.year, type: ThemeGroupType.POM),
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
          _buildPikaSpecies(),
          _buildSignsChoices(),
          _buildCountChoices(),
          _buildDistanceChoices(),
          _buildSearchDurationChoices(),
          _buildTalusAreaChoices(),
          _buildTemperatureChoices(),
          _buildSkiesChoices(),
          _buildWindChoices(),
          _buildOtherAnimalsPresent(),
          _buildSharedWithProjects(),
          _buildSiteHistory(),
          _buildComments(),
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
      title: translations.images,
      emptyListMessage: translations.noImages,
      imageHeight: 200.0,
      imageWidth: 250.0,
      icons: icons,
      onDeleteClickedCallback: (value) => { _removeImage(value) },
      showDeleteButtonOnCard: widget.isEditMode
    );
  }

  _removeImage(path) {
    setState(() {
      //remove image from the observation
      widget.observation.imageUrls?.remove(path);
      needsUpdated = true;
    });

    showToast("${translations.delete} $path");
  }

  Widget _buildAudioRecordings() {

    var icons = !widget.isEditMode ? <Widget>[] : [
      ThemedIconButton(Icons.audiotrack, onPressedCallback: () => _openFileExplorer(true, FileType.custom, ['3gp','aa','aac','aax','act','aiff','alac','amr','ape','au','awb','dss','dvf','flac','gsm','iklax','kvs','m4a','m4b','m4p','mmf','movpkg','mp3','mpc','msv','nmf','ogg','oga','mogg','opus','ra','rm','raw','rf64','sln','tta','voc','vox','wav','wma','wv','webm','8svx','cda'], false)),
      ThemedIconButton(Icons.mic, onPressedCallback: () => { _openAudioRecorder()})
    ];

    return AudioContentScroll(
      urls: widget.observation.audioUrls ?? <String>[],
      title: translations.audioRecordings,
      emptyListMessage: translations.noAudioRecordings,
      imageHeight: 200.0,
      imageWidth: 250.0,
      icons: icons,
    );
  }

  void showAudioRecorderDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) => const AudioRecorderDialog(),
      barrierDismissible: true
    ).then((value) => {
      setState(() {
        if (value != null && (value as String).isNotEmpty) {
          widget.observation.audioUrls?.add(value);
          justKeepToggling = !justKeepToggling;
        }
      })
    });
  }

  void _openAudioRecorder() async {
    try {
      //Always check for permission. It will ask for permission if not already granted
      //NOTE: FlutterAudioRecorder4.hasPermissions requests the permission by showing the dialog to the user,
      //but hasPermissions is always false. So, don't use it. Keeping this here as a reminder.
      //bool hasPermission = await FlutterAudioRecorder4.hasPermissions ?? false;

      if (await Permission.microphone.request().isGranted) {
        showAudioRecorderDialog();
      } else {
        showToast(translations.couldNotOpenRecorder);
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
            showToast(translations.didNotAddImage);
          } else {
            widget.observation.imageUrls?.add(filePath);
          }
        } else if (widget.observation.audioUrls?.contains(filePath) == true) {
          showToast(translations.didNotAddAudio);
        } else {
          widget.observation.audioUrls?.add(filePath);
        }
      }

      needsUpdated = filePaths.isNotEmpty;
    });
  }

  Future<void> _pickMultipleFiles(
    FileType pickingType,
    List<String> allowedExtensions,
    bool addImages
  ) async {

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
          showToast(translations.couldNotOpenFilePickerAcceptCameraPermissions);
          return;
        }
      }

      if (isAndroid) {

        //Devices running Android 13 (API level 33) and above require the photos permission and don't
        //even have storage permission. Device before that only have storage permission.
        //So, if either is accepted then the system has the correct permissions for the given sdk
        var isPhotosPermissionGranted = await Permission.photos.request().isGranted;
        var isVideosPermissionGranted = await Permission.videos.request().isGranted;
        var isAudioPermissionGranted = await Permission.audio.request().isGranted;

        var isStoragePermissionGranted = await Permission.storage.request().isGranted;
        var isMediaLocationPermissionGranted = await Permission.accessMediaLocation.request().isGranted;
        var isManageExternalStoragePermissionGranted = await Permission.manageExternalStorage.request().isGranted;

        var allPreSdk33FilePermissionsGranted = isStoragePermissionGranted && isMediaLocationPermissionGranted && isManageExternalStoragePermissionGranted;
        var allSdk33FilePermissionsGranted = isPhotosPermissionGranted && isVideosPermissionGranted && isAudioPermissionGranted;
        var allSdkSpecificPermissionsGranted = allPreSdk33FilePermissionsGranted || allSdk33FilePermissionsGranted;

        if (!allSdkSpecificPermissionsGranted) {
          if (!isPhotosPermissionGranted) {
            showToast(translations.couldNotOpenFilePickerAcceptPhotosPermissions);
            return;
          }

          if (!isStoragePermissionGranted) {
            showToast(translations.couldNotOpenFilePickerAcceptStoragePermissions);
            return;
          }

          if (!isMediaLocationPermissionGranted) {
            showToast(translations.couldNotOpenFilePickerAcceptMediaPermissions);
            return;
          }

          if (!isManageExternalStoragePermissionGranted) {
            showToast(translations.couldNotOpenFilePickerAcceptExternalStoragePermissions);
            return;
          }


          if (!isVideosPermissionGranted) {
            showToast(translations.couldNotOpenFilePickerAcceptVideosPermissions);
            return;
          }
        }
      }

      if (isIos) {
        var isMediaLibraryPermissionGranted = await Permission.mediaLibrary.request().isGranted;
        if (!isMediaLibraryPermissionGranted) {
          showToast(translations.couldNotOpenFilePickerAcceptMediaLibraryPermissions);
          return;
        }

        var isPhotosPermissionGranted = await Permission.photos.request().isGranted;
        if (!isPhotosPermissionGranted) {
          showToast(translations.couldNotOpenFilePickerAcceptPhotosPermissions);
          return;
        }

        var isStoragePermissionGranted = await Permission.storage.request().isGranted;
        if (!isStoragePermissionGranted) {
          showToast(translations.couldNotOpenFilePickerAcceptStoragePermissions);
          return;
        }
      }

      if (isMultiPick) {
        await _pickMultipleFiles(pickingType, allowedExtensions, addImages);
      } else {
        await _pickSingleFile(pickingType, allowedExtensions, addImages);
      }
    } on PlatformException catch (e) {
      developer.log("${translations.unsupportedOperation}: $e");
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
      showToast(translations.errorWhenTryingToCropImage);
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
      showToast(translations.couldNotOpenCameraAcceptCameraPermissions);
      return;
    }

    //Take picture with camera ...
    var imagePicker = ImagePicker();
    XFile? selected = await imagePicker.pickImage(source: ImageSource.camera);

    var selectedPath = selected?.path;
    
    if (selectedPath == null) {
      showToast(translations.errorWhenTryingToTakePicture);
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

  Widget _buildPikaSpecies() {
    var speciesValues = widget.observation.getSpeciesValues(translations);//TODO - CHRIS - using this inline results in American Pika showing twice; not sure why
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        smallTransparentDivider,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ThemedSubTitle(translations.species, type: ThemeGroupType.POM),
            /*if (widget.isEditMode)...[
            ThemedIconButton(Icons.add, onPressedCallback: () => _openAddOtherSpeciesDialog())
          ]*/
          ],
        ),
        ChipsChoice<String>.single(
          padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
          value: widget.observation.species,
          onChanged: (value) => {
            if (widget.isEditMode) {
              setState(() => widget.observation.species = value)
            }
          },
          choiceItems: C2Choice.listFrom<String, String>(
            source: speciesValues,
            value: (i, v) => v,
            label: (i, v) => getSpeciesLabel(i, v, translations),
            tooltip: (i, v) => v,
          ),
        )
      ],
    );
  }

  void _openAddOtherSpeciesDialog() {
    if (!mounted) return;

    showDialog(
        context: context,
        builder: (BuildContext context) => TextEntryDialog(
          title: translations.addAnotherSpeciesDialogTitle,
          description: translations.addAnotherSpeciesDialogDescription,
        ),
        barrierDismissible: false
    ).then((value) => {
      setState(() {
        if (value != null && (value as String).isNotEmpty) {
          widget.observation.species = value.trim();
        }
      })
    });
  }

  Widget _buildSignsChoices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        smallTransparentDivider,
        ThemedSubTitle(translations.signs, type: ThemeGroupType.POM),
        ChipsChoice<String>.multiple(
          padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
          value: widget.observation.signs ?? <String>[],
          onChanged: (val) => {
            if (widget.isEditMode) {
              setState(() => widget.observation.signs = val)
            }
          },
          choiceItems: C2Choice.listFrom<String, String>(
            source: widget.observation.getSignsValues(translations),
            value: (i, v) => v,
            label: (i, v) => getSignsLabel(i, v, translations),
            tooltip: (i, v) => v,
          ),
        )
      ],
    );
  }

  Widget _buildCountChoices() {
    String? pikasDetected = widget.observation.pikasDetected;
    bool pikasDetectedEmpty = pikasDetected != null && pikasDetected.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        smallTransparentDivider,
        ThemedSubTitle(translations.pikasDetected, type: ThemeGroupType.POM),
        ChipsChoice<String>.single(
            padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
            value: pikasDetectedEmpty ? null : pikasDetected,//empty shows empty bubble instead of nothing selected
            onChanged: (val) => {
              if (widget.isEditMode) {
                setState(() {
                  //If selected the same value as before, unset the value
                  widget.observation.pikasDetected = widget.observation.pikasDetected == val ? null : val;
                })
              }
            },
            choiceItems: C2Choice.listFrom<String, String>(
              source: widget.observation.getPikasDetectedValues(translations),
              value: (i, v) => v,
              label: (i, v) => getPikasDetectedLabel(i, v, translations),
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
        ThemedSubTitle(translations.distanceToClosestPika, type: ThemeGroupType.POM),
        ChipsChoice<String>.single(
            padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
            value: widget.observation.distanceToClosestPika,
            onChanged: (val) => {
              if (widget.isEditMode) {
                setState(() => widget.observation.distanceToClosestPika = val)
              }
            },
            choiceItems: C2Choice.listFrom<String, String>(
              source: widget.observation.getDistanceToClosestPikaValues(translations),
              value: (i, v) => v,
              label: (i, v) => getDistanceToClosestPikaLabel(i, v, translations),
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
        ThemedSubTitle(translations.searchDuration, type: ThemeGroupType.POM),
        ChipsChoice<String>.single(
            padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
            value: widget.observation.searchDuration,
            onChanged: (val) => {
              if (widget.isEditMode) {
                setState(() => widget.observation.searchDuration = val)
              }
            },
            choiceItems: C2Choice.listFrom<String, String>(
              source: widget.observation.getSearchDurationValues(translations),
              value: (i, v) => v,
              label: (i, v) => getSearchDurationLabel(i, v, translations),
              tooltip: (i, v) => v,
            )
        )
      ],
    );
  }

  bool showTalusAreaHints = false;
  Widget _buildTalusAreaChoices() {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //smallTransparentDivider, //TODO - add this after fixing the ThemedIconButton styling in ThemesManager
        Row(
          children: [
            ThemedSubTitle(showTalusAreaHints ? translations.searchArea : translations.talusArea, type: ThemeGroupType.POM),
            Expanded(
              flex: 1,
              child: ThemedCaption(translations.showHints, type: ThemeGroupType.MOM, textAlign: TextAlign.end),
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
              source: widget.observation.getTalusAreaValues(translations),
              value: (i, v) => v,
              label: (i, v) => getTalusAreaLabel(i, v, translations, showTalusAreaHints),
              tooltip: (i, v) => getTalusAreaLabel(i, v, translations, showTalusAreaHints),
            )
        )
      ],
    );
  }

  Widget _buildTemperatureChoices() {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        smallTransparentDivider,
        ThemedSubTitle(translations.temperature, type: ThemeGroupType.POM),
        ChipsChoice<String>.single(
          padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
          value: widget.observation.temperature,
          onChanged: (val) => {
            if (widget.isEditMode) {
              setState(() => widget.observation.temperature = val)
            }
          },
          choiceItems: C2Choice.listFrom<String, String>(
            source: widget.observation.getTemperatureValues(translations),
            value: (i, v) => v,
            label: (i, v) => getTemperatureLabel(i, v, translations),
            tooltip: (i, v) => v,
          )
        )
      ],
    );
  }

  Widget _buildSkiesChoices() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      smallTransparentDivider,
      ThemedSubTitle(translations.skies, type: ThemeGroupType.POM),
      ChipsChoice<String>.single(
        padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
        value: widget.observation.skies,
        onChanged: (val) => {
          if (widget.isEditMode) {
            setState(() => widget.observation.skies = val)
          }
        },
        choiceItems: C2Choice.listFrom<String, String>(
          source: widget.observation.getSkiesValues(translations),
          value: (i, v) => v,
          label: (i, v) => getSkiesLabel(i, v, translations),
          tooltip: (i, v) => v,
        )
      )
    ],
  );

  Widget _buildWindChoices() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      smallTransparentDivider,
      ThemedSubTitle(translations.wind, type: ThemeGroupType.POM),
      ChipsChoice<String>.single(
        padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
        value: widget.observation.wind,
        onChanged: (val) => {
          if (widget.isEditMode) {
            setState(() => widget.observation.wind = val)
          }
        },
        choiceItems: C2Choice.listFrom<String, String>(
          source: widget.observation.getWindValues(translations),
          value: (i, v) => v,
          label: (i, v) => getWindLabel(i, v, translations),
          tooltip: (i, v) => v,
        )
      )
    ],
  );

  Widget _buildOtherAnimalsPresent() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      smallTransparentDivider,
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ThemedSubTitle(translations.otherAnimalsPresent, type: ThemeGroupType.POM),
          if (widget.isEditMode)...[
            ThemedIconButton(Icons.add, onPressedCallback: () => _openAddOtherAnimalsDialog())
          ]
        ],
      ),
      ChipsChoice<String>.multiple(
        padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
        value: widget.observation.otherAnimalsPresent ?? <String>[],
        onChanged: (val) => {
          if (widget.isEditMode) {
            setState(() => widget.observation.otherAnimalsPresent = val)
          }
        },
        choiceItems: C2Choice.listFrom<String, String>(
          source: widget.observation.getOtherAnimalsPresentValues(translations),
          value: (i, v) => v,
          label: (i, v) => getOtherAnimalsPresentLabel(i, v, translations),
          tooltip: (i, v) => v,
        ),
      )
    ],
  );

  void _openAddOtherAnimalsDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) => TextEntryDialog(
        title: translations.addAnotherAnimalDialogTitle,
        description: translations.addAnotherAnimalDialogDescription,
      ),
      barrierDismissible: false
    ).then((value) => {
      setState(() {
        if (value != null && (value as String).isNotEmpty) {
          var otherAnimalsPresent = widget.observation.otherAnimalsPresent ?? <String>[];
          otherAnimalsPresent.addAll(value.split(","));
          otherAnimalsPresent = otherAnimalsPresent.map((string) => string.replaceAllMapped(RegExp(r'^\s+|\s+$'), (match) => "")).toSet().toList();
          widget.observation.otherAnimalsPresent = otherAnimalsPresent;
        }
      })
    });
  }

  Widget _buildSharedWithProjects() {

    List<String> approvedOrganizations = [];//Provider.of<GoogleSheetsService>(context, listen: false).organizations.toTrimmedUniqueList().sortList();

    //TODO - CHRIS - figure out how to get the projects after user has logged in. Currently, the list
    //is still empty after logging in, until user restarts app
    //This list needs to be available offlline as well.
    if (approvedOrganizations.isEmpty) {
      approvedOrganizations = ["Colorado Pika Project", "Cascades Pika Watch", "PikaNET (Mountain Studies Institute)", "Glacier National Park", "Mt. Rainier National Park", "Cascades Forest Conservancy", "Montana Pika Project", "Nevada Pika Atlas"];//"Pika Patrol", "Denver Zoo", "IF/THEN", , "Rocky Mountain Wild"
    }

    var isNewObservation = widget.observation.uid == null;

    var sharedWithProjects = widget.observation.sharedWithProjects ?? [];
    var notSharedWithProjects = widget.observation.notSharedWithProjects ?? [];

    for (var approvedOrganization in approvedOrganizations) {
      if (!sharedWithProjects.contains(approvedOrganization) && !notSharedWithProjects.contains(approvedOrganization)) {
          notSharedWithProjects.add(approvedOrganization);
      }
    }

    sharedWithProjects = sharedWithProjects.toTrimmedUniqueList().sortList();
    widget.observation.sharedWithProjects = sharedWithProjects;

    notSharedWithProjects = notSharedWithProjects.toTrimmedUniqueList().sortList();
    widget.observation.notSharedWithProjects = notSharedWithProjects;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        smallTransparentDivider,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ThemedSubTitle(translations.sharedWithProjects, type: ThemeGroupType.POM),
            // if (widget.isEditMode)...[
            //   ThemedIconButton(Icons.add, onPressedCallback: () => _openSharedWithProjectsDialog())
            // ]
          ],
        ),
        if(sharedWithProjects.isNotEmpty || notSharedWithProjects.isNotEmpty) ... [
          ChipsChoice<String>.multiple(
            padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
            value: widget.observation.sharedWithProjects ?? <String>[],
            onChanged: (updatedSharedWithProjects) =>
            {
              if (widget.isEditMode) {
                setState((){
                  widget.observation.sharedWithProjects = updatedSharedWithProjects;

                  var approvedSet = approvedOrganizations.toSet();
                  var selectedSet = updatedSharedWithProjects.toSet();
                  widget.observation.notSharedWithProjects = List.from(approvedSet.difference(selectedSet));
                })
              }
            },
            choiceItems: C2Choice.listFrom<String, String>(
              source: approvedOrganizations,
              value: (i, v) => v,
              label: (i, v) => v,
              tooltip: (i, v) => v,
            ),
          )
        ]
      ],
    );
  }

  void _openSharedWithProjectsDialog() {
    if (!mounted) return;

    showDialog(
        context: context,
        builder: (BuildContext context) => TextEntryDialog(
          title: translations.addAnotherProjectDialogTitle,
          description: translations.addAnotherProjectDialogDescription
        ),
        barrierDismissible: false
    ).then((value) => {
      setState(() {
        if (value != null && (value as String).isNotEmpty) {
          var sharedWithProjects = widget.observation.sharedWithProjects ?? <String>[];
          sharedWithProjects.addAll(value.split(","));
          sharedWithProjects = sharedWithProjects.map((string) => string.replaceAllMapped(RegExp(r'^\s+|\s+$'), (match) => "")).toSet().toList();
          widget.observation.sharedWithProjects = sharedWithProjects;
        }
      })
    });
  }

  Widget _buildSiteHistory() => NotificationListener<ScrollNotification>(
    onNotification: (boolVal) { return true; },
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        smallTransparentDivider,
        ThemedSubTitle(translations.siteHistory, type: ThemeGroupType.POM),
        miniTransparentDivider,
        if(widget.isEditMode) ... [
          ThemedEditableLabelValue(
            showLabel: false,
            text: widget.observation.siteHistory ?? "",
            textType: ThemeGroupType.POM,
            hintText: translations.siteHistoryHint,
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

  Widget _buildComments() => NotificationListener<ScrollNotification>(
    onNotification: (boolVal) { return true; },
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        smallTransparentDivider,
        ThemedSubTitle(translations.comments, type: ThemeGroupType.POM),
        miniTransparentDivider,
        if(widget.isEditMode) ... [
          ThemedEditableLabelValue(
            showLabel: false,
            text: widget.observation.comments ?? "",
            textType: ThemeGroupType.POM,
            hintText: translations.anyAdditionalObservations,
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

  Widget _buildDeleteButtonForForm() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
    child: Center(
      child: _buildDeleteButton(false)
    )
  );

  Widget _buildDeleteButton(bool userConfirmedDelete) => ElevatedButton(
    onPressed: () async {
      if (userConfirmedDelete) {
        var exception = await deleteObservation(context, widget.observation, true, true);
        if (exception == null) {
          showToast(translations.observationDeleted);
          if (context.mounted) {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (BuildContext context) => const HomeWithDrawer())
            );
          }
        } else {
          showToast("${translations.observationNotDeleted} : $exception");
          if (context.mounted) {
            Navigator.pop(context, true);
          }
        }
      } else {
        _showDeleteObservationVerificationDialog();
      }
    },
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      backgroundColor: Colors.red,
      shape: const StadiumBorder(),
    ),
    child: ThemedTitle(translations.delete, type: ThemeGroupType.MOP),
  );

  Widget _buildCancelButton() => TextButton(
    child: Text(translations.cancel),
    onPressed: () async {
      Navigator.pop(context, true);
    },
  );

  _showDeleteObservationVerificationDialog() {
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text(translations.deleteObservationDialogTitle),
          content: Text(translations.deleteObservationDialogDescription),
          actions: [
            _buildCancelButton(),
            _buildDeleteButton(true)
          ],
        )
      );
    }
  }
}