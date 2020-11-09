import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/fundamental/icons.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';
import 'package:pika_joe/model/local_observation.dart';
import 'package:provider/provider.dart';
import 'package:pika_joe/model/observation2.dart';
import 'package:pika_joe/widget/card_scroll.dart';
import 'package:pika_joe/screens/observation_screen2.dart';
import 'package:data_connection_checker/data_connection_checker.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ObservationsPage extends StatefulWidget {

  List<Observation2> observations;
  double currentPage;

  ObservationsPage(this.observations) {
    observations = observations == null ? <Observation2>[] : observations;
    currentPage = observations.isEmpty ? 0.0 : observations.length - 1.0;
    print("CurrentPage:$currentPage");
  }

  @override
  _ObservationsPageState createState() => _ObservationsPageState();
}

class _ObservationsPageState extends State<ObservationsPage> {

  @override
  Widget build(BuildContext context) {

    //TODO - for some reason this page number is zero instead of the latest page nuber
    print("Current Page ${widget.currentPage} init");
    PageController controller = PageController(initialPage: widget.currentPage.toInt());

    controller.addListener(() {
      print("Current Page ${controller.page} addList");
      setState(() {
        widget.currentPage = controller.page;
      });
    });

    return ValueListenableBuilder(
      valueListenable: Hive.box<LocalObservation>('observations').listenable(),
      builder: (context, box, widget2){

        //Get all locally saved observations
        Map<dynamic, dynamic> raw = box.toMap();
        List list = raw.values.toList();
        List observationsList = <Observation2>[];
        list.forEach((element) {
          LocalObservation localObservation = element;
          var observation = Observation2(
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
          observationsList.add(observation);
          print("Observation:${observation.toString()}");
        });

        print("LocalObservations:${observationsList.toString()}");

        return Container(
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              children: <Widget>[
                context.watch<MaterialThemesManager>().getBackgroundGradient(BackgroundGradientType.PRIMARY),
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ThemedH4("Observations", type: ThemeGroupType.MOP, emphasis: Emphasis.HIGH),
                              if(observationsList.isNotEmpty) ... [
                                ThemedIconButton(
                                    Icons.upload_file,
                                    type: ThemeGroupType.MOP,
                                    onPressedCallback: () async {
                                      var hasConnection = await DataConnectionChecker().hasConnection;
                                      if(hasConnection) {
                                        Fluttertoast.showToast(
                                            msg: "Uploading observations",
                                            toastLength: Toast.LENGTH_SHORT,
                                            gravity: ToastGravity.CENTER,
                                            timeInSecForIosWeb: 1,
                                            backgroundColor: Colors.teal,//TODO - need to use Toast with context to link to the primary color
                                            textColor: Colors.white,
                                            fontSize: 16.0
                                        );
                                      } else {
                                        Fluttertoast.showToast(
                                            msg: "Could not upload observations. No data connection.",
                                            toastLength: Toast.LENGTH_SHORT,
                                            gravity: ToastGravity.CENTER,
                                            timeInSecForIosWeb: 1,
                                            backgroundColor: Colors.teal,//TODO - need to use Toast with context to link to the primary color
                                            textColor: Colors.white,
                                            fontSize: 16.0
                                        );
                                      }
                                    }
                                )
                              ]
                            ],
                          ),
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
                                            builder: (_) => ObservationScreen2(widget.observations[index]),
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