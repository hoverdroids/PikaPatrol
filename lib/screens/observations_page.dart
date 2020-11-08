import 'package:flutter/material.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';
import 'package:provider/provider.dart';
import 'package:pika_joe/model/observation2.dart';
import 'package:pika_joe/widget/card_scroll.dart';
import 'package:pika_joe/screens/observation_screen2.dart';

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