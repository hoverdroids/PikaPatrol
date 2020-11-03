import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pika_joe/model/observation2.dart';
import 'package:pika_joe/widget/universal_image.dart';
import 'custom_pan_gesture_recognizer.dart';

class CardScrollWidget extends StatelessWidget {

  List<Observation2> observations;
  var cardAspectRatio;
  var widgetAspectRatio;

  var currentPage = 0.0;
  var padding = 20.0;
  var verticalInset = 20.0;

  CardScrollWidget(this.observations, {this.currentPage = 0}){
    cardAspectRatio = 12.0 / 16.0;
    widgetAspectRatio = cardAspectRatio * 1.2;
    if (this.observations == null) {
      this.observations = <Observation2>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    return observations == null || observations.isEmpty ? _buildEmptyCards() : _buildCards();
  }

  Widget _buildCards() {
    return new AspectRatio(
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

        List<Widget> cardList = new List();

        _onPanDown(DragUpdateDetails details) {
          print('Pan Down');
        }

        _onPanUpdate(DragUpdateDetails details) {
          print('Pan Update');
        }

        _onPanEnd(_) {
          print('Pan End');
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
                decoration: BoxDecoration(color: Colors.white, boxShadow: [
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
                        UniversalImage(observations[i].imageUrls.isNotEmpty ? observations[i].imageUrls[0] : null),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 8.0),
                                child: Text(observations[i].name,//
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 25.0,
                                        fontFamily: "SF-Pro-Text-Regular")),
                              ),
                              SizedBox(
                                height: 10.0,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 12.0, bottom: 12.0),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 22.0, vertical: 6.0),
                                  decoration: BoxDecoration(
                                      color: Colors.teal,
                                      borderRadius: BorderRadius.circular(20.0)),
                                  child: RawGestureDetector(
                                    gestures: <Type, GestureRecognizerFactory>{
                                      CustomPanGestureRecognizer: GestureRecognizerFactoryWithHandlers<CustomPanGestureRecognizer>(
                                            () => CustomPanGestureRecognizer(
                                            onPanDown: () => _onPanDown,
                                            onPanUpdate: () => _onPanUpdate,
                                            onPanEnd:  () => _onPanEnd
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
                                    child: Text("View Observation",
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
      color: Colors.blue,
      width: 100,
      height: 100,
    );
  }
}