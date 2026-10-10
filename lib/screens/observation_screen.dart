// ignore_for_file: depend_on_referenced_packages
import 'dart:convert';
import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:gal/gal.dart';
import 'package:just_audio/just_audio.dart';
import 'package:chips_choice/chips_choice.dart';
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
import 'package:pika_patrol/model/observation_view_model.dart';
import 'package:pika_patrol/utils/observation_utils.dart';
import 'package:provider/provider.dart';
import 'package:pika_patrol/model/app_user.dart';
import '../services/native_land_service.dart';

import 'package:pika_patrol/screens/training_screens_pager.dart';
import 'package:pika_patrol/widgets/audio_content_scroll.dart';
import 'package:pika_patrol/widgets/circular_clipper.dart';
import 'package:pika_patrol/widgets/confirm_dialog.dart';
import 'package:pika_patrol/widgets/content_scroll.dart';
import 'package:pika_patrol/widgets/universal_image.dart';
import 'package:pika_patrol/primitives/overlay_mode.dart';
import 'package:pika_patrol/utils/geo_utils.dart';
import 'package:pika_patrol/widgets/audio_recorder_dialog.dart';
import 'package:intl/intl.dart';  //for date format
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:path_provider/path_provider.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../l10n/translations.dart';
import '../services/observations_service.dart';
import '../services/settings_service.dart';
import '../utils/media_cache.dart';
import '../utils/firebase_utils.dart';
import '../utils/network_utils.dart';
import 'home_with_drawer.dart';

// ignore: must_be_immutable
class ObservationScreen extends StatefulWidget {

  final ObservationViewModel observationViewModel;

  //When true, this screen edits the default observation template (the values applied to every new
  //observation) instead of a real observation: images/audio are hidden and saving writes the
  //template to preferences rather than uploading.
  final bool isTemplate;

  const ObservationScreen(this.observationViewModel, {this.isTemplate = false, super.key});

  @override
  ObservationScreenState createState() => ObservationScreenState();
}

class ObservationScreenState extends State<ObservationScreen> with TickerProviderStateMixin {

  static const String _nativeLandMapUrl = 'https://native-land.ca/maps/native-land';

  // Native Land's map page only has toggleable overlay layers for these
  // categories (see its `allLayers` list); "territories" isn't one of them,
  // and passing it as `?category=` clobbers the default `languages` layer
  // without showing anything in return.
  static const Set<String> _nativeLandMapToggleableCategories = {'languages', 'treaties', 'greetings'};

  // chips_choice's default chip style is identical for selected and unselected, so the two
  // states are nearly indistinguishable without this. Note: ChipsChoice's own `choiceActiveStyle`
  // widget parameter isn't actually wired up in the installed package version, so the selected
  // look has to be set via C2ChipStyle.toned's `selectedStyle` instead, which is. backgroundOpacity
  // must be set to 1 explicitly - toned()'s default of .12 otherwise washes out these colors into
  // a barely-visible tint, which is what made selected/unselected hard to tell apart in the first place.
  static final C2ChipStyle _choiceChipStyle = C2ChipStyle.toned(
    backgroundColor: Colors.grey.shade200,
    backgroundOpacity: 1,
    foregroundColor: Colors.black87,
    borderColor: Colors.grey.shade400,
    borderStyle: BorderStyle.solid,
    // Selected chips differ by more than color (GitHub #72): dark fill, thick dark border, bold
    // text and a check mark, so they read clearly in sunlight, with polarized sunglasses, or
    // with limited color vision.
    selectedStyle: C2ChipStyle(
      backgroundColor: Colors.teal,
      backgroundOpacity: 1,
      foregroundColor: Colors.white,
      foregroundStyle: const TextStyle(fontWeight: FontWeight.bold),
      borderColor: Colors.black,
      borderWidth: 3,
      checkmarkColor: Colors.white,
    ),
  );

  final _formKey = GlobalKey<FormState>();

  final EdgeInsets _horzPadding = const EdgeInsets.symmetric(horizontal: 20.0);

  late ScrollController _scrollController;
  late AnimationController _colorAnimationController;
  late Animation<Color?> _colorTween;

  bool needsUpdated = false;

  bool justKeepToggling = true;

  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _audioPlayerStateSubscription;
  AudioPlaybackState _playerState = AudioPlaybackState.stop;
  int _playingIndex = -1;

  bool _isUploading = false;

  bool _hideGeoFields = false;
  final bool _hideDateFields = false;

  // Display-only units preference; backing data is unchanged by this choice (altitude is always
  // stored in meters, and the choice values for distance/talus/temperature are always stored as
  // their imperial English strings).
  bool _isMetric = false;

  // Debounces the Indigenous territory lookup for manually-typed coordinates: onStringChangedCallback
  // fires on every keystroke, and both latitude and longitude are separate fields, so firing the
  // lookup immediately would spam the API (and pop the Native Land map) mid-keystroke.
  Timer? _manualCoordinatesLookupDebounce;

  // Fetched fresh whenever an observation is opened in read-only (view) mode, kept only in local
  // widget state - unlike the edit-mode flow, this is never written back onto the observation
  // (nothing to persist for a view that doesn't save), and intentionally skips toasts/the map dialog.
  List<Territory>? _readOnlyTerritories;
  List<Territory>? _readOnlyLanguages;

  bool _scrollListener(ScrollNotification scrollInfo) {
    if (scrollInfo.metrics.axis == Axis.vertical) {
      _colorAnimationController.animateTo(scrollInfo.metrics.pixels / 350);
      return true;
    } else {
      return false;
    }
  }

  late Translations translations;

  // Kept in the state, not the widget, so a rebuilt widget can't flip the screen out of edit mode
  late bool _isEditMode;

  @override
  void initState() {
    //When opening after a user clicks a card, show a previously created observation in viewing mode.
    //When opening after a user clicks the add observation button, show a new observation in edit mode.
    _isEditMode = widget.observationViewModel.observation.isNewObservation();
    _scrollController = ScrollController();
    _colorAnimationController = AnimationController(vsync: this, duration: const Duration(seconds: 0));

    if (!_isEditMode) {
      _fetchIndigenousTerritoriesForViewing();
    } else {
      // A new observation can start with coordinates from the default template. Templates saved
      // before they kept the territories have none, so look them up for those coordinates.
      final observation = widget.observationViewModel.observation;
      final latitude = observation.latitude;
      final longitude = observation.longitude;
      if (latitude != null && longitude != null && (observation.indigenousTerritories?.isEmpty ?? true)
          && (observation.indigenousLanguages?.isEmpty ?? true)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _fetchAndSetIndigenousTerritories(latitude, longitude);
        });
      }
    }

    _audioPlayerStateSubscription = _audioPlayer.playerStateStream.listen(_onAudioPlayerStateChanged);

    super.initState();
  }

  @override
  void dispose() {
    _manualCoordinatesLookupDebounce?.cancel();
    _audioPlayerStateSubscription?.cancel();
    _audioPlayer.dispose();
    _scrollController.dispose();
    _colorAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    translations = Provider.of<Translations>(context);
    final settingsService = Provider.of<SettingsService>(context);
    _isMetric = settingsService.isMetric;
    showTalusAreaHints = settingsService.showHints;

    final user = Provider.of<AppUser?>(context);

    _colorTween = ColorTween(
        begin: context.watch<MaterialThemesManager>().colorPalette().secondary, //Colors.transparent,
        end: context.watch<MaterialThemesManager>().colorPalette().secondary)
        .animate(_colorAnimationController);

    // Show delete button even when not editing
    final observation = widget.observationViewModel.observation;
    var showDeleteButton = observation.canUserEdit(user) && !observation.isNewObservation();

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
                    if (!widget.isTemplate) ... [
                      smallTransparentDivider,
                      _buildImages(
                          context.watch<MaterialThemesManager>().colorPalette().primary,
                          context.watch<MaterialThemesManager>().colorPalette().primary
                      ),
                      smallTransparentDivider,
                      _buildAudioRecordings(),
                    ],
                    if (showDeleteButton) ... [
                      _buildDeleteButtonForForm(context)
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

      var showRightIcon = widget.observationViewModel.observation.canUserEdit(user);

      return IconTitleIconFakeAppBar(
        shape: const StadiumBorder(),
        backgroundColor: _colorTween.value,
        title: widget.isTemplate ? translations.defaultObservation : translations.makeObservation,
        titleType: ThemeGroupType.MOS,
        leftIcon: Icons.arrow_back,
        leftIconType: ThemeGroupType.MOS,
        leftIconClickedCallback: () => Navigator.pop(context),
        rightIcon: _isEditMode ? Icons.check : Icons.edit,
        showRightIcon: showRightIcon,
        rightIconType: ThemeGroupType.MOS,
        rightIconClickedCallback: () async {
          if (!_isEditMode) {
            setState(() {
              _isEditMode = true;

              // Entering edit mode switches the territories/languages display over to the
              // observation's own fields (since edit mode lets those change via GPS/manual
              // coordinates). Seed them from what read-only viewing already fetched so the
              // list doesn't disappear for observations that predate this feature or were
              // never re-geocoded in edit mode.
              final observation = widget.observationViewModel.observation;
              if ((observation.indigenousTerritories?.isEmpty ?? true) && (_readOnlyTerritories?.isNotEmpty ?? false)) {
                observation.indigenousTerritories = _encodeIndigenousEntries(_readOnlyTerritories!);
              }
              if ((observation.indigenousLanguages?.isEmpty ?? true) && (_readOnlyLanguages?.isNotEmpty ?? false)) {
                observation.indigenousLanguages = _encodeIndigenousEntries(_readOnlyLanguages!);
              }
            });
          } else {
            if (_formKey.currentState?.validate() == true) {
              _formKey.currentState?.save();

              if (widget.isTemplate) {
                //Persist the template values instead of uploading an observation
                final settingsService = Provider.of<SettingsService>(context, listen: false);
                await settingsService.setDefaultObservationTemplateJson(widget.observationViewModel.observation.toTemplateJson());
                showToast(translations.defaultObservationSaved);
                if (context.mounted) Navigator.pop(context);
                return;
              }

              setState((){
                _isUploading = true;
              });

              //Indicate that there are changes that are not uploaded when the updates are saved so that observations
              //can be saved in whatever their current state is without having to determine if the observation has been updated.
              widget.observationViewModel.observation.isUploaded = false;

              var observationsService = Provider.of<ObservationsService>(context, listen: false);
              final returnValue = await observationsService.saveObservation(widget.observationViewModel.observation, user);
              final message = returnValue?.message;
              if (message != null) {
                showToast(message);
              }

              setState((){
                _isUploading = false;
                _isEditMode = false;
              });
              _fetchIndigenousTerritoriesForViewing();
            } else {
              //The following isn't required because the form will show the error messages
              //showToast(translations.fillInAllFormFields);
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
    //The template stores no images, so don't let the user pick one from its page
    onTap: () => _isEditMode && !widget.isTemplate ? _openFileExplorer(true, FileType.image, [], true) : {},
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
          //The template stores no audio, so don't show its record button
          if (!widget.isTemplate) ... [
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: RawMaterialButton(
                  //padding: EdgeInsets.all(0.0),
                  //elevation: 12.0,
                  // The record/play button inside handles the tap; this only draws the white circle
                  onPressed: () {},
                  shape: const CircleBorder(),
                  fillColor: Colors.white,
                  child: _isEditMode ? _buildRecordButton() : _buildPlayButton(),
                ),
              ),
            ),
          ],
          /*Positioned( //TODO
            bottom: 10.0,
            left: 10.0,
            child: ThemedIconButton(
              Icons.add_location,
              iconSize: IconSize.MEDIUM,
              onPressedCallback: () => developoer.log('Allow user to manually select a geo point'),
            )
        ),*/
          if(_isEditMode) ... [
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
                            MaterialPageRoute(builder: (BuildContext context) => ObservationScreen(widget.observationViewModel))
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

  // Index 0 - this button always plays the first recording. It shares _playerState/_playingIndex/
  // _audioPlayer with the per-recording buttons in AudioContentScroll (_buildAudioRecordings)
  // so both stay in sync - they used to each own a separate player and separate state, which is why
  // pressing one didn't update the other's icon.
  Widget _buildPlayButton() => ThemedPlayButton(
    isPlaying: _playerState == AudioPlaybackState.play && _playingIndex == 0,
    pauseIcon: Icon(
        Icons.pause,
        color: context.watch<MaterialThemesManager>().colorPalette().secondary,
        size: 48),
    playIcon: Icon(Icons.play_arrow,
        color: context.watch<MaterialThemesManager>().colorPalette().secondary,
        size: 48),
    onPressed: () {
      var audioUrls = widget.observationViewModel.observation.audioUrls;
      if (audioUrls != null && audioUrls.isNotEmpty) {
        _playAudio(0);
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

  void _onAudioPlayerStateChanged(PlayerState state) {
    if (state.processingState == ProcessingState.completed) {
      _audioPlayer.stop();
      if (!mounted) return;
      setState(() {
        _playerState = AudioPlaybackState.stop;
        _playingIndex = -1;
      });
    }
  }

  void _playAudio(int index) async {
    var audioUrls = widget.observationViewModel.observation.audioUrls;
    if (audioUrls == null || index < 0 || index >= audioUrls.length) return;

    if (_playerState == AudioPlaybackState.stop || _playingIndex != index) {
      // One player is reused for every recording; stop() releases the previous source first
      await _audioPlayer.stop();

      var audioUrl = audioUrls[index];
      try {
        if (audioUrl.contains("http")) {
          // Downloaded once, then played from the phone
          await _audioPlayer.setFilePath((await MediaCache.file(audioUrl)).path);
        } else {
          await _audioPlayer.setFilePath(audioUrl);
        }
      } catch (e) {
        developer.log("Unable to load audio $audioUrl: $e");
        return;
      }

      if (!mounted) return;
      setState(() {
        _playingIndex = index;
        _playerState = AudioPlaybackState.play;
      });
      // Not awaited: play() only completes when playback pauses or ends
      _audioPlayer.play();

    } else if (_playerState == AudioPlaybackState.play) {
      await _audioPlayer.pause();
      if (!mounted) return;
      setState(() {
        _playerState = AudioPlaybackState.pause;
      });

    } else {
      if (!mounted) return;
      setState(() {
        _playerState = AudioPlaybackState.play;
      });
      _audioPlayer.play();
    }
  }

  // The first image is always the cover
  Widget _buildImage() {
    var imageUrls = widget.observationViewModel.observation.imageUrls ?? <String>[];
    //The template page doesn't allow adding images, so show a pika instead of the +image prompt
    var emptyAssetPath = widget.isTemplate ? "assets/images/pika3.jpg" : "assets/images/add_image.png";
    return UniversalImage(
      imageUrls.isEmpty ? emptyAssetPath : imageUrls[0],
      overlayMode: OverlayMode.never,
      height: 300.0,
    );
  }

  Widget _buildLatLonAltitude() {
    final observation = widget.observationViewModel.observation;
    String latitude = formatCoordinate(observation.latitude);
    String editLatitude = latitude;
    String longitude = formatCoordinate(observation.longitude);
    String editLongitude = longitude;

    double? altMeters = observation.altitudeInMeters;
    String altitudeDisplay = altMeters != null ? (_isMetric ? altMeters : metersToFeet(altMeters)).toStringAsFixed(2) : "";//Display altitude is shortened
    String editAltitudeDisplay = altitudeDisplay;    //Editable altitude is full length

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
                else if (_isEditMode) ...[
                  ThemedEditableLabelValue(
                    showLabel: false,
                    text: editLatitude,
                    textType: ThemeGroupType.POM,
                    hintText: "0.0",
                    onStringChangedCallback: (value) => _onManualCoordinateChanged(latitude: value),
                    validator: (value) => widget.isTemplate ? null : isValidGeo(value, translations.latitude),
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
                ] else if (_isEditMode) ...[
                  ThemedEditableLabelValue(
                    showLabel: false,
                    text: editLongitude,
                    textType: ThemeGroupType.POM,
                    hintText: "0.0",
                    onStringChangedCallback: (value) => _onManualCoordinateChanged(longitude: value),
                    validator: (value) => widget.isTemplate ? null : isValidGeo(value, translations.longitude),
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
                ThemedSubTitle(_isMetric ? translations.altitudeMetric : translations.altitude, type: ThemeGroupType.POM),
                tinyTransparentDivider,
                if (_hideGeoFields) ... [
                  //A hack state because geo fields not updating from self location button
                  //Don't add another ThemedEditableLabelValue here; it'll just create the same issue of not updating
                  ThemedTitle(altitudeDisplay, type: ThemeGroupType.MOM, emphasis: Emphasis.HIGH),
                ] else if (_isEditMode) ...[
                  ThemedEditableLabelValue(
                    showLabel: false,
                    text: editAltitudeDisplay,
                    textType: ThemeGroupType.POM,
                    hintText: "0.0",
                    onStringChangedCallback: (value) {
                      //tryParse so that clearing the field (or typing mid-edit garbage) clears the
                      //value instead of throwing; in normal mode the validator still requires a number
                      var altitude = double.tryParse(value);
                      widget.observationViewModel.observation.altitudeInMeters = altitude == null ? null : (_isMetric ? altitude : feetToMeters(altitude));
                    },
                    validator: (value) => widget.isTemplate ? null : isValidGeo(value, translations.altitude),
                  )
                ] else ...[
                  ThemedTitle(altitudeDisplay, type: ThemeGroupType.MOM, emphasis: Emphasis.HIGH),
                ]
              ],
            ),
          )
        )
      ],
    );
  }

  // Mirrors what happens after a GPS fix (_getCurrentPositionAndUpdateUi): once both latitude and
  // longitude are valid numbers, look up Indigenous territories/languages and optionally show the
  // Native Land map, same as the automatic flow. Debounced because onStringChangedCallback fires on
  // every keystroke and latitude/longitude are edited as two separate fields.
  void _onManualCoordinateChanged({String? latitude, String? longitude}) {
    final observation = widget.observationViewModel.observation;

    if (latitude != null) {
      if (latitude.trim().isEmpty) {
        //Clearing the field clears the value (e.g. removing a default from the observation template)
        observation.latitude = null;
        return;
      }
      final parsed = double.tryParse(latitude);
      if (parsed == null) return;
      observation.latitude = roundCoordinate(parsed);
    }

    if (longitude != null) {
      if (longitude.trim().isEmpty) {
        observation.longitude = null;
        return;
      }
      final parsed = double.tryParse(longitude);
      if (parsed == null) return;
      observation.longitude = roundCoordinate(parsed);
    }

    _manualCoordinatesLookupDebounce?.cancel();
    _manualCoordinatesLookupDebounce = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;

      final currentLatitude = observation.latitude;
      final currentLongitude = observation.longitude;
      if (currentLatitude == null || currentLongitude == null) return;

      _fetchAndSetIndigenousTerritories(currentLatitude, currentLongitude);
      _maybeShowNativeLandMapForGps(currentLatitude, currentLongitude);
    });
  }

  _getCurrentPositionAndUpdateUi() async {
    showToast(translations.fetchingLocation);

    await checkPermissionsAndGetCurrentPosition(translations)
      .then((Position position) async {
        String lat = formatCoordinate(position.latitude);
        String lon = formatCoordinate(position.longitude);
        String alt = position.altitude.toStringAsFixed(2);
        
        // Delay before showing location toast to avoid overlap
        await Future.delayed(const Duration(milliseconds: 1500));
        showToast("${translations.location}:\n$lat $lon $alt");

        setState(() {
          final observation = widget.observationViewModel.observation;
          observation.latitude = roundCoordinate(position.latitude);
          observation.longitude = roundCoordinate(position.longitude);
          observation.altitudeInMeters = position.altitude;

          _hideGeoFields = true;
          resetHideGeoFields();
        });

        // Fetch Indigenous territories for this location
        await _fetchAndSetIndigenousTerritories(position.latitude, position.longitude);

        // Show the Native Land map in-app when the user opted in and internet is available.
        await _maybeShowNativeLandMapForGps(position.latitude, position.longitude);
      })
      .catchError((e) {
        // Delay before showing error toast to avoid overlap
        Future.delayed(const Duration(milliseconds: 1500)).then((_) {
          showToast("$e");
        });
      });
  }

  _fetchAndSetIndigenousTerritories(double latitude, double longitude) async {
    try {
      final hasInternet = await isConnectedToNetwork();
      if (!hasInternet) {
        await Future.delayed(const Duration(milliseconds: 1500));
        showToast(translations.cannotRequestIndigenousTerritoriesOffline);
        return;
      }

      // Check if the API is available
      if (!NativeLandService.isAvailable) {
        await Future.delayed(const Duration(milliseconds: 1500));
        showToast('Indigenous territory lookup requires a Native Land API key.\nAdd NATIVE_LAND_API_KEY to your local .env file.');
        return;
      }
      
      // Delay before showing territory lookup toast
      await Future.delayed(const Duration(milliseconds: 1500));
      showToast(translations.lookingUpIndigenousTerritories ?? "Looking up Indigenous territories...");
      
      // Fetch both territories and languages
      final territories = await NativeLandService.getTerritoriesAt(
        latitude: latitude,
        longitude: longitude,
      );
      
      final languages = await NativeLandService.getLanguagesAt(
        latitude: latitude,
        longitude: longitude,
      );

      if (territories.isNotEmpty || languages.isNotEmpty) {
        setState(() {
          final observation = widget.observationViewModel.observation;
          observation.indigenousTerritories = _encodeIndigenousEntries(territories);
          observation.indigenousLanguages = _encodeIndigenousEntries(languages);
        });

        // Show toast with found territories and languages
        String territoryNames = territories
            .map((t) => t.name)
            .join(', ');
        String languageNames = languages
            .map((l) => l.name)
            .join(', ');
        
        String message = '';
        if (territoryNames.isNotEmpty) {
          message += translations.traditionalTerritoryOf.replaceAll('%s', territoryNames);
        }
        if (languageNames.isNotEmpty) {
          if (message.isNotEmpty) message += '\n';
          message += '${translations.indigenousLanguages ?? "Indigenous Languages"}: $languageNames';
        }
        
        if (message.isNotEmpty) {
          // Delay before showing territory results toast
          await Future.delayed(const Duration(milliseconds: 1500));
          showToast(message);
        }
      } else {
        // Delay before showing no territory found toast
        await Future.delayed(const Duration(milliseconds: 1500));
        showToast(translations.noIndigenousTerritoryFound ?? "No Indigenous territory data found for this location.");
      }
    } catch (e) {
      developer.log('Error fetching Indigenous territories: $e');
      // Delay before showing error toast
      await Future.delayed(const Duration(milliseconds: 1500));
      showToast('Error: ${translations.failedToFetchTerritoryData ?? "Failed to fetch territory data"}');
    }
  }

  // Looks up Indigenous territories/languages for a read-only observation view. Unlike
  // _fetchAndSetIndigenousTerritories (the edit-mode flow), this never mutates the observation
  // model and never shows a toast or the Native Land map - it just fetches quietly and updates
  // local state so _buildIndigenousTerritoryInfo can render the result.
  Future<void> _fetchIndigenousTerritoriesForViewing() async {
    final observation = widget.observationViewModel.observation;
    final latitude = observation.latitude;
    final longitude = observation.longitude;
    if (latitude == null || longitude == null) return;
    if (!NativeLandService.isAvailable) return;

    try {
      final hasInternet = await isConnectedToNetwork();
      if (!hasInternet) return;

      final territories = await NativeLandService.getTerritoriesAt(latitude: latitude, longitude: longitude);
      final languages = await NativeLandService.getLanguagesAt(latitude: latitude, longitude: longitude);

      if (!mounted) return;
      setState(() {
        _readOnlyTerritories = territories;
        _readOnlyLanguages = languages;
      });
    } catch (e) {
      developer.log('Error fetching Indigenous territories for viewing: $e');
    }
  }

  Future<void> _maybeShowNativeLandMapForGps(double latitude, double longitude) async {
    final settings = Provider.of<SettingsService>(context, listen: false);
    final showMap = await settings.getShowIndigenousMap();
    if (!showMap) return;

    final hasInternet = await isConnectedToNetwork();
    if (!hasInternet) return;

    if (!mounted) return;

    final firstSelection = _firstAvailableIndigenousSelection();
    if (firstSelection != null) {
      await _showNativeLandMapForSelection(
        selectionName: firstSelection.value,
        selectionCategory: firstSelection.key,
      );
      return;
    }

    _showNativeLandMapDialog(
      mapUrl: _buildFallbackNativeLandMapUrl(latitude: latitude, longitude: longitude),
      latitude: latitude,
      longitude: longitude,
    );
  }

  MapEntry<String, String>? _firstAvailableIndigenousSelection() {
    final observation = widget.observationViewModel.observation;
    final territories = observation.indigenousTerritories ?? <String>[];
    if (territories.isNotEmpty) {
      return MapEntry('territories', territories.first.split('|||').first);
    }

    final languages = observation.indigenousLanguages ?? <String>[];
    if (languages.isNotEmpty) {
      return MapEntry('languages', languages.first.split('|||').first);
    }

    return null;
  }

  String _buildNativeLandMapUrl({
    String? category,
    NativeLandMapSelection? selection,
  }) {
    final queryParameters = <String, String>{};

    if (category != null && _nativeLandMapToggleableCategories.contains(category)) {
      queryParameters['category'] = category;
    }
    if (selection != null) {
      queryParameters['bbox'] = selection.bboxQuery;
      queryParameters['center'] = selection.centerQuery;
    }

    if (queryParameters.isEmpty) {
      return _nativeLandMapUrl;
    }

    return Uri.parse(_nativeLandMapUrl).replace(queryParameters: queryParameters).toString();
  }

  String _buildFallbackNativeLandMapUrl({
    required double latitude,
    required double longitude,
  }) {
    const delta = 0.25;
    final bbox = [longitude - delta, latitude - delta, longitude + delta, latitude + delta];
    return Uri.parse(_nativeLandMapUrl).replace(queryParameters: {
      'bbox': jsonEncode(bbox),
      'center': '$longitude,$latitude',
    }).toString();
  }

  Future<void> _showNativeLandMapForSelection({
    required String selectionName,
    required String selectionCategory,
  }) async {
    final hasInternet = await isConnectedToNetwork();
    if (!hasInternet) {
      showToast('Internet connection is required to open the Native Land map.');
      return;
    }

    if (!mounted) return;
    final observation = widget.observationViewModel.observation;
    final resolvedSelection = await NativeLandService.resolveMapSelection(
      name: selectionName,
      category: selectionCategory,
    );

    final mapUrl = resolvedSelection != null
        ? _buildNativeLandMapUrl(
            category: selectionCategory,
            selection: resolvedSelection,
          )
        : (observation.latitude != null && observation.longitude != null)
            ? _buildFallbackNativeLandMapUrl(
                latitude: observation.latitude!,
                longitude: observation.longitude!,
              )
            : _buildNativeLandMapUrl(category: selectionCategory);

    _showNativeLandMapDialog(
      selectionName: selectionName,
      mapUrl: mapUrl,
      latitude: observation.latitude,
      longitude: observation.longitude,
    );
  }

  Future<void> _showNativeLandMapDialog({
    required String mapUrl,
    String? selectionName,
    double? latitude,
    double? longitude,
  }) async {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(mapUrl));

    final settings = Provider.of<SettingsService>(context, listen: false);
    var autoOpenMap = await settings.getShowIndigenousMap();
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Dialog(
              insetPadding: EdgeInsets.zero,
              clipBehavior: Clip.hardEdge,
              child: SafeArea(
                child: Column(
                  children: [
                    // Controls row above the map
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          if (latitude != null && longitude != null) ...[
                            const Icon(Icons.my_location, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                selectionName == null
                                    ? 'GPS: ${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}'
                                    : '$selectionName — GPS: ${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ] else
                            const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            tooltip: 'Close',
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Map fills the rest
                    Expanded(
                      child: WebViewWidget(controller: controller),
                    ),
                    const Divider(height: 1),
                    Container(
                      color: Colors.white,
                      child: CheckboxListTile(
                        dense: true,
                        activeColor: Colors.teal,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text('Automatically open map'),
                        value: autoOpenMap,
                        onChanged: (enabled) async {
                          final newValue = enabled ?? false;
                          setDialogState(() {
                            autoOpenMap = newValue;
                          });
                          await settings.setShowIndigenousMap(newValue);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  resetHideGeoFields() async {
    await Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _hideGeoFields = false;
      });
    });
  }

  // Whether the server has this version of the observation, so volunteers know their edits arrived
  Widget _buildUploadStatus() {
    final observation = widget.observationViewModel.observation;
    final uploadedAt = observation.dateUpdatedInGoogleSheets;
    final locale = Localizations.localeOf(context).toString();
    final text = !observation.isUploaded
        ? translations.observationWaitingToUpload
        : uploadedAt == null
            ? translations.observationOnServerNoDate
            : translations.observationOnServer.replaceAll('%s', DateFormat.yMMMd(locale).add_jm().format(uploadedAt.toLocal()));
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(observation.isUploaded ? Icons.cloud_done : Icons.access_time_filled, size: 18.0),
        const SizedBox(width: 6.0),
        Flexible(child: ThemedBody(text, type: ThemeGroupType.MOM)),
      ],
    );
  }

  Widget _buildHeader() {
    var date = widget.observationViewModel.observation.date;
    String month = date == null ? "" : DateFormat.MMMM(Localizations.localeOf(context).toString()).format(date);
    String day = date == null ? "" : date.day.toString();
    String year = date == null ? "" : date.year.toString();

    return Padding(
      padding: _horzPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          _buildLatLonAltitude(),
          smallTransparentDivider,
          if(_isEditMode) ... [
            ThemedEditableLabelValue(
              showLabel: false,
              text: widget.observationViewModel.observation.location ?? "",
              textType: ThemeGroupType.POM,
              hintText: translations.siteName,
              onStringChangedCallback: (value) => { widget.observationViewModel.observation.location = value },
              //The template is all optional - it only pre-fills new observations
              validator: (value) => widget.isTemplate ? null : nonEmptyValidator(value, translations.siteName, true),
            )
          ] else ... [
            ThemedH5(widget.observationViewModel.observation.location?.toUpperCase(), type: ThemeGroupType.POM, emphasis: Emphasis.HIGH),
            if (!widget.isTemplate && !widget.observationViewModel.observation.isNewObservation()) ... [
              smallTransparentDivider,
              _buildUploadStatus(),
            ],
          ],
          //TODO - smallTransparentDivider,
          //TODO - ThemedTitle('⭐ ⭐ ⭐ ⭐', type: ThemeGroupType.SOM),//TODO - hide until we allow jo
          smallTransparentDivider,
          Row(
            children: <Widget>[
              if(_isEditMode) ... [
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
              if(_isEditMode) ... [
                ThemedIconButton(
                    null,
                    iconSize: IconSize.MEDIUM,
                    onPressedCallback: () => { }
                ),
              ],
            ],
          ),
          smallTransparentDivider,
          _buildIndigenousTerritoryInfo(),
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

  // Entries stored on the observation are encoded as "name|||url" or just "name" for
  // backwards compatibility.
  MapEntry<String, String?> _decodeIndigenousEntry(String entry) {
    final parts = entry.split('|||');
    return MapEntry(parts[0], parts.length > 1 ? parts[1] : null);
  }

  MapEntry<String, String?> _indigenousEntryFromTerritory(Territory territory) {
    final url = territory.properties != null && territory.properties != territory.name
        ? territory.properties
        : null;
    return MapEntry(territory.name, url);
  }

  // Encodes territories/languages as "name|||url" (or just "name") to match the format
  // persisted on the observation and understood by _decodeIndigenousEntry.
  List<String> _encodeIndigenousEntries(List<Territory> entries) {
    return entries
        .map((e) => e.properties != null && e.properties != e.name ? '${e.name}|||${e.properties}' : e.name)
        .toList();
  }

  Widget _buildIndigenousTerritoryInfo() {
    final List<MapEntry<String, String?>> territoryEntries;
    final List<MapEntry<String, String?>> languageEntries;

    if (_isEditMode) {
      final observation = widget.observationViewModel.observation;
      territoryEntries = (observation.indigenousTerritories ?? <String>[]).map(_decodeIndigenousEntry).toList();
      languageEntries = (observation.indigenousLanguages ?? <String>[]).map(_decodeIndigenousEntry).toList();
    } else {
      territoryEntries = (_readOnlyTerritories ?? <Territory>[]).map(_indigenousEntryFromTerritory).toList();
      languageEntries = (_readOnlyLanguages ?? <Territory>[]).map(_indigenousEntryFromTerritory).toList();
    }

    if (territoryEntries.isEmpty && languageEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    Widget entryRow(MapEntry<String, String?> entry, IconData icon, String category) {
      final name = entry.key;
      final url = entry.value;

      final nameWidget = url != null
          ? GestureDetector(
              onTap: () async {
                final uri = Uri.tryParse(url);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Text(
                name,
                style: const TextStyle(
                  decoration: TextDecoration.underline,
                  color: Colors.grey,
                ),
              ),
            )
          : ThemedBody(name, type: ThemeGroupType.MOM);

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _showNativeLandMapForSelection(selectionName: name, selectionCategory: category),
              child: Icon(icon, size: 32, color: Colors.grey),
            ),
            const SizedBox(width: 10),
            Flexible(child: nameWidget),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (territoryEntries.isNotEmpty) ...[
          ThemedSubTitle(
            translations.indigenousTerritories ?? "Indigenous Territories",
            type: ThemeGroupType.POM,
          ),
          miniTransparentDivider,
          ThemedBody(
            translations.traditionalTerritoryOf.replaceAll('%s', territoryEntries.map((t) => t.key).join(', ')),
            type: ThemeGroupType.MOM,
          ),
          miniTransparentDivider,
          ...territoryEntries.map((t) => entryRow(t, Icons.map, 'territories')),
          if (languageEntries.isNotEmpty) smallTransparentDivider,
        ],
        if (languageEntries.isNotEmpty) ...[
          ThemedSubTitle(
            translations.indigenousLanguages ?? "Indigenous Languages",
            type: ThemeGroupType.POM,
          ),
          miniTransparentDivider,
          ...languageEntries.map((l) => entryRow(l, Icons.map, 'languages')),
        ],
        if (territoryEntries.isNotEmpty || languageEntries.isNotEmpty) ...[
          miniTransparentDivider,
          GestureDetector(
            onTap: () => launchUrl(Uri.parse("https://native-land.ca/about/how-it-works/"), mode: LaunchMode.externalApplication),
            child: Text(
              translations.nativeLandSource,
              style: const TextStyle(fontSize: 12, decoration: TextDecoration.underline, color: Colors.grey),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImages(Color color1, Color color2) {

    var icons = !_isEditMode ? <Widget>[] : [
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
      images: widget.observationViewModel.observation.imageUrls ?? <String>[],
      title: translations.images,
      emptyListMessage: translations.noImages,
      imageHeight: 200.0,
      imageWidth: 250.0,
      icons: icons,
      onDeleteClickedCallback: (value) => { _removeImage(value) },
      showDeleteButtonOnCard: _isEditMode
    );
  }

  // Removing a photo or recording can't be undone once the observation is saved, so ask first
  Future<bool> _confirmDeleteMedia(String title) async {
    final confirmed = await showConfirmDialog(
      context,
      title: title,
      description: translations.deleteMediaDialogDescription,
      confirmLabel: translations.delete,
      cancelLabel: translations.cancel,
    );
    return confirmed && mounted;
  }

  _removeImage(path) async {
    if (!await _confirmDeleteMedia(translations.deleteImageDialogTitle)) return;

    setState(() {
      //remove image from the observation
      widget.observationViewModel.observation.imageUrls?.remove(path);
      needsUpdated = true;
    });
  }

  Widget _buildAudioRecordings() {

    var icons = !_isEditMode ? <Widget>[] : [
      ThemedIconButton(Icons.audiotrack, onPressedCallback: () => _openFileExplorer(true, FileType.custom, ['3gp','aa','aac','aax','act','aiff','alac','amr','ape','au','awb','dss','dvf','flac','gsm','iklax','kvs','m4a','m4b','m4p','mmf','movpkg','mp3','mpc','msv','nmf','ogg','oga','mogg','opus','ra','rm','raw','rf64','sln','tta','voc','vox','wav','wma','wv','webm','8svx','cda'], false)),
      ThemedIconButton(Icons.mic, onPressedCallback: () => { _openAudioRecorder()})
    ];

    return AudioContentScroll(
      urls: widget.observationViewModel.observation.audioUrls ?? <String>[],
      title: translations.audioRecordings,
      emptyListMessage: translations.noAudioRecordings,
      imageHeight: 200.0,
      imageWidth: 250.0,
      icons: icons,
      playerState: _playerState,
      playingIndex: _playingIndex,
      onToggle: _playAudio,
      onDeleteClickedCallback: _removeAudio,
      showDeleteButtonOnCard: _isEditMode,
    );
  }

  void _removeAudio(String url) async {
    var audioUrls = widget.observationViewModel.observation.audioUrls;
    if (audioUrls == null) return;

    if (!await _confirmDeleteMedia(translations.deleteAudioDialogTitle)) return;

    // Stop playback first if this recording, or one after it, is selected: removing it shifts the indexes
    var index = audioUrls.indexOf(url);
    if (index >= 0 && _playingIndex >= index) {
      await _audioPlayer.stop();
    }
    if (!mounted) return;

    setState(() {
      if (index >= 0 && _playingIndex >= index) {
        _playerState = AudioPlaybackState.stop;
        _playingIndex = -1;
      }
      audioUrls.remove(url);
      needsUpdated = true;
    });
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
          widget.observationViewModel.observation.audioUrls?.add(value);
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
          if (widget.observationViewModel.observation.imageUrls?.contains(filePath) == true) {
            showToast(translations.didNotAddImage);
          } else {
            widget.observationViewModel.observation.imageUrls?.add(filePath);
          }
        } else if (widget.observationViewModel.observation.audioUrls?.contains(filePath) == true) {
          showToast(translations.didNotAddAudio);
        } else {
          widget.observationViewModel.observation.audioUrls?.add(filePath);
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

    List<PlatformFile> result = await FilePicker.pickFiles(
        type: pickingType,
        allowedExtensions: allowedExtensions,
        compressionQuality: pickingType == FileType.image ? photoQuality : 0
    );

    // Result is empty if user cancelled
    List<String> filePaths = result.map((file) => file.path).whereType<String>().toList();
    //List<File> files = filePaths.map((path) => File(path)).toList();

    /*if (mounted && filePaths.isNotEmpty) {
      developer.log("File paths:$filePaths");
    }*/

    _addMediaUrlsToObservations(filePaths, addImages);
  }

  Future<void> _pickSingleFile(FileType pickingType, List<String> allowedExtensions, bool addImages) async {

    PlatformFile? result = await FilePicker.pickFile(
        type: pickingType,
        allowedExtensions: allowedExtensions,
        compressionQuality: pickingType == FileType.image ? photoQuality : 0
    );

    // Result is null if user cancelled
    var filePath = result?.path ?? "";
    //File file = File(filePath);

    /*if (mounted && filePath.isNotEmpty) {
      developer.log("File path:$filePath name:${ filePath.split('/').last }");
    }*/

    if (filePath.isNotEmpty) {
      _addMediaUrlsToObservations([filePath], addImages);
    }
  }
  
  // No permission is asked for here. The system photo picker (Android) and PHPicker or document
  // picker (iOS) give the app only what the user selects, without any permission. Asking for
  // camera, Photos or media library access first used to stop the gallery from opening when any
  // was refused, including iPhone's "Select Photos" (limited) choice. GitHub #30.
  void _openFileExplorer(bool isMultiPick, FileType pickingType, List<String> allowedExtensions, bool addImages) async {
    try {
      if (isMultiPick) {
        await _pickMultipleFiles(pickingType, allowedExtensions, addImages);
      } else {
        await _pickSingleFile(pickingType, allowedExtensions, addImages);
      }
    } on PlatformException catch (e) {
      developer.log("${translations.unsupportedOperation}: $e");
    }
  }

  static const double maxPhotoDimension = 2560;
  static const int photoQuality = 85;

  Future<void> _savePhotoToGallery(String path) async {
    try {
      // Saving into an album needs full Photos access on iPhone; add-only access can't make albums
      if (!await Gal.hasAccess(toAlbum: true)) {
        await Gal.requestAccess(toAlbum: true);
      }
      await Gal.putImage(path, album: translations.appName);
    } catch (e) {
      // Saving to the gallery is a convenience; the photo is still added to the observation
      developer.log("Unable to save photo to gallery: $e");
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
      widget.observationViewModel.observation.imageUrls?.add(croppedPath ?? sourcePath);
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
    // Large phone photos are slow to upload and fill Firebase Storage, so cap the size
    XFile? selected = await imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: maxPhotoDimension,
      maxHeight: maxPhotoDimension,
      imageQuality: photoQuality,
    );

    var selectedPath = selected?.path;
    
    if (selectedPath == null) {
      showToast(translations.errorWhenTryingToTakePicture);
    } else {
      // Keep a copy in the phone's photo gallery so the volunteer never loses the picture
      _savePhotoToGallery(selectedPath);

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
    // Keep in a local: calling getSpeciesValues() inline listed American Pika twice
    var speciesValues = widget.observationViewModel.getSpeciesValues();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        smallTransparentDivider,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ThemedSubTitle(translations.species, type: ThemeGroupType.POM),
            /*if (_isEditMode)...[
            ThemedIconButton(Icons.add, onPressedCallback: () => _openAddOtherSpeciesDialog())
          ]*/
          ],
        ),
        ChipsChoice<String>.single(
          padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
          choiceStyle: _choiceChipStyle,
          choiceCheckmark: true,
          value: widget.observationViewModel.observation.species,
          onChanged: (value) => {
            if (_isEditMode) {
              setState(() => widget.observationViewModel.observation.species = value)
            }
          },
          choiceItems: C2Choice.listFrom<String, String>(
            source: speciesValues,
            value: (i, v) => v,
            label: (i, v) => widget.observationViewModel.getSpeciesLabel(i, v),
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
          widget.observationViewModel.observation.species = value.trim();
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
          choiceStyle: _choiceChipStyle,
          choiceCheckmark: true,
          value: widget.observationViewModel.observation.signs ?? <String>[],
          onChanged: (val) => {
            if (_isEditMode) {
              setState(() => widget.observationViewModel.observation.signs = val)
            }
          },
          choiceItems: C2Choice.listFrom<String, String>(
            source: widget.observationViewModel.getSignsValues(),
            value: (i, v) => v,
            label: (i, v) => widget.observationViewModel.getSignsLabel(i, v),
            tooltip: (i, v) => v,
          ),
        )
      ],
    );
  }

  Widget _buildCountChoices() {
    String? pikasDetected = widget.observationViewModel.observation.pikasDetected;
    bool pikasDetectedEmpty = pikasDetected != null && pikasDetected.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        smallTransparentDivider,
        ThemedSubTitle(translations.pikasDetected, type: ThemeGroupType.POM),
        ChipsChoice<String>.single(
            padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
            choiceStyle: _choiceChipStyle,
          choiceCheckmark: true,
            value: pikasDetectedEmpty ? null : pikasDetected,//empty shows empty bubble instead of nothing selected
            onChanged: (val) => {
              if (_isEditMode) {
                setState(() {
                  //If selected the same value as before, unset the value
                  widget.observationViewModel.observation.pikasDetected = widget.observationViewModel.observation.pikasDetected == val ? null : val;
                })
              }
            },
            choiceItems: C2Choice.listFrom<String, String>(
              source: widget.observationViewModel.getPikasDetectedValues(),
              value: (i, v) => v,
              label: (i, v) => widget.observationViewModel.getPikasDetectedLabel(i, v),
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
            choiceStyle: _choiceChipStyle,
          choiceCheckmark: true,
            value: widget.observationViewModel.observation.distanceToClosestPika,
            onChanged: (val) => {
              if (_isEditMode) {
                setState(() => widget.observationViewModel.observation.distanceToClosestPika = val)
              }
            },
            choiceItems: C2Choice.listFrom<String, String>(
              source: widget.observationViewModel.getDistanceToClosestPikaValues(),
              value: (i, v) => v,
              label: (i, v) => widget.observationViewModel.getDistanceToClosestPikaLabel(i, v, metric: _isMetric),
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
            choiceStyle: _choiceChipStyle,
          choiceCheckmark: true,
            value: widget.observationViewModel.observation.searchDuration,
            onChanged: (val) => {
              if (_isEditMode) {
                setState(() => widget.observationViewModel.observation.searchDuration = val)
              }
            },
            choiceItems: C2Choice.listFrom<String, String>(
              source: widget.observationViewModel.getSearchDurationValues(),
              value: (i, v) => v,
              label: (i, v) => widget.observationViewModel.getSearchDurationLabel(i, v),
              tooltip: (i, v) => v,
            )
        )
      ],
    );
  }

  bool showTalusAreaHints = false;//seeded from the persisted preference in build
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
                  //Persist so the choice sticks across observations and app restarts
                  Provider.of<SettingsService>(context, listen: false).setShowHints(boolVal);
                }
            )
          ],
        ),
        ChipsChoice<String>.single(
            padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
            choiceStyle: _choiceChipStyle,
          choiceCheckmark: true,
            value: widget.observationViewModel.observation.talusArea,
            onChanged: (val) => {
              if (_isEditMode) {
                setState(() => widget.observationViewModel.observation.talusArea = val)
              }
            },
            choiceItems: C2Choice.listFrom<String, String>(
              source: widget.observationViewModel.getTalusAreaValues(),
              value: (i, v) => v,
              label: (i, v) => widget.observationViewModel.getTalusAreaLabel(i, v, showTalusAreaHints, metric: _isMetric),
              tooltip: (i, v) => widget.observationViewModel.getTalusAreaLabel(i, v, showTalusAreaHints, metric: _isMetric),
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
          choiceStyle: _choiceChipStyle,
          choiceCheckmark: true,
          value: widget.observationViewModel.observation.temperature,
          onChanged: (val) => {
            if (_isEditMode) {
              setState(() => widget.observationViewModel.observation.temperature = val)
            }
          },
          choiceItems: C2Choice.listFrom<String, String>(
            source: widget.observationViewModel.getTemperatureValues(),
            value: (i, v) => v,
            label: (i, v) => widget.observationViewModel.getTemperatureLabel(i, v, metric: _isMetric),
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
        choiceStyle: _choiceChipStyle,
          choiceCheckmark: true,
        value: widget.observationViewModel.observation.skies,
        onChanged: (val) => {
          if (_isEditMode) {
            setState(() => widget.observationViewModel.observation.skies = val)
          }
        },
        choiceItems: C2Choice.listFrom<String, String>(
          source: widget.observationViewModel.getSkiesValues(),
          value: (i, v) => v,
          label: (i, v) => widget.observationViewModel.getSkiesLabel(i, v),
          tooltip: (i, v) => v
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
        choiceStyle: _choiceChipStyle,
          choiceCheckmark: true,
        value: widget.observationViewModel.observation.wind,
        onChanged: (val) => {
          if (_isEditMode) {
            setState(() => widget.observationViewModel.observation.wind = val)
          }
        },
        choiceItems: C2Choice.listFrom<String, String>(
          source: widget.observationViewModel.getWindValues(),
          value: (i, v) => v,
          label: (i, v) => widget.observationViewModel.getWindLabel(i, v),
          tooltip: (i, v) => v
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
          if (_isEditMode)...[
            ThemedIconButton(Icons.add, onPressedCallback: () => _openAddOtherAnimalsDialog())
          ]
        ],
      ),
      ChipsChoice<String>.multiple(
        padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
        choiceStyle: _choiceChipStyle,
          choiceCheckmark: true,
        value: widget.observationViewModel.observation.otherAnimalsPresent ?? <String>[],
        onChanged: (val) => {
          if (_isEditMode) {
            setState(() => widget.observationViewModel.observation.otherAnimalsPresent = val)
          }
        },
        choiceItems: C2Choice.listFrom<String, String>(
          source: widget.observationViewModel.getOtherAnimalsPresentValues(),
          value: (i, v) => v,
          label: (i, v) => widget.observationViewModel.getOtherAnimalsPresentLabel(i, v),
          tooltip: (i, v) => v
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
          var otherAnimalsPresent = widget.observationViewModel.observation.otherAnimalsPresent ?? <String>[];
          otherAnimalsPresent.addAll(value.split(","));
          otherAnimalsPresent = otherAnimalsPresent.map((string) => string.replaceAllMapped(RegExp(r'^\s+|\s+$'), (match) => "")).toSet().toList();
          widget.observationViewModel.observation.otherAnimalsPresent = otherAnimalsPresent;
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
      approvedOrganizations = ["Colorado Pika Project", "Cascades Pika Watch", "PikaNET (Mountain Studies Institute)", "Glacier National Park", "Mt. Rainier National Park", "Cascades Forest Conservancy", "Montana Pika Project", "Nevada Pika Atlas", "Canadian Pika Project", "Utah Pika Watch"];//"Pika Patrol", "Denver Zoo", "IF/THEN", , "Rocky Mountain Wild"
    }

    var observation = widget.observationViewModel.observation;

    var sharedWithProjects = observation.sharedWithProjects ?? [];
    var notSharedWithProjects = observation.notSharedWithProjects ?? [];

    for (var approvedOrganization in approvedOrganizations) {
      if (!sharedWithProjects.contains(approvedOrganization) && !notSharedWithProjects.contains(approvedOrganization)) {
          notSharedWithProjects.add(approvedOrganization);
      }
    }

    sharedWithProjects = sharedWithProjects.toTrimmedUniqueList().sortList();
    observation.sharedWithProjects = sharedWithProjects;

    notSharedWithProjects = notSharedWithProjects.toTrimmedUniqueList().sortList();
    observation.notSharedWithProjects = notSharedWithProjects;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        smallTransparentDivider,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ThemedSubTitle(translations.sharedWithProjects, type: ThemeGroupType.POM),
            // if (_isEditMode)...[
            //   ThemedIconButton(Icons.add, onPressedCallback: () => _openSharedWithProjectsDialog())
            // ]
          ],
        ),
        if(sharedWithProjects.isNotEmpty || notSharedWithProjects.isNotEmpty) ... [
          ChipsChoice<String>.multiple(
            padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
            choiceStyle: _choiceChipStyle,
          choiceCheckmark: true,
            value: widget.observationViewModel.observation.sharedWithProjects ?? <String>[],
            onChanged: (updatedSharedWithProjects) =>
            {
              if (_isEditMode) {
                setState((){
                  final observation = widget.observationViewModel.observation;
                  sharedWithProjects = updatedSharedWithProjects;

                  var approvedSet = approvedOrganizations.toSet();
                  var selectedSet = updatedSharedWithProjects.toSet();
                  observation.sharedWithProjects = selectedSet.toList();
                  observation.notSharedWithProjects = List.from(approvedSet.difference(selectedSet));
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
          final observation = widget.observationViewModel.observation;

          var sharedWithProjects = observation.sharedWithProjects ?? <String>[];
          sharedWithProjects.addAll(value.split(","));
          sharedWithProjects = sharedWithProjects.map((string) => string.replaceAllMapped(RegExp(r'^\s+|\s+$'), (match) => "")).toSet().toList();
          observation.sharedWithProjects = sharedWithProjects;
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
        if(_isEditMode) ... [
          ThemedEditableLabelValue(
            showLabel: false,
            text: widget.observationViewModel.observation.siteHistory ?? "",
            textType: ThemeGroupType.POM,
            hintText: translations.siteHistoryHint,
            //hintTextType: hintTextType,
            //hintTextEmphasis: hintTextEmphasis,
            //backgroundType: textFieldBackgroundType,
            onStringChangedCallback: (value) => { widget.observationViewModel.observation.siteHistory = value },
            //validator: validator
          )
        ] else ... [
          SizedBox(
            height: 120.0,
            child: SingleChildScrollView(
              child: ThemedBody(
                widget.observationViewModel.observation.siteHistory,
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
        if(_isEditMode) ... [
          ThemedEditableLabelValue(
            showLabel: false,
            text: widget.observationViewModel.observation.comments ?? "",
            textType: ThemeGroupType.POM,
            hintText: translations.anyAdditionalObservations,
            //hintTextType: hintTextType,
            //hintTextEmphasis: hintTextEmphasis,
            //backgroundType: textFieldBackgroundType,
            onStringChangedCallback: (value) => { widget.observationViewModel.observation.comments = value },
            //validator: validator
          )
        ] else ... [
          SizedBox(
            height: 120.0,
            child: SingleChildScrollView(
              child: ThemedBody(
                widget.observationViewModel.observation.comments,
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
      initialDate: widget.observationViewModel.observation.date ?? DateTime.now(),
      firstDate: DateTime.fromMicrosecondsSinceEpoch(0),
      lastDate: DateTime.now()
    );
    if (picked != null && picked != widget.observationViewModel.observation.date) {
      setState((){
        widget.observationViewModel.observation.date = picked;
      });
    }
  }

  Widget _buildDeleteButtonForForm(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
    child: Center(
      child: _buildDeleteButton(context, false)
    )
  );

  Widget _buildDeleteButton(BuildContext context, bool userConfirmedDelete) => ElevatedButton(
    onPressed: () async {
      _confirmAndDelete(context, userConfirmedDelete, true, true, true);
    },
    onLongPress: () async {
      _confirmAndDelete(context, userConfirmedDelete, true, false, false);
    },
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      backgroundColor: Colors.red,
      shape: const StadiumBorder(),
    ),
    child: ThemedTitle(translations.delete, type: ThemeGroupType.MOP),
  );

  _confirmAndDelete(BuildContext context, bool userConfirmedDelete, bool deleteLocal, bool deleteFromFirebase, bool deleteFromGoogleSheets) async {
    if (userConfirmedDelete) {
      final observationsService = Provider.of<ObservationsService>(context, listen: false);
      var exception = await observationsService.deleteObservation(context, widget.observationViewModel.observation, true, true, deleteLocal, deleteFromFirebase, deleteFromGoogleSheets);
      if (exception == null || exception.code == ERROR_REGISTER_NETWORK_CODE) {
        //Network exception is OK because the observation is deleted in cache and queued for deletion
        //from the server once the app is back online
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
      _showDeleteObservationVerificationDialog(context);
    }
  }

  Widget _buildCancelButton() => TextButton(
    child: Text(translations.cancel),
    onPressed: () async {
      Navigator.pop(context, true);
    },
  );

  _showDeleteObservationVerificationDialog(BuildContext context) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text(translations.deleteObservationDialogTitle),
          content: Text(translations.deleteObservationDialogDescription),
          actions: [
            _buildCancelButton(),
            _buildDeleteButton(context, true)
          ],
        )
      );
    }
  }
}