import 'dart:ui';

import 'package:flutter/material.dart';

// Determined using :
// https://material.io/resources/color/#!/?view.left=0&view.right=0&primary.color=FF5722&primary.text.color=000000
var primaryStartColor = Colors.deepOrange;//Color(0xffff8800);
var primaryEndColor = Colors.deepOrangeAccent;//Color(0xffff3300);
var lightTextOnPrimaryColor = Colors.white;//*not legible when normal text size
var darkTextOnPrimaryColor = Colors.black;

var primaryLightColor = Color(0xffff8a50);
var lightTextOnPrimaryLightColor = Colors.white;//*not legible for any text size
var darkTextOnPrimaryLightColor = Colors.black;

var primaryDarkColor = Color(0xffc41c00);
var lightTextOnPrimaryDarkColor = Colors.white;
var darkTextOnPrimaryDarkColor = Colors.black;//*not legible when normal text size

// Looking at:
// https://material.io/design/color/dark-theme.html#anatomy
var lightBackgroundStartColor = Colors.white;
var lightBackgroundEndColor = Colors.white70;
var lightSurfaceStartColor = Colors.white;//*based on link, the color variation should automatically happen from elevation change
var lightSurfaceEndColor = Colors.white70;
var lightSurfaceBorderColor = Colors.grey;

var darkBackgroundStartColor = Colors.black;
var darkBackgroundEndColor = Colors.black87;
var darkSurfaceStartColor = Colors.black45;//*based on link, the color variation should automatically happen from elevation change
var darkSurfaceEndColor = Colors.black38;
var darkSurfaceBorderColor = Colors.black12;














//Old sign in blue gradient
/*colors: [
Color(0xFF73AEF5),
Color(0xFF61A4F1),
Color(0xFF478DE0),
Color(0xFF398AE5),
],
stops: [0.1, 0.4, 0.7, 0.9],
*/

var frppBlue = Color(0xff00929F);
var frppGreen = Color(0xff6D8D23);
var frppBrown = Color(0xff564319);

var gradient1StartColor = Color(0xFF1b1e44);
var gradient1EndColor = Color(0xFF2d3447);

var textLightBgColor = Colors.black45;
var textDarkBgColor = Colors.white;

//------------------- Navigation Bar ----------
var navbarColor = Colors.white;
var navbarBgColor = Colors.transparent;
var navbarButtonColor = navbarColor;
var navbarIconColor = textLightBgColor;

//------------------- Icons ---------------
var iconLightBgColor = textLightBgColor;
var iconDarkBgColor = textDarkBgColor;

// ------------------ Pages ----------------
var observationsPageBgGradient = [gradient1StartColor, gradient1EndColor];

// ------------------ Cards ----------------
var cardDecorationColor = Colors.white;
var cardShadowColor = Colors.black12;
var cardTitleColor = Colors.white;
var cardButtonColor = Colors.blueAccent;
var cardButtonTextColor = Colors.white;


//---------------------- Text ----------------------------
var LIGHT_ON_DARK_TEXT_COLOR = Colors.white;
var DARK_ON_LIGHT_TEXT_COLOR = Colors.black45;
var COLORED_ON_LIGHT_TEXT_COLOR = primaryStartColor;

//TODO - material guideline has primary and the onPrimary for text colors
//when used over the primary