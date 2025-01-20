// ignore_for_file: depend_on_referenced_packages
import 'dart:async';

import 'package:data_connection_checker_nulls/data_connection_checker_nulls.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/dialogs/text_entry_dialog.dart';
import 'package:material_themes_widgets/fundamental/icons.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';
import 'package:material_themes_widgets/utils/ui_utils.dart';
import 'package:pika_patrol/model/local_observation.dart';
import 'package:pika_patrol/model/observation.dart';
import 'package:provider/provider.dart';
import '../l10n/translations.dart';
import '../model/app_user.dart';
import '../primitives/card_layout.dart';
import '../services/firebase_database_service.dart';
import '../services/firebase_observations_service.dart';
import '../services/settings_service.dart';
import '../services/shared_observations_service.dart';
import '../utils/observation_utils.dart';
import '../widgets/card_scroller.dart';
import 'observation_screen.dart';

// ignore: must_be_immutable
class ObservationsPage extends StatefulWidget {

  const ObservationsPage({super.key});

  @override
  ObservationsPageState createState() => ObservationsPageState();
}

class ObservationsPageState extends State<ObservationsPage> {

  late Translations translations;

  /*final Key _sharedObservationsScrollerKey = UniqueKey();
  final Key _emptySharedObservationsScrollerKey = UniqueKey();*/

  final Key _localObservationsScrollerKey = UniqueKey();
  final Key _emptyLocalObservationsScrollerKey = UniqueKey();

  bool _isLocalObservationsDialogShowing = false;

  bool localObservationsNeedUploaded() {

    return false;//localObservations.isNotEmpty && localObservations.any((Observation observation) => !observation.isUploaded);
  }

  late StreamSubscription<DataConnectionStatus> _dataConnectionStatusListener;

  @override
  void initState() {
    super.initState();

    // actively listen for status updates
    // this will cause DataConnectionChecker to check periodically
    // with the interval specified in DataConnectionChecker().checkInterval
    // until listener.cancel() is called
    _dataConnectionStatusListener = DataConnectionChecker().onStatusChange.listen((status) {
      switch (status) {
        case DataConnectionStatus.connected:
          _onDataConnectionConnected();
          break;
        case DataConnectionStatus.disconnected:
          //TODO - CHRIS - instead of checking for network availability when making an observation, we should just have a service that streams this value
          break;
      }
    });

  }

  @override
  void dispose() {
    _dataConnectionStatusListener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    translations = Provider.of<Translations>(context);

    return SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: <Widget>[
            context.watch<MaterialThemesManager>().getBackgroundGradient(BackgroundGradientType.PRIMARY),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      ThemedH4(translations.sharedObservationsLine1, type: ThemeGroupType.MOP, emphasis: Emphasis.HIGH),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ThemedH4(translations.sharedObservationsLine2, type: ThemeGroupType.MOP, emphasis: Emphasis.HIGH),
                          ThemedIconButton(
                            Icons.info,
                            type: ThemeGroupType.MOP,
                            onPressedCallback: () async {
                              AlertDialog alert = AlertDialog(
                                title: Text(translations.sharedObservationsDialogTitle),
                                content: Text(translations.sharedObservationsDialogDetails),
                              );
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return alert;
                                },
                              );
                            }
                          )
                        ],
                      ),
                      /*StreamBuilder<List<Observation>>(
                        stream: Provider.of<SharedObservationsService>(context).sharedObservations,
                        builder: (context, snapshot) {
                          List<Observation> observations = snapshot.hasData ? (snapshot.data ?? <Observation>[]) : <Observation>[];
                          observations = observations.reversed.toList();

                          for (var observation in  observations) {
                            observation.buttonText = translations.viewObservation;
                          }

                          if (observations.isNotEmpty) {
                            return CardScroller(
                              observations,
                              key: _sharedObservationsScrollerKey,
                              onTapCard: (index) => {
                                Navigator.push( context,
                                  MaterialPageRoute(
                                    builder: (_) => ObservationScreen(observations[index].copy()),
                                  ),
                                )
                              }
                            );
                          }

                          return CardScroller(
                            _createDefaultObservations(),
                            key: _emptySharedObservationsScrollerKey,
                          );
                        },
                      ),*/
                      ThemedH4(translations.cachedObservationsLine1, type: ThemeGroupType.MOP, emphasis: Emphasis.HIGH),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ThemedH4(translations.cachedObservationsLine2, type: ThemeGroupType.MOP, emphasis: Emphasis.HIGH),
                          /*if(needUploaded) ... [
                            ThemedIconButton(
                                Icons.upload_file,
                                type: ThemeGroupType.MOP,
                                onPressedCallback: () async {
                                  await _uploadLocalObservations(appUser);
                                }
                            )
                          ],*/
                          ThemedIconButton(
                            Icons.info,
                            type: ThemeGroupType.MOP,
                            onPressedCallback: () async {
                              AlertDialog alert = AlertDialog(
                                title: Text(translations.cachedObservationsDialogTitle),
                                content: Text(translations.cachedObservationsDialogDetails),
                              );
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return alert;
                                },
                              );
                            }
                          )
                        ],
                      ),
                      StreamBuilder<List<Observation>>(
                        stream: Provider.of<SharedObservationsService>(context).localObservationsStream,
                        builder: (context, snapshot) {
                          List<Observation> localObservations = snapshot.hasData ? (snapshot.data ?? <Observation>[]) : <Observation>[];

                          if (localObservations.isNotEmpty) {
                            return CardScroller(
                                localObservations,
                                key: Key(localObservations.hashCode.toString()),//using hash for key so that build is called and stack is correctly displayed after observations change
                                onTapCard: (index) => {
                                  Navigator.push( context,
                                    MaterialPageRoute(
                                      builder: (_) => ObservationScreen(localObservations[index].copy()),
                                    ),
                                  )
                                }
                            );
                          }

                          return CardScroller(
                            _createDefaultObservations(),
                            key: _emptyLocalObservationsScrollerKey,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        )
    );
  }

  List<Observation> _createDefaultObservations() => [
    Observation(location:translations.noObservationsFound, buttonText: null, notUploadedIcon: null, cardLayout: CardLayout.centered)
  ];

  void _openLocalObservationsNeedUploadedDialog(BuildContext context, AppUser user) async {

    if (!context.mounted || _isLocalObservationsDialogShowing) return;

    _isLocalObservationsDialogShowing = true;

    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text(translations.localObservationsNeedUploadedDialogTitle),
          content: Text(translations.localObservationsNeedUploadedDialogDescription),
          actions: [
            TextButton(
              child: Text(translations.cancel),
              onPressed: () async {
                await _closeLocalObservationsNeedUploadedDialog(context, false, user);
              },
            ),
            ElevatedButton(
              onPressed: () async {
                await _closeLocalObservationsNeedUploadedDialog(context, true, user);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                backgroundColor: context.watch<MaterialThemesManager>().colorPalette().primary,
                shape: const StadiumBorder(),
              ),
              child: ThemedTitle(translations.ok, type: ThemeGroupType.MOP),
            )
          ],
        )
    );
  }

  Future _closeLocalObservationsNeedUploadedDialog(BuildContext context, bool uploadLocalObservationsNow, AppUser user) async {
    Navigator.pop(context, true);
    _isLocalObservationsDialogShowing = false;

    if (uploadLocalObservationsNow) {
      await _uploadLocalObservations(user);
    }
  }

  Future _uploadLocalObservations(AppUser user) async {
    /*var hasConnection = await DataConnectionChecker().hasConnection;
    if(hasConnection && context.mounted) {
      showToast(translations.uploadingObservations);

      for (var observation in localObservations) {
          //If the observation was made when the user was not logged in, then edited after logging in, the user
          //id can be null. So update it now. This allows local observations to be uploaded when online.
          // However, if it's not null, then an admin could be editing it; so, don't override the original owner's ID
          observation.observerUid = user.uid ?? observation.observerUid;
          saveObservation(context, observation);
      }
    } else {
      showToast(translations.couldNotUploadObservationsNoDataConnection);
    }*/
  }


  _onDataConnectionConnected() {
    if (mounted) {
      var user = Provider.of<AppUser?>(context, listen: false);
      var needUploaded = user != null && localObservationsNeedUploaded();
      if (needUploaded) {
        Future.delayed(Duration.zero, () => _openLocalObservationsNeedUploadedDialog(context, user));
      }
    }
  }
}