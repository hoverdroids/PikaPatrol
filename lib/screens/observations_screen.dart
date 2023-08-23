// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';
import 'package:pika_patrol/model/local_observation.dart';
import 'package:pika_patrol/model/observation.dart';
import 'package:pika_patrol/widgets/card_scroll.dart';
import 'package:provider/provider.dart';
import 'observation_screen.dart';
import 'dart:developer' as developer;

// ignore: must_be_immutable
class ObservationsPage extends StatefulWidget {

  late List<Observation> observations;
  double currentPage = 0;

  ObservationsPage(List<Observation>? observations, {super.key}) {
    this.observations = observations == null ? <Observation>[] : List.from(observations.reversed);
    currentPage = this.observations.isEmpty ? 0.0 : this.observations.length - 1.0;
    developer.log("CurrentPage:$currentPage");
  }

  @override
  ObservationsPageState createState() => ObservationsPageState();
}

class ObservationsPageState extends State<ObservationsPage> {

  List<Observation> localObservations = <Observation>[];
  double localObservationsCurrentPage = 0.0;

  @override
  Widget build(BuildContext context) {

    //TODO - for some reason this page number is zero instead of the latest page nuber
    developer.log("Current Page ${widget.currentPage} init");
    PageController controller = PageController(initialPage: widget.currentPage.toInt());

    controller.addListener(() {
      setState(() {
        widget.currentPage = controller.page ?? 0;
      });
    });

    PageController localObservationsController = PageController(initialPage: localObservationsCurrentPage.toInt());

    localObservationsController.addListener(() {
      setState(() {
        localObservationsCurrentPage = localObservationsController.page ?? 0;
      });
    });

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
                          ThemedH4("Shared Observations", type: ThemeGroupType.MOP, emphasis: Emphasis.HIGH),
                          Stack(
                            children: <Widget>[
                              /*------------------ The visual cards overlapping one another -------------------------------------------------------*/
                              CardScrollWidget(widget.observations, currentPage: widget.currentPage),
                              /*------------------ Invisible pager the intercepts touches and passes paging input from user to visual cards ------- */
                              Positioned.fill(
                                child: PageView.builder(
                                  itemCount: widget.observations.length,
                                  controller: controller,
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ThemedH4("Your Observations", type: ThemeGroupType.MOP, emphasis: Emphasis.HIGH),
                              //TODO - upload all local observations at once
                              /*if(localObservations.isNotEmpty) ... [
                                ThemedIconButton(
                                    Icons.upload_file,
                                    type: ThemeGroupType.MOP,
                                    onPressedCallback: () async {
                                      var hasConnection = await DataConnectionChecker().hasConnection;
                                      if(hasConnection) {
                                        showToast("Uploading observations");
                                      } else {
                                        showToast("Could not upload observations. No data connection.");
                                      }
                                    }
                                )
                              ]*/
                            ],
                          ),
                          Stack(
                            children: <Widget>[
                              /*------------------ The visual cards overlapping one another -------------------------------------------------------*/
                              CardScrollWidget(localObservations, currentPage: localObservationsCurrentPage),
                              /*------------------ Invisible pager the intercepts touches and passes paging input from user to visual cards ------- */
                              Positioned.fill(
                                child: PageView.builder(
                                  itemCount: localObservations.length,
                                  controller: localObservationsController,
                                  reverse: true,
                                  scrollDirection: Axis.horizontal,
                                  allowImplicitScrolling: true,
                                  itemBuilder: (context, index) {
                                    return GestureDetector(
                                      onTap: () => {
                                        /*Navigator.push(context,
                                          MaterialPageRoute(
                                            builder: (_) => ObservationScreen(localObservations[index]),
                                          ),
                                        )*/
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