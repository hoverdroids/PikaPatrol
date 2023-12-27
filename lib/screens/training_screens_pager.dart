// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/fundamental/icons.dart';
import 'package:material_themes_widgets/screens/onboarding_screen.dart';
import 'package:pika_patrol/data/pika_species.dart';
import 'package:provider/provider.dart';

import '../l10n/translations.dart';
import '../model/pika.dart';

class TrainingScreensPager extends StatefulWidget {

  final VoidCallback? backClickedCallback;

  const TrainingScreensPager({super.key, this.backClickedCallback});

  @override
  TrainingScreensPagerState createState() => TrainingScreensPagerState();
}

class TrainingScreensPagerState extends State<TrainingScreensPager> {

  LiquidController liquidController = LiquidController();
  late Translations translations;

  @override
  Widget build(BuildContext context) {
    translations = Provider.of<Translations>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
        children: <Widget>[
          LiquidSwipe(
            pages: _buildPages(context),
            enableLoop: false,
            fullTransitionValue: 300,
            slideIconWidget: Container(
              margin: const EdgeInsets.all(10.0),
              decoration: const BoxDecoration(
                  color: Colors.white,//TODO - CHRIS - use theme manager
                  shape: BoxShape.circle
              ),
              child: const ThemedIconButton(
                  Icons.arrow_back_ios,
                  emphasis: Emphasis.HIGH,
                  type: ThemeGroupType.POM
              ),
            ),
            waveType: WaveType.liquidReveal,
            positionSlideIcon: 0.99,
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
              onPressedCallback: widget.backClickedCallback,
            ),
          )
        ],
      ),
    );
  }

  List<Widget> _buildPages(BuildContext context) => _buildTrainingPages(context) + _buildSpeciesPages(context);

  List<Widget> _buildTrainingPages(BuildContext context) => [
    OnboardingScreen(
      title: translations.identifyingPikasAndTheirSignsOnboardingTitle,
      backgroundGradientType: BackgroundGradientType.SECONDARY,
      descriptionType: ThemeGroupType.MOS,
      imageFit: BoxFit.cover,
      descriptionTextAlign: TextAlign.justify,
      description: translations.identifyingPikasAndTheirSignsOnboardingDetails),
    OnboardingScreen(
        title:translations.sightOnboardingTitle,
        imageUrl: "assets/images/pika_in_rockslide.jpg",
        backgroundGradientType: BackgroundGradientType.PRIMARY,
        descriptionType: ThemeGroupType.MOP,
        imageFit: BoxFit.cover,
        descriptionTextAlign: TextAlign.justify,
        descriptionFlex: 3,
        description:translations.sightOnboardingDetails),
    OnboardingScreen(
        title: translations.juvenileOnboardingTitle,
        imageUrl: "assets/images/juvenile_pika.jpg",
        backgroundGradientType: BackgroundGradientType.SECONDARY,
        descriptionType: ThemeGroupType.MOS,
        imageFit: BoxFit.cover,
        descriptionTextAlign: TextAlign.justify,
        descriptionFlex: 3,
        description: translations.juvenileOnboardingDetails),
    OnboardingScreen(
        title: translations.soundOnboardingTitle,
        imageUrl: "assets/images/pika4.jpg",
        backgroundGradientType: BackgroundGradientType.PRIMARY,
        descriptionType: ThemeGroupType.MOP,
        imageFit: BoxFit.cover,
        descriptionTextAlign: TextAlign.justify,
        descriptionFlex: 3,
        audioUrl: "assets/audio/pika_calls.mp3",
        description: translations.soundOnboardingDetails),
    OnboardingScreen(
        title: translations.haypilesOnboardingTitle,
        imageUrl: "assets/images/pika_food_cache.jpg",
        backgroundGradientType: BackgroundGradientType.SECONDARY,
        descriptionType: ThemeGroupType.MOS,
        imageFit: BoxFit.cover,
        descriptionTextAlign: TextAlign.justify,
        descriptionFlex: 3,
        description: translations.haypilesOnboardingDetails),
    OnboardingScreen(
        title: translations.scatPileOnboardingTitle,
        imageUrl: "assets/images/pika_scat_pile_square.jpg",
        backgroundGradientType: BackgroundGradientType.PRIMARY,
        descriptionType: ThemeGroupType.MOP,
        imageFit: BoxFit.cover,
        descriptionTextAlign: TextAlign.justify,
        descriptionFlex: 3,
        description: translations.scatPileOnboardingDetails),
    OnboardingScreen(
        title: translations.scatOnboardingTitle,
        imageUrl: "assets/images/pika_scat_square.jpg",
        backgroundGradientType: BackgroundGradientType.SECONDARY,
        descriptionType: ThemeGroupType.MOS,
        imageFit: BoxFit.cover,
        descriptionTextAlign: TextAlign.justify,
        descriptionFlex: 3,
        description: translations.scatOnboardingDetails),
  ];

  List<Widget> _buildSpeciesPages(BuildContext context) {
    var pages = <OnboardingScreen>[];

    for (var index = 0; index < PikaData.PIKAS.length; index++) {
      Pika pika = PikaData.PIKAS[index];
      var bla = OnboardingScreen(
          title: pika.species,
          imageUrl: "assets/images/${pika.imagePath}",
          backgroundGradientType: index.isEven ? BackgroundGradientType.PRIMARY : BackgroundGradientType.SECONDARY ,
          descriptionType: index.isEven ? ThemeGroupType.MOP : ThemeGroupType.MOS,
          imageFit: BoxFit.cover,
          descriptionTextAlign: TextAlign.justify,
          descriptionFlex: 3,
          description: pika.description,
          moreInfoUrl: pika.moreInfoLink,
      );
      pages.add(bla);
    }

    return pages;
  }
}