// ignore_for_file: depend_on_referenced_packages
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:material_themes_widgets/fundamental/icons.dart';
import 'package:pika_patrol/model/card.dart' as card;
import 'package:pika_patrol/widgets/universal_image.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'dart:developer' as developer;

import '../primitives/card_layout.dart';

// ignore: must_be_immutable
class CardScrollWidget extends StatelessWidget {

  List<card.Card> cards = [];
  late double cardAspectRatio;
  late double widgetAspectRatio;

  double currentCardPosition;
  var padding = 20.0;
  var verticalInset = 20.0;

  late BorderRadius cardBorderRadius;
  double cardShadowOffsetX;
  double cardShadowOffsetY;
  double cardShadowBlurRadius;
  Color cardShadowColor;

  CardScrollWidget(
      List<card.Card> cards,
      this.currentCardPosition,
      {
        super.key,
        BorderRadius? cardBorderRadius,
        this.cardShadowOffsetX = 3.0,
        this.cardShadowOffsetY = 3.0,
        this.cardShadowBlurRadius = 10.0,
        this.cardShadowColor = Colors.black38
      }
  ) {
    this.cardBorderRadius = cardBorderRadius ?? BorderRadius.circular(16);
    //developer.log("CurrentCardPosition:$currentCardPosition");
    var defaultCards = [
      card.Card(title:"No Observations Found", buttonText: null, cardLayout: CardLayout.centered)
    ];

    this.cards = cards.isEmpty ? defaultCards : cards;

    cardAspectRatio = 12.0 / 16.0;
    widgetAspectRatio = cardAspectRatio * 1.2;
  }

  @override
  Widget build(BuildContext context) => cards.isEmpty ? _buildEmptyCards() : _buildCards();

  Widget _buildCards() => AspectRatio(
    aspectRatio: widgetAspectRatio,

    child: LayoutBuilder(builder: (context, constraints) {
      var (primaryCardLeft, horizontalInset) = _calculateCardLeftAndHorizontalInset(constraints);
      //developer.log("CurrentCardPosition:$currentCardPosition primaryCardLeft:$primaryCardLeft horzInset:$horizontalInset");

      List<Widget> cardList = <Widget>[];

      for (var cardIndex = 0; cardIndex < cards.length; cardIndex++) {
        cardList.add(_buildCard(cardIndex, primaryCardLeft, horizontalInset));
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

  Widget _buildCard(int cardIndex, String title, String buttonText, double primaryCardLeft, double horizontalInset) {
    var cardContent = _buildCardContent(cardIndex, title, buttonText);
    return _buildCardWrapper(cardIndex, primaryCardLeft, horizontalInset, cardContent);
  }

  Widget _buildCardContent(int cardIndex, String title, String buttonText) => Stack(
    var card = cards[cardIndex];
    children: <Widget>[
      _buildCardImage(cardIndex),
      _buildIcon(cardIndex),
      _buildTitleAndMoreDetailsButton(cardIndex, title, buttonText)
    ],
  );

  Widget _buildCardWrapper (int cardIndex, double primaryCardLeft, double horizontalInset, Widget cardContent) {
    var numberCardsToMove = cardIndex - currentCardPosition;
    bool isOnRight = numberCardsToMove > 0;

    var cardLeft = primaryCardLeft - horizontalInset * -numberCardsToMove * (isOnRight ? 15 : 1);
    var start = padding + max(cardLeft, 0.0);
    var verticalDeltaBetweenCards = padding + verticalInset * max(-numberCardsToMove, 0.0);

    return Positioned.directional(
      top: verticalDeltaBetweenCards,//should be called from top
      bottom: verticalDeltaBetweenCards,//should be called from bottom
      start: start,
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: _buildCardShadow(),
        child: ClipRRect(
          borderRadius: cardBorderRadius,
          child: AspectRatio(
            aspectRatio: cardAspectRatio,
            child: cardContent
          )
        )
      )
    );
  }

  Decoration _buildCardShadow() => BoxDecoration(
    borderRadius: cardBorderRadius,
    boxShadow: [
      BoxShadow(
        color: cardShadowColor,
        offset: Offset(cardShadowOffsetX, cardShadowOffsetY),
        blurRadius: cardShadowBlurRadius
      )
    ]
  );

  Widget _buildCardImage(int cardIndex) {//TODO - CHRIS - was passing null; need to pass local image path so cards still show with blank bg
    return UniversalImage(cards[cardIndex].imageUrl);
  }

  Widget _buildIcon(int cardIndex) => Align(
    alignment: Alignment.topLeft,
    child: ThemedIconButton(cards[cardIndex].icon, type: ThemeGroupType.MOI, onPressedCallback: () => {}),
  );

  Widget _buildTitleAndMoreDetailsButton(String? title, String? buttonText, CardLayout cardLayout) => Align(
    alignment: cardLayout == CardLayout.bottomLeft ? Alignment.bottomLeft : Alignment.center,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: cardLayout == CardLayout.bottomLeft ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: <Widget>[
        if (title != null) ... [
          _buildTitle(title, cardLayout),
          const SizedBox(height: 10.0),
        ],
        if (buttonText != null) ... [
          _buildMoreDetailsButton(buttonText)
        ]
      ],
    ),
  );

  Widget _buildTitle(String? title, CardLayout cardLayout) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    child: Text(
      title ?? "!!! NO TITLE !!!",
      textAlign: cardLayout == CardLayout.bottomLeft ? TextAlign.start : TextAlign.center,
      style: const TextStyle(color: Colors.white, fontSize: 25.0, fontFamily: "SF-Pro-Text-Regular")
    ),
  );

  Widget _buildMoreDetailsButton(String buttonText) => Padding(
    padding: const EdgeInsets.only(left: 12.0, bottom: 12.0),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 6.0),
      decoration: BoxDecoration(color: Colors.teal, borderRadius: BorderRadius.circular(20.0)),
      child: Text(
          buttonText,
          style: const TextStyle(color: Colors.white)
      )
    ),
  );
}
