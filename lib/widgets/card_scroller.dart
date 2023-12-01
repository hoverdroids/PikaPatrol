
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pika_patrol/model/card.dart' as card;
import 'card_scroll.dart';

class CardScroller extends StatefulWidget {

  List<card.Card> cards;
  Function(int index)? onTapCard;
  bool reverse = true;
  double currentCardPosition = 0.0;

  CardScroller(this.cards, {super.key, this.onTapCard, this.reverse = true}) {
    currentCardPosition = cards.length - 1;
  }

  @override
  CardScrollerState createState() => CardScrollerState();
}

class CardScrollerState extends State<CardScroller> {

  int numberOldObservations = 0;

  late PageController pageController;

  @override
  void initState() {
    pageController = PageController(initialPage: widget.currentCardPosition.toInt());//initialPage: widget.currentPage.toInt()
    pageController.addListener(() {
      setState(() {
        if (widget.cards.length != numberOldObservations) {
          numberOldObservations = widget.cards.length;
          widget.currentCardPosition = numberOldObservations - 1.0;
          pageController.jumpTo(widget.currentCardPosition);
        } else {
          widget.currentCardPosition = pageController.page ?? widget.currentCardPosition;
        }
      });
    });
    
    super.initState();
  }

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
            controller: pageController,
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
}