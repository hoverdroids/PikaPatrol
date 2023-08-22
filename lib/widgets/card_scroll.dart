// ignore_for_file: depend_on_referenced_packages
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:material_themes_widgets/fundamental/icons.dart';
import 'package:pika_patrol/model/observation.dart';
import 'package:pika_patrol/widgets/universal_image.dart';
import 'custom_pan_gesture_recognizer.dart';
import 'package:material_themes_manager/material_themes_manager.dart';

// ignore: must_be_immutable
class CardScrollWidget extends StatelessWidget {

  List<Observation> observations = <Observation>[];
  late double cardAspectRatio;
  late double widgetAspectRatio;

  var currentPage = 0.0;
  var padding = 20.0;
  var verticalInset = 20.0;

  CardScrollWidget(this.observations, {super.key, this.currentPage = 0.0}){
    cardAspectRatio = 12.0 / 16.0;
    widgetAspectRatio = cardAspectRatio * 1.2;
  }

  @override
  Widget build(BuildContext context) {
    return observations.isEmpty ? _buildEmptyCards() : _buildCards();
  }

  Widget _buildCards() {
    return AspectRatio(
      aspectRatio: widgetAspectRatio,
      child: LayoutBuilder(builder: (context, constraints) {
        var width = constraints.maxWidth;
        var height = constraints.maxHeight;

        var safeWidth = width - 2 * padding;
        var safeHeight = height - 2 * padding;

        var heightOfPrimaryCard = safeHeight;
        var widthOfPrimaryCard = heightOfPrimaryCard * cardAspectRatio;

        var primaryCardLeft = safeWidth - widthOfPrimaryCard;
        var horizontalInset = primaryCardLeft / 2;

        List<Widget> cardList = <Widget>[];

        onPanDown(DragUpdateDetails details) {
          // print('Pan Down');
        }

        onPanUpdate(DragUpdateDetails details) {
          // print('Pan Update');
        }

        onPanEnd(_) {
          // print('Pan End');
          return true;
        }

        for (var i = 0; i < observations.length; i++) {
          var delta = i - currentPage;
          bool isOnRight = delta > 0;

          var start = padding +
              max(
                  primaryCardLeft -
                      horizontalInset * -delta * (isOnRight ? 15 : 1),
                  0.0);

          var cardItem = Positioned.directional(
            top: padding + verticalInset * max(-delta, 0.0),
            bottom: padding + verticalInset * max(-delta, 0.0),
            start: start,
            textDirection: TextDirection.rtl,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: Container(
                decoration: const BoxDecoration(color: Colors.white, boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      offset: Offset(3.0, 6.0),
                      blurRadius: 10.0)
                ]),
                child: AspectRatio(
                  aspectRatio: cardAspectRatio,
                  child: GestureDetector(
                    onTap: () => print('Bummer'),
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        if (observations[i].imageUrls?.isNotEmpty == true) ... [
                          //TODO - CHRIS - was passing null; need to pass local image path so cards still show with blank bg
                          UniversalImage(observations[i].imageUrls?.elementAt(0) ?? ""),
                        ],
                        if (observations[i].uid?.isNotEmpty == true) ... [
                          Align(
                              alignment: Alignment.topLeft,
                              child: ThemedIconButton(Icons.cloud_upload, type: ThemeGroupType.MOI, onPressedCallback: () => {}),
                          ),
                        ] else ... [
                          Align(
                              alignment: Alignment.topLeft,
                              child: ThemedIconButton(Icons.access_time_filled, type: ThemeGroupType.MOI, onPressedCallback: () => {}),
                          ),
                        ],
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0),
                                child: Text(observations[i].name ?? "BAD NAME",//
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 25.0,
                                        fontFamily: "SF-Pro-Text-Regular")),
                              ),
                              const SizedBox(
                                height: 10.0,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 12.0, bottom: 12.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 22.0,
                                      vertical: 6.0),
                                  decoration: BoxDecoration(
                                      color: Colors.teal,
                                      borderRadius: BorderRadius.circular(20.0)),
                                  child: RawGestureDetector(
                                    gestures: <Type, GestureRecognizerFactory>{
                                      CustomPanGestureRecognizer: GestureRecognizerFactoryWithHandlers<CustomPanGestureRecognizer>(
                                            () => CustomPanGestureRecognizer(
                                            onPanDown: () => onPanDown,
                                            onPanUpdate: () => onPanUpdate,
                                            onPanEnd:  () => onPanEnd
                                        ),
                                            (CustomPanGestureRecognizer instance) {},
                                      ),
                                    },
                                    /*onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MovieScreen(movie: movies[2]),
                                      ),
                                    ),*/
                                    child: const Text("View Observation",
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          cardList.add(cardItem);
        }
        return Stack(
          children: cardList,
        );
      }),
    );
  }

  Widget _buildEmptyCards() {
    return Container(
      color: Colors.transparent,
      width: 100,
      height: 100,
    );
  }
}