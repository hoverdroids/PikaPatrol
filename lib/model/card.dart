import 'package:flutter/widgets.dart';

import '../primitives/card_layout.dart';

class CardModel {

  String? title;
  IconData? icon;
  String? imageUrl;
  String? buttonText;
  CardLayout cardLayout = CardLayout.bottomLeft;

  CardModel({
    this.title,
    this.icon,
    this.imageUrl,
    this.buttonText,
    this.cardLayout = CardLayout.bottomLeft
  });
}