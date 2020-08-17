import 'package:flutter/material.dart';
import 'package:pika_joe/styles/colors.dart';

//Dark BG text should be white

//White BG text should be gray or colored
//colored when low/med/high emphasis
//gray when no emphasis - ie description text

//TODO - make this into an easy to use widget where we indicate a couple params and it handles the rest
//For now, let's just start aggregating

//TODO - try to remove the following after standardizing
//Big login button
var COLORED_ON_LIGHT_TEXT_STYLE_1 = TextStyle(
  color: primaryStartColor,
  letterSpacing: 1.5,
  fontSize: 18.0,
  fontWeight: FontWeight.bold,
  fontFamily: 'OpenSans',
);

// Font sizes from:
// https://material.io/design/typography/the-type-system.html#type-scale
// https://www.didierboelens.com/2020/05/material-textstyle-texttheme/#:~:text=In%20Flutter%2C%20the%20default%20font,which%20each%20glyph%20is%20designed.
const h1FontSize = 96;

