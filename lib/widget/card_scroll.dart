

import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:pika_joe/mock/data.dart';
import 'package:pika_joe/styles/styles.dart';
import 'package:pika_joe/widget/card_item.dart';

class CardScrollWidget extends StatelessWidget {

  var currentPage;

  //Pass the start page when constructing the widget
  CardScrollWidget(this.currentPage);//TODO - do we want to pass a page vs current?

  @override
  Widget build(BuildContext context) {
    return new AspectRatio(
        aspectRatio: cardScrollWidgetAspectRatio,
        child: LayoutBuilder(
          builder: (context, constraints){
            var width = constraints.maxWidth;
            var height = constraints.maxHeight;

            var safeWidth = width - 2 * cardScrollWidgetPadding;
            var safeHeight = height - 2 * cardScrollWidgetPadding;

            var heightOfPrimaryCard = safeHeight;
            var widthOfPrimaryCard = safeWidth;

            var primaryCardLeft = safeWidth - widthOfPrimaryCard;
            var horizontalInset = primaryCardLeft / 2;

            List<Widget> cardList = new List();
            for(var i = 0; i < images.length; i++) {
              var delta = i - currentPage;
              bool isOnRight = delta > 0;
              //TODO - should the 15 be a dimen?
              var start = cardScrollWidgetPadding + max(primaryCardLeft - horizontalInset * -delta * (isOnRight ? 15 : 1), 0.0);
              var cardItem = CardItem(title: title[i], delta: delta, start: start, isOnRight: isOnRight, img: images[i]);
              cardList.add(cardItem);
            }

            return Stack(
              children: cardList,
            );
          },
        ),
    );
  }
}