import 'package:flutter/material.dart';
import 'package:pika_joe/styles/colors.dart';
import 'package:pika_joe/styles/styles.dart';
import 'package:pika_joe/widget/text/standardized_text.dart';

class StandardizedButton extends StatelessWidget {

  String text;
  Function onTapped = () => print('Tappy Tap');
  ElementSize elementSize;
  ElementStyle elementStyle;
  Emphasis emphasis;
  ShadowIntensity shadowIntensity;
  SpacingTypes spacingType;
  BackgroundShades backgroundShade;

  StandardizedButton({
    this.text,
    this.onTapped,
    this.elementSize = ElementSize.M,
    this.elementStyle = ElementStyle.LIGHT_ON_LIGHT,
    this.emphasis = Emphasis.NONE,
    this.shadowIntensity = ShadowIntensity.NONE,
    this.spacingType = SpacingTypes.NONE,
    this.backgroundShade = BackgroundShades.LIGHT
  });

  @override
  Widget build(BuildContext context) {
    //TODO - the sizes here should be read from styling so that no matter where the button is used in the app, it can just pass a text and be done


    /*
      Material Button Types and Guidelines:
      - Contained & Rounded (aka the highest emphasis)
        - Same colors as high emphasis but round the corners
      - Contained (aka high emphasis)
        - Colored
          - Light Bg  Primary color fill with white text
          - Dark Bg   Primary color fill with dark text
        - Normal
          - Light Bg  Gray color fill with white text?
          - Dark Bg   White color fill with dark text?
      - Outlined (medium emphasis)
        - Colored
          - Light Bg  Primary color with Gray box
          - Dark Bg   Primary color with white box
        - Normal
          - Light Bg  Gray with gray box
          - Dark Bg   White with white box
      - Text (aka low emphasis)
        - Colored
          - Light Bg  Primary color
          - Dark Bg   Primary color
        - Normal
          - Light Bg  Gray
          - Dark Bg   White
    */






    Color color = LIGHT_ON_DARK_TEXT_COLOR;
    TextStyle textStyle = COLORED_ON_LIGHT_TEXT_STYLE_1;

    return Container(
      padding: STANDARDIZED_SPACING[spacingType.index],
      width: double.infinity,
      child: RaisedButton(
        elevation: BUTTON_ELEVATION[shadowIntensity.index],
        onPressed: () => onTapped,
        padding: EdgeInsets.all(15.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        color: color,
        child: Text(text, style: textStyle),
      ),
    );
  }
}