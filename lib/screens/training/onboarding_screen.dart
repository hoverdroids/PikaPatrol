import 'package:flutter/material.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/clippaths/clip_paths.dart';
import 'package:material_themes_widgets/defaults/dimens.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';
import 'package:provider/provider.dart';

class OnboardingScreen extends Container {

  final BackgroundGradientType backgroundGradientType;
  final ClipPathType clipPathType;
  final String title;
  final String description;
  final String imageUrl;

  OnboardingScreen(
  {
    this.title,
    this.description,
    this.imageUrl,
    this.backgroundGradientType = BackgroundGradientType.PRIMARY,
    this.clipPathType = ClipPathType.BOILER_PLATE,
    EdgeInsetsGeometry padding
  }): super(padding: padding != null ? padding : EdgeInsets.all(0.0));

  @override
  Widget build(BuildContext context) {

    var children = <Widget>[];

    //if (title != null) {
      children.add(_createTitle());
    //}

    ////if (imageUrl != null) {
      children.add(_createImage());
    //}

    //if (description != null) {
      children.add(_createDescription());
    //}

    return Container(
      //width: width != null ? width : calculatedWidth,
      width: double.infinity,
      height: double.infinity,
      child: Padding(
        child: ClipPath(
            child: Stack(
              children: <Widget>[
                context.watch<MaterialThemesManager>().getBackgroundGradient(backgroundGradientType),
                Column(
                  children: children,
                )
              ],
            ),
          clipper: SimpleClipPath(type: clipPathType),
        ),
        padding: padding,
      ),
    );
  }

  Widget _createTitle() {
    //return SizedBox(height: 20.0, width: 20.0,child: Container(color: Colors.deepPurple,),);
    //return ThemedTitle("Signs of life", type: ThemeGroupType.MOP);
    return Flexible(
      flex: 1,
      //fit: FlexFit.tight,
      child: //Container(
        //width: double.infinity,
        //height: double.infinity,
        //color: Colors.deepPurple,
        //child:
        Center(child: ThemedH4(title, type: ThemeGroupType.MOP, emphasis: Emphasis.HIGH)),
      //),//Container(child:ThemedTitle(title, type: ThemeGroupType.MOP)
    );
  }

  Widget _createImage() {
    return Flexible(
      flex: 4,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Image.asset(imageUrl),
        ),
      ),
    );
  }

  Widget _createDescription() {
    return Flexible(
      flex: 1,
      child: Center(child: ThemedH5(description, type: ThemeGroupType.MOP)),
    );
  }

}

/*

Column(
      children: <Widget>[


      ],
    )


 */



/*
Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Image.asset("assets/images/cobra_kai.jpg"),
        ),
      )

 */

//context.watch<MaterialThemesManager>().getBackgroundGradient(backgroundGradientType)