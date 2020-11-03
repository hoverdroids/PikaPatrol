import 'package:flutter/material.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';
import 'package:pika_joe/mock/data.dart';
import 'package:pika_joe/widget/break_me_apart.dart';
import 'package:provider/provider.dart';
import 'package:pika_joe/model/observation2.dart';

class ObservationsPage extends StatefulWidget {
  @override
  _ObservationsPageState createState() => _ObservationsPageState();
}

class _ObservationsPageState extends State<ObservationsPage> {

  var currentPage = images.length - 1.0;

  @override
  Widget build(BuildContext context) {

    PageController controller = PageController(initialPage: images.length - 1);

    controller.addListener(() {
      setState(() {
        currentPage = controller.page;
      });
    });

    final observations = Provider.of<List<Observation2>>(context) ?? [];

    print("Observations:${observations.toString()}");

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
                          CardScrollWidget(currentPage),
                          /*------------------ Invisible pager the intercepts touches and passes paging input from user to visual cards ------- */
                          Positioned.fill(
                            child: PageView.builder(
                              itemCount: images.length,
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
                                    color: Color.fromRGBO(255, 255, 255, 0.00),
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