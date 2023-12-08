import 'package:flutter/widgets.dart';

import '../primitives/card_layout.dart';

class Card {

  String? title;
  IconData? icon;
  String? imageUrl;
  String? buttonText;
  CardLayout cardLayout = CardLayout.bottomLeft;

  Card({
    this.title,
    this.icon,
    this.imageUrl,
    this.buttonText = "More Details",
    this.cardLayout = CardLayout.bottomLeft
  });
}