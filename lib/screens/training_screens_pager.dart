// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/fundamental/icons.dart';
import 'package:material_themes_widgets/screens/onboarding_screen.dart';

class TrainingScreensPager extends StatefulWidget {

  final VoidCallback? backClickedCallback;

  const TrainingScreensPager({super.key, this.backClickedCallback});

  @override
  _TrainingScreensPagerState createState() => _TrainingScreensPagerState();

}

class _TrainingScreensPagerState extends State<TrainingScreensPager> {

  LiquidController liquidController = LiquidController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
        children: <Widget>[
          LiquidSwipe(
            pages: [
              OnboardingScreen(
                title:"Identifying Pikas\n&\nTheir Sign",
                backgroundGradientType: BackgroundGradientType.SECONDARY,
                descriptionType: ThemeGroupType.MOS,
                imageFit: BoxFit.cover,
                descriptionTextAlign: TextAlign.justify,
                description: "If pikas are present in a rockslide, they are easy to detect using many types of unique sign. Here's a short guide to help you identify pikas.",),
              OnboardingScreen(
                  title:"Sight",
                  imageUrl: "assets/images/pika_in_rockslide.jpg",
                  backgroundGradientType: BackgroundGradientType.PRIMARY,
                  descriptionType: ThemeGroupType.MOP,
                  imageFit: BoxFit.cover,
                  descriptionTextAlign: TextAlign.justify,
                  descriptionFlex: 3,
                  description:"Pikas are about the size and shape of a potato. They have grayish to cinnamon-brown fur, and large “Mickey Mouse” ears with a white rim around the outside. They do not have a visible tail. They travel across the rock-slide above and below the rocks."),
              OnboardingScreen(
                  title:"Wee Lil' Tikes",
                  imageUrl: "assets/images/juvenile_pika.jpg",
                  backgroundGradientType: BackgroundGradientType.SECONDARY,
                  descriptionType: ThemeGroupType.MOS,
                  imageFit: BoxFit.cover,
                  descriptionTextAlign: TextAlign.justify,
                  descriptionFlex: 3,
                  description: "Juvenile pikas tend to be smaller and a more uniform gray color. This is because they are on their first coat of fur, so they have not yet molted. Their calls are also softer and higher-pitched than adults."),
              OnboardingScreen(
                  title:"Hear them roar!",
                  imageUrl: "assets/images/pika4.jpg",
                  backgroundGradientType: BackgroundGradientType.PRIMARY,
                  descriptionType: ThemeGroupType.MOP,
                  imageFit: BoxFit.cover,
                  descriptionTextAlign: TextAlign.justify,
                  descriptionFlex: 3,
                  audioUrl: "assets/audio/pika_calls.mp3",
                  description: "Pikas make squeaky alarm calls for several reasons: to warn other pikas about predators like hawks and to keep others out of their territory. Adult males may also make long calls, which have a slightly higher pitch than short calls and may last up to one minute! Calls are regionally variable – so the call you hear in one part of the state may not sound quite the same as calls you hear in other parts."),
              OnboardingScreen(
                  title:"Haypiles",
                  imageUrl: "assets/images/pika_food_cache.jpg",
                  backgroundGradientType: BackgroundGradientType.SECONDARY,
                  descriptionType: ThemeGroupType.MOS,
                  imageFit: BoxFit.cover,
                  descriptionTextAlign: TextAlign.justify,
                  descriptionFlex: 3,
                  description: "Pikas construct large food caches to survive the winter, beginning in the summer and continuing until vegetation dies in the fall. Active haypiles usually consist of fresh green clippings of grass and wildflowers, packed under or between rocks. Usually, pikas build a fresh haypile on top of leftover twigs or leaves from previous years, which appear brown."),
              OnboardingScreen(
                  title:"Scat Pile",
                  imageUrl: "assets/images/pika_scat_pile_square.jpg",
                  backgroundGradientType: BackgroundGradientType.PRIMARY,
                  descriptionType: ThemeGroupType.MOP,
                  imageFit: BoxFit.cover,
                  descriptionTextAlign: TextAlign.justify,
                  descriptionFlex: 3,
                  description: "Pikas deposit two types of scat. The most common is a hard, round, brown pellet that is about the size and shape of a peppercorn. These “fecal pellets” are usually found below a large boulder in latrine sites, which may also have large white smears on the rock from urine. It is notoriously difficult to tell the age of fecal pellets, but more-recent deposits tend to still have green plant material in them and tend to be perched in a pile on a rock, with the newest pellets on top. Older pellets typically turn gray with time, fall apart easily, and do not have any green plant material in them."),
              OnboardingScreen(
                  title:"Scat",
                  imageUrl: "assets/images/pika_scat_square.jpg",
                  backgroundGradientType: BackgroundGradientType.SECONDARY,
                  descriptionType: ThemeGroupType.MOS,
                  imageFit: BoxFit.cover,
                  descriptionTextAlign: TextAlign.justify,
                  descriptionFlex: 3,
                  description: "The second type of scat is a soft black shiny string of material called a caecal pellet. Caecal pellets are re-ingested because they are actually more nutritious than plants stored in haypiles! These pellets are sometimes found stored in haypiles (usually smeared on a rock or a cached plant), but are rarely found in latrine sites."),
            ],
            enableLoop: false,
            fullTransitionValue: 300,
            /*enableSlideIcon: true,*/
            waveType: WaveType.liquidReveal,
            positionSlideIcon: 0.5,
            liquidController: liquidController,
            ignoreUserGestureWhileAnimating: false,
            disableUserGesture: false,
            //TODO - onPageChangeCallback: pageChangeCallback,
          ),
          SafeArea(
            child: ThemedIconButton(
              Icons.arrow_back,
              emphasis: Emphasis.HIGH,
              type: ThemeGroupType.MOP,
              onPressedCallback: widget?.backClickedCallback,
            ),
          )
        ],
      ),
    );
  }
}