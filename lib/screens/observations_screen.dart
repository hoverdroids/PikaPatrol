// ignore_for_file: depend_on_referenced_packages
import 'package:data_connection_checker_nulls/data_connection_checker_nulls.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/fundamental/icons.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';
import 'package:material_themes_widgets/utils/ui_utils.dart';
import 'package:pika_patrol/model/local_observation.dart';
import 'package:pika_patrol/model/observation.dart';
import 'package:provider/provider.dart';
import '../model/app_user.dart';
import '../primitives/card_layout.dart';
import '../utils/observation_utils.dart';
import '../widgets/card_scroller.dart';
import 'observation_screen.dart';
import 'dart:developer' as developer;

// ignore: must_be_immutable
class ObservationsPage extends StatefulWidget {

  late List<Observation> observations;
  late bool observationsNotNull;

  ObservationsPage(List<Observation>? observations, {super.key}) {
    List<Observation> resolvedObservations = observations ?? <Observation>[];
    this.observations = List.from(resolvedObservations.reversed);
    developer.log("ObservationsPage ctor observations length:${observations?.length}");
  }

  @override
  ObservationsPageState createState() => ObservationsPageState();
}

class ObservationsPageState extends State<ObservationsPage> {

  late PageController localObservationsPageController;
  List<Observation> localObservations = <Observation>[];
  double localObservationsCurrentPage = 0.0;

  bool localObservationsNeedUploaded() {
    return localObservations.isNotEmpty && localObservations.any((Observation observation) => observation.uid == null || observation.uid?.isEmpty == true);
  }

  @override
  void initState() {
    super.initState();
    localObservationsPageController = PageController(initialPage: localObservationsCurrentPage.toInt());
    localObservationsPageController.addListener(() {
      setState(() {
        localObservationsCurrentPage = localObservationsPageController.page ?? localObservationsCurrentPage;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<LocalObservation>('observations').listenable(),
      builder: (context, box, widget2){

        //Get all locally saved observations
        Map<dynamic, dynamic> raw = box.toMap();
        List list = raw.values.toList();
        localObservations = <Observation>[];
        for (var element in list) {
          LocalObservation localObservation = element;
          var observation = Observation(
              dbId: localObservation.key,
              uid: localObservation.uid,
              observerUid: localObservation.observerUid,
              name: localObservation.name,
              location: localObservation.location,
              date: DateTime.parse(localObservation.date),
              altitudeInMeters: localObservation.altitudeInMeters,
              latitude: localObservation.latitude,
              longitude: localObservation.longitude,
              species: localObservation.species,
              signs: localObservation.signs,
              pikasDetected: localObservation.pikasDetected,
              distanceToClosestPika: localObservation.distanceToClosestPika,
              searchDuration: localObservation.searchDuration,
              talusArea: localObservation.talusArea,
              temperature: localObservation.temperature,
              skies: localObservation.skies,
              wind: localObservation.wind,
              siteHistory: localObservation.siteHistory,
              comments: localObservation.comments,
              imageUrls: localObservation.imageUrls,
              audioUrls: localObservation.audioUrls,
              otherAnimalsPresent: localObservation.otherAnimalsPresent,
          );
          localObservations.add(observation);
        }

        var user = Provider.of<AppUser?>(context);

        //developer.log("widget.currentPage ${widget.currentPage}");

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
                          ThemedH4("Shared", type: ThemeGroupType.MOP, emphasis: Emphasis.HIGH),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ThemedH4("Observations", type: ThemeGroupType.MOP, emphasis: Emphasis.HIGH),
                              ThemedIconButton(
                                Icons.info,
                                type: ThemeGroupType.MOP,
                                onPressedCallback: () async {
                                  AlertDialog alert = const AlertDialog(
                                    title: Text("Shared Observations"),
                                    content: Text("The five most recent observations uploaded to Pika Patrol's server by any user."),
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
                          if (widget.observations.isNotEmpty) ... [
                            CardScroller(
                                widget.observations,
                                onTapCard: (index) => {
                                  Navigator.push( context,
                                    MaterialPageRoute(
                                      builder: (_) => ObservationScreen(widget.observations[index]),
                                    ),
                                  )
                                }
                            ),
                          ] else ...[
                            CardScroller(_createDefaultObservations()),
                          ],
                          ThemedH4("Cached", type: ThemeGroupType.MOP, emphasis: Emphasis.HIGH),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ThemedH4("Observations", type: ThemeGroupType.MOP, emphasis: Emphasis.HIGH),
                              if(user != null && localObservationsNeedUploaded()) ... [
                                ThemedIconButton(
                                    Icons.upload_file,
                                    type: ThemeGroupType.MOP,
                                    onPressedCallback: () async {
                                      var hasConnection = await DataConnectionChecker().hasConnection;
                                      if(hasConnection && context.mounted) {
                                        showToast("Uploading observations");

                                        for (var observation in localObservations) {
                                          //TODO - CHRIS - if the user updated an observation when offline,
                                          //the UID won't be null or empty, so those updates will never get pushed
                                          //in the bulk upload. This will get fixed when we compare current observations
                                          //vs the stored observation.
                                          var uid = observation.uid;
                                          if (uid == null || uid.isEmpty) {
                                            saveObservation(user, observation);
                                          }
                                        }
                                      } else {
                                        showToast("Could not upload observations. No data connection.");
                                      }
                                    }
                                )
                              ],
                              ThemedIconButton(
                                Icons.info,
                                type: ThemeGroupType.MOP,
                                onPressedCallback: () async {
                                  AlertDialog alert = const AlertDialog(
                                    title: Text("Cached Observations"),
                                    content: Text("Cached observations are those created on the current device. Clearing cache, deleting app data, or removing the app will permanently remove these observations from the device. If the observations were uploaded to the Pika Patrol server (i.e. there is a cloud icon in the top left of the card), then the observations will remain on the server but will not be pulled back onto the device."),
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
                          if (localObservations.isNotEmpty) ... [
                            CardScroller(
                              localObservations,
                              onTapCard: (index) => {
                                Navigator.push( context,
                                  MaterialPageRoute(
                                    builder: (_) => ObservationScreen(localObservations[index]),
                                  ),
                                )
                              }
                            ),
                          ] else ...[
                            CardScroller(_createDefaultObservations()),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
        );
      },
    );
  }

  List<Observation> _createDefaultObservations() => [
    Observation(name:"No Observations Found", buttonText: null, notUploadedIcon: null, cardLayout: CardLayout.centered)
  ];
}