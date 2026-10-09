import 'package:flutter/material.dart';
import 'package:pika_patrol/model/card.dart' as card;
import 'card_scroll.dart';

class CardScroller extends StatefulWidget {

  final List<card.CardModel> cards;
  final Function(int index)? onTapCard;
  final bool reverse;

  // Called when the user scrolls near the oldest card (index 0), so the caller can load older
  // cards. They are added to the start of the list; the scroller keeps showing the same card.
  final VoidCallback? onNearStart;

  const CardScroller(this.cards, {super.key, this.onTapCard, this.reverse = false, this.onNearStart});

  @override
  CardScrollerState createState() => CardScrollerState();
}

class CardScrollerState extends State<CardScroller> {

  // How close to the oldest card, in cards, before asking for more
  static const int _nearStartCards = 3;

  late double _currentCardPosition;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentCardPosition = _lastIndex(widget.cards);
    _pageController = PageController(initialPage: _currentCardPosition.toInt());
    _pageController.addListener(_onPageChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkNearStart());
  }

  @override
  void didUpdateWidget(CardScroller oldWidget) {
    super.didUpdateWidget(oldWidget);
    final added = widget.cards.length - oldWidget.cards.length;
    if (added == 0) return;

    // Stay on the same card: cards are added or removed at the oldest end (index 0), so keep the
    // same distance from the newest card
    final cardsFromEnd = _lastIndex(oldWidget.cards) - _currentCardPosition;
    _currentCardPosition = (_lastIndex(widget.cards) - cardsFromEnd).clamp(0.0, _lastIndex(widget.cards));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageController.hasClients) {
        _pageController.jumpToPage(_currentCardPosition.round());
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  double _lastIndex(List<card.CardModel> cards) => cards.isEmpty ? 0.0 : cards.length - 1.0;

  void _onPageChanged() {
    setState(() {
      _currentCardPosition = _pageController.page ?? _currentCardPosition;
    });
    _checkNearStart();
  }

  void _checkNearStart() {
    if (mounted && widget.cards.isNotEmpty && _currentCardPosition <= _nearStartCards) {
      widget.onNearStart?.call();
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: <Widget>[
      /*------------------ The visual cards overlapping one another -------------------------------------------------------*/
      CardScrollWidget(widget.cards, _currentCardPosition),

      /*------------------ Invisible pager the intercepts touches and passes paging input from user to visual cards ------- */
      Positioned.fill(
        child: PageView.builder(
          itemCount: widget.cards.length,
          controller: _pageController,
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
}
