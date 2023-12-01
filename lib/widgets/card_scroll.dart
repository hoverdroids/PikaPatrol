// ignore_for_file: depend_on_referenced_packages
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:material_themes_widgets/fundamental/icons.dart';
import 'package:pika_patrol/model/observation.dart';
import 'package:pika_patrol/widgets/universal_image.dart';
import 'custom_pan_gesture_recognizer.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'dart:developer' as developer;

// ignore: must_be_immutable
class CardScrollWidget extends StatelessWidget {
  List<Observation> observations = <Observation>[]; //TODO - CHRIS - this should be generic "cards"
  late double cardAspectRatio;
  late double widgetAspectRatio;

  var currentCardPosition = 0.0;
  var padding = 20.0;
  var verticalInset = 20.0;

  CardScrollWidget(this.observations, {super.key, this.currentCardPosition = 0.0}) {
    //developer.log("CurrentCardPosition:$currentCardPosition");
    cardAspectRatio = 12.0 / 16.0;
    widgetAspectRatio = cardAspectRatio * 1.2;
  }

  @override
  Widget build(BuildContext context) {
    return observations.isEmpty ? _buildEmptyCards() : _buildCards();
  }

  Widget _buildCards() => AspectRatio(
    aspectRatio: widgetAspectRatio,

    child: LayoutBuilder(builder: (context, constraints) {
      var (primaryCardLeft, horizontalInset) = _calculateCardLeftAndHorizontalInset(constraints);
      //developer.log("CurrentCardPosition:$currentCardPosition primaryCardLeft:$primaryCardLeft horzInset:$horizontalInset");

      List<Widget> cardList = <Widget>[];

      for (var observationIndex = 0; observationIndex < observations.length; observationIndex++) {
        var card = _buildCard(observationIndex, primaryCardLeft, horizontalInset);
        cardList.add(card);
      }

      return Stack(
        children: cardList,
      );
    }),
  );

  (double, double) _calculateCardLeftAndHorizontalInset(BoxConstraints constraints) {
    var width = constraints.maxWidth;
    var height = constraints.maxHeight;

    var safeWidth = width - 2 * padding;
    var safeHeight = height - 2 * padding;

    var heightOfPrimaryCard = safeHeight;
    var widthOfPrimaryCard = heightOfPrimaryCard * cardAspectRatio;

    var primaryCardLeft = safeWidth - widthOfPrimaryCard;
    var horizontalInset = primaryCardLeft / 2;

    return (primaryCardLeft, horizontalInset);
  }

  Widget _buildEmptyCards() => Container(color: Colors.transparent, width: 100, height: 100);

  Widget _buildCard(int observationIndex, double primaryCardLeft, double horizontalInset) {
    var cardContent = _buildCardContent(observationIndex);
    return _buildCardWrapper(observationIndex, primaryCardLeft, horizontalInset, cardContent);
  }

  Widget _buildCardContent(int observationIndex) => Stack(
    fit: StackFit.expand,
    children: <Widget>[
      _buildCardImage(observationIndex),
      _buildObservationUploadStatusIcon(observationIndex),
      _buildObservationNameAndButton(observationIndex)
    ],
  );

  Widget _buildCardWrapper (int observationIndex, double primaryCardLeft, double horizontalInset, Widget cardContent) {
    var numberCardsToMove = observationIndex - currentCardPosition;
    bool isOnRight = numberCardsToMove > 0;

    var cardLeft = primaryCardLeft - horizontalInset * -numberCardsToMove * (isOnRight ? 15 : 1);
    var start = padding + max(cardLeft, 0.0);
    var verticalDeltaBetweenCards = padding + verticalInset * max(-numberCardsToMove, 0.0);

    return Positioned.directional(
      top: verticalDeltaBetweenCards,//should be called from top
      bottom: verticalDeltaBetweenCards,//should be called from bottom
      start: start,
      textDirection: TextDirection.rtl,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          decoration: _buildCardShadow(),
          child: AspectRatio(
            aspectRatio: cardAspectRatio,
            child: GestureDetector(
              onTap: () => developer.log('Tapped'),
              child: cardContent,
            ),
          ),
        ),
      ),
    );
  }

  Decoration _buildCardShadow() => const BoxDecoration(
    color: Colors.white,
    boxShadow: [
      BoxShadow(color: Colors.black12,
      offset: Offset(3.0, 6.0),
      blurRadius: 10.0)
    ]
  );

  Widget _buildCardImage(int observationIndex) {//TODO - CHRIS - was passing null; need to pass local image path so cards still show with blank bg
    var imageUrls = observations[observationIndex].imageUrls ?? [];
    var url = imageUrls.isNotEmpty ? imageUrls.elementAt(0) : "";
    return UniversalImage(url);
  }

  Widget _buildObservationUploadStatusIcon(int observationIndex) {
    var icon = observations[observationIndex].uid?.isNotEmpty == true ? Icons.cloud_upload : Icons.access_time_filled;
    return Align(
      alignment: Alignment.topLeft,
      child: ThemedIconButton(icon, type: ThemeGroupType.MOI, onPressedCallback: () => {}),
    );
  }

  Widget _buildObservationNameAndButton(int observationIndex) => Align(
    alignment: Alignment.bottomLeft,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildObservationName(observations[observationIndex].name),
        const SizedBox(height: 10.0),
        _buildViewObservationButton()
      ],
    ),
  );

  Widget _buildObservationName(String? observationName) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    child: Text(
      observationName ?? "!!! NO OBSERVATION NAME !!!",
      style: const TextStyle(color: Colors.white, fontSize: 25.0, fontFamily: "SF-Pro-Text-Regular")
    ),
  );

  Widget _buildViewObservationButton() => Padding(
    padding: const EdgeInsets.only(left: 12.0, bottom: 12.0),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 6.0),
      decoration: BoxDecoration(color: Colors.teal, borderRadius: BorderRadius.circular(20.0)),
      child: const Text("View Observation", style: TextStyle(color: Colors.white))
    ),
  );
}
