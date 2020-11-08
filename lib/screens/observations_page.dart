import 'package:flutter/material.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';
import 'package:provider/provider.dart';
import 'package:pika_joe/model/observation2.dart';
import 'package:pika_joe/widget/card_scroll.dart';
import 'dart:math' as math;

class ObservationsPage extends StatefulWidget {
  @override
  _ObservationsPageState createState() => _ObservationsPageState();
}

class _ObservationsPageState extends State<ObservationsPage> {

  double currentPage = 0;
  List<Observation2> observations = <Observation2>[];
  int lastObservationsSize = 0;

  @override
  Widget build(BuildContext context) {

    //if(observations == null || observations.isEmpty) {
      observations = Provider.of<List<Observation2>>(context) ?? <Observation2>[];
      if(lastObservationsSize != observations.length) {
        setState(() {
          currentPage = observations.isEmpty ? 0.0 : observations.length - 1.0;
          lastObservationsSize = observations.length;
        });
      }
    //}

    PageController controller = PageController(initialPage: currentPage.toInt());

    controller.addListener(() {
      setState(() {
        currentPage = controller.page;
      });
    });

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
                      ThemedH4("Observations", type: ThemeGroupType.MOP, emphasis: Emphasis.HIGH),
                      Stack(
                        children: <Widget>[
                          /*------------------ The visual cards overlapping one another -------------------------------------------------------*/
                          CardScrollWidget(observations, currentPage: currentPage),
                          /*------------------ Invisible pager the intercepts touches and passes paging input from user to visual cards ------- */
                          Positioned.fill(
                            child: PageView.builder(
                              itemCount: observations.length,
                              controller: controller,
                              reverse: true,
                              scrollDirection: Axis.horizontal,
                              allowImplicitScrolling: true,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () => print(""),
                                      /*Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MovieScreen(movie: movies[2]),
                                    ),
                                  )*/
                                  child: Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    color: Color.fromARGB(70, 255-index*25, 255-index*10, 255-index*50),
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
  }

}