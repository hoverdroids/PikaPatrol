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
import 'package:pika_patrol/widgets/card_scroll.dart';
import 'package:provider/provider.dart';
import '../model/app_user.dart';
import '../utils/observation_utils.dart';
import 'observation_screen.dart';
import 'dart:developer' as developer;

// ignore: must_be_immutable
class ObservationsPage extends StatefulWidget {

  late List<Observation> observations;
  double currentPage = 0;

  ObservationsPage(List<Observation>? observations, {super.key}) {
    this.observations = observations == null ? <Observation>[] : List.from(observations.reversed);
    currentPage = this.observations.isEmpty ? 0.0 : this.observations.length - 1.0;
    developer.log("ObservationsPage ctor observations length:${observations?.length}");
  }

  @override
  ObservationsPageState createState() => ObservationsPageState();
}

class ObservationsPageState extends State<ObservationsPage> {

  int numberOldObservations = 0;

  late PageController sharedObservationsPageController;

  late PageController localObservationsPageController;
  List<Observation> localObservations = <Observation>[];
  double localObservationsCurrentPage = 0.0;

  bool localObservationsNeedUploaded() {
    return localObservations.isNotEmpty && localObservations.any((Observation observation) => observation.uid == null || observation.uid?.isEmpty == true);
  }

  @override
  void initState() {
    super.initState();
    sharedObservationsPageController = PageController(initialPage: widget.currentPage.toInt());
    sharedObservationsPageController.addListener(() {
      setState(() {
        if (widget.observations.length != numberOldObservations) {
          numberOldObservations = widget.observations.length;
          widget.currentPage = numberOldObservations - 1.0;
          sharedObservationsPageController.jumpTo(widget.currentPage);

        } else {
          widget.currentPage = sharedObservationsPageController.page ?? widget.currentPage;
        }
      });
    });

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
              altitude: localObservation.altitude,
              longitude: localObservation.longitude,
              latitude: localObservation.latitude,
              name: localObservation.name,
              location: localObservation.location,
              date: DateTime.parse(localObservation.date),
              signs: localObservation.signs,
              pikasDetected: localObservation.pikasDetected,
              distanceToClosestPika: localObservation.distanceToClosestPika,
              searchDuration: localObservation.searchDuration,
              talusArea: localObservation.talusArea,
              temperature: localObservation.temperature,
              skies: localObservation.skies,
              wind: localObservation.wind,
              otherAnimalsPresent: localObservation.otherAnimalsPresent,
              siteHistory: localObservation.siteHistory,
              comments: localObservation.comments,
              imageUrls: localObservation.imageUrls,
              audioUrls: localObservation.audioUrls
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
                          ThemedH4("Observations", type: ThemeGroupType.MOP, emphasis: Emphasis.HIGH),
                          Stack(
                            children: <Widget>[
                              /*------------------ The visual cards overlapping one another -------------------------------------------------------*/
                              CardScrollWidget(widget.observations, currentCardPosition: widget.currentPage),
                              /*------------------ Invisible pager the intercepts touches and passes paging input from user to visual cards ------- */

                              Positioned.fill(
                                child: PageView.builder(
                                  itemCount: widget.observations.length,
                                  controller: sharedObservationsPageController,
                                  reverse: true,
                                  scrollDirection: Axis.horizontal,
                                  allowImplicitScrolling: true,
                                  itemBuilder: (context, index) {
                                    return GestureDetector(
                                      onTap: () => {
                                        Navigator.push(context,
                                          MaterialPageRoute(
                                            builder: (_) => ObservationScreen(widget.observations[index]),
                                          ),
                                        )
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        height: double.infinity,
                                        color: Color.fromARGB(1, 255-index*25, 255-index*10, 255-index*50),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
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
                              ]
                            ],
                          ),
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

}