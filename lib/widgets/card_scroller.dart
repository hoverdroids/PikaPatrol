import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pika_patrol/model/card.dart' as card;
import 'card_scroll.dart';
import 'dart:developer' as developer;

class CardScroller extends StatefulWidget {

  List<card.CardModel> cards;
  Function(int index)? onTapCard;
  bool reverse = true;
  double currentCardPosition = 0.0;

  CardScroller(this.cards, {super.key, this.onTapCard, this.reverse = true}) {
    currentCardPosition = cards.isEmpty ? 0.0 : cards.length.toDouble();
    //developer.log("CardScroller ctor currentCardPosition:$currentCardPosition cards.length:${cards.length}");
  }

  @override
  CardScrollerState createState() => CardScrollerState();
}

class CardScrollerState extends State<CardScroller> {

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        /*------------------ The visual cards overlapping one another -------------------------------------------------------*/
        CardScrollWidget(widget.cards, widget.currentCardPosition),//TODO - CHRIS - was widget.currentPage; tried: widget.cards.length - 1

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
                  color: Color.fromARGB(1, 255-index*25, 255-index*10, 255-index*50),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  PageController _createPageController() {
    var pageController = PageController(initialPage: widget.currentCardPosition.toInt());//initialPage: widget.currentPage.toInt()

    // developer.log("CardScroller initState currentCardPosition:${widget.currentCardPosition} pageController.page:${pageController.page}");

    pageController.addListener(() {
      setState(() {
        //developer.log("CardScroller controller update currentCardPosition:${widget.currentCardPosition} pageController.page:${pageController.page}");
        widget.currentCardPosition = pageController.page ?? widget.currentCardPosition;
      });
    });

    return pageController;
  }
}