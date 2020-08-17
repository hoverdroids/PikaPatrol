import 'package:flutter/material.dart';
import 'package:pika_joe/styles/colors.dart';
import 'package:pika_joe/styles/constants.dart';
import 'package:pika_joe/styles/styles.dart';
import 'package:pika_joe/widget/text/standardized_text.dart';

class StandardizedButton extends StatelessWidget {

  String text;
  Function onTapped = () => print('Tappy Tap');
  ElementSize elementSize;
  WidthStyle widthStyle;
  ElementStyle elementStyle;
  Emphasis emphasis;
  ShadowIntensity shadowIntensity;
  ShadowSize shadowSize;
  SpacingTypes spacingType;
  BackgroundShades backgroundShade;
  CornerTypes cornerType;

  StandardizedButton({
    this.text,
    this.onTapped,
    this.elementSize = ElementSize.M,
    this.widthStyle = WidthStyle.WRAPPED,
    this.elementStyle = ElementStyle.LIGHT_ON_LIGHT,
    this.emphasis = Emphasis.NONE,
    this.shadowIntensity = ShadowIntensity.NONE,
    this.shadowSize = ShadowSize.NONE,
    this.spacingType = SpacingTypes.NONE,
    this.backgroundShade = BackgroundShades.LIGHT,
    this.cornerType = CornerTypes.ROUNDED
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

    var width;
    if(widthStyle == WidthStyle.WRAPPED){
      width = null;
    } else if(widthStyle == WidthStyle.MATCH_PARENT) {
      width = double.infinity;
    } else {
      //TODO - need to include stretch
    }

    return Container(
      padding: STANDARDIZED_SPACING[spacingType.index],
      width: width,
      child: _buildButton(),
    );
  }

  Widget _buildButton() {
    if (emphasis == Emphasis.NONE) {
      return _buildNoEmphasisButton();
    } else if (emphasis == Emphasis.LOW) {
      return _buildLowEmphasisButton();
    } else if (emphasis == Emphasis.MEDIUM) {
      return _buildMediumEmphasisButton();
    } else if (emphasis == Emphasis.HIGH) {
      return _buildHighEmphasisButton();
    } else {
      return _buildPrimaryCallToActionButton();
    }
  }

  Widget _buildCircularButton() {

  }

  //TODO - small, clickable for getting more info
  /*Widget _buildInfoButton() {

  }*/

  //TODO - standardize the way we place buttons into the appbar
  /*Widget _buildAppbarButton() {

  }*/

  //Text that is bold, capitalized, and not colorized
  Widget _buildNoEmphasisButton() {
    return FlatButton(
      onPressed: () => onTapped,
      //padding: EdgeInsets.all(15.0),
      //color: LIGHT_ON_DARK_TEXT_COLOR,
      child: Text(text, style: kLabelStyle),
    );
  }

  //Text that is bold, capitalized, and colorized
  Widget _buildLowEmphasisButton() {
    return RaisedButton(
      elevation: BUTTON_ELEVATION[shadowSize.index],
      onPressed: () => onTapped,
      padding: EdgeInsets.all(15.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cornerRadii[cornerType.index]),
      ),
      color: LIGHT_ON_DARK_TEXT_COLOR,
      child: Text(text, style: COLORED_ON_LIGHT_TEXT_STYLE_1),
    );
  }

  //No-fill button with text that is bold and capitalized; rounded corners
  Widget _buildMediumEmphasisButton() {
    return RaisedButton(
      elevation: BUTTON_ELEVATION[shadowSize.index],
      onPressed: () => onTapped,
      padding: EdgeInsets.all(15.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cornerRadii[cornerType.index]),
      ),
      color: LIGHT_ON_DARK_TEXT_COLOR,
      child: Text(text, style: COLORED_ON_LIGHT_TEXT_STYLE_1),
    );
  }

  //Filled button with text that is bold and capitalized; rounded corners
  Widget _buildHighEmphasisButton() {
    return RaisedButton(
      elevation: BUTTON_ELEVATION[shadowSize.index],
      onPressed: () => onTapped,
      padding: EdgeInsets.all(15.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cornerRadii[cornerType.index]),
      ),
      color: LIGHT_ON_DARK_TEXT_COLOR,
      child: Text(text, style: COLORED_ON_LIGHT_TEXT_STYLE_1),
    );
  }

  //Filled button with text that is bold and capitalized; circular ends
  Widget _buildPrimaryCallToActionButton() {
    return RaisedButton(
      elevation: BUTTON_ELEVATION[shadowSize.index],
      onPressed: () => onTapped,
      padding: EdgeInsets.all(15.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cornerRadii[cornerType.index]),
      ),
      color: LIGHT_ON_DARK_TEXT_COLOR,
      child: Text(text, style: COLORED_ON_LIGHT_TEXT_STYLE_1),
    );
  }

}