import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pika_patrol/model/card.dart' as card;
import 'card_scroll.dart';

class CardScroller extends StatefulWidget {

  List<card.CardModel> cards;
  Function(int index)? onTapCard;
  bool reverse = true;
  double currentCardPosition = 0.0;

  CardScroller(this.cards, {super.key, this.onTapCard, this.reverse = false}) {
    currentCardPosition = cards.isEmpty ? 0.0 : cards.length.toDouble() - 1.0;
  }

  @override
  CardScrollerState createState() => CardScrollerState();
}

class CardScrollerState extends State<CardScroller> {

  @override
  Widget build(BuildContext context) => Stack(
    children: <Widget>[
      /*------------------ The visual cards overlapping one another -------------------------------------------------------*/
      CardScrollWidget(widget.cards, widget.currentCardPosition),

      /*------------------ Invisible pager the intercepts touches and passes paging input from user to visual cards ------- */
      Positioned.fill(
        child: PageView.builder(
          itemCount: widget.cards.length,
          controller: _createPageController(),
          reverse: widget.reverse,
          scrollDirection: Axis.horizontal,
          allowImplicitScrolling: true,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => { widget.onTapCard?.call(index) },
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Color.fromARGB(1, 255-index*25, 255-index*10, 255-index*50)
              ),
            );
          },
        ),
      ),
    ],
  );

  PageController _createPageController() {
    var pageController = PageController(initialPage: widget.currentCardPosition.toInt(), keepPage: false);

    pageController.addListener(() {
      setState(() {
        widget.currentCardPosition = pageController.page ?? widget.currentCardPosition;
      });
    });

    return pageController;
  }
}