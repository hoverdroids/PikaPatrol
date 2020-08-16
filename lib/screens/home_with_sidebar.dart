import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:pika_joe/screens/observations_page.dart';
import 'package:pika_joe/styles/colors.dart';
import 'package:pika_joe/styles/styles.dart';
import 'package:pika_joe/widget/drawer/elastic_drawer.dart';
import 'package:pika_joe/widget/navigation/menu_title_profile_appbar.dart';
import 'package:pika_joe/widget/navigation/transitions/center_bounce_in.dart';
import 'package:pika_joe/widget/navigation/transitions/top_right_scale_in.dart';
import 'package:pika_joe/widget/navigation/stats_observations_map_navigationbar.dart';
import 'package:pika_joe/widget/profile/login_page.dart';

//Derived from https://github.com/iamSahdeep/liquid_swipe_flutter/blob/master/example/lib/main.dart
class HomeWithDrawer extends StatefulWidget {
  @override
  _HomeWithDrawerState createState() => _HomeWithDrawerState();
}

class _HomeWithDrawerState extends State<HomeWithDrawer> {

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  LiquidController liquidController = LiquidController();

  //TODO - replace the following with liquidController eventually
  PageController pageController = PageController(initialPage: initialPage);

  @override
  Widget build(BuildContext context) {
    print('Build home with sidebar');
    Size mediaQuery = MediaQuery.of(context).size;

    List<Widget> pages=[ObservationsPage(),ObservationsPage(),ObservationsPage()];

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: MenuTitleProfileAppBar(
        appName: 'Pika Patrol',
        openMenuCallback: (){ _scaffoldKey.currentState.openDrawer(); },
        openProfileCallback: (){
          Navigator.push(context, TopRightScaleIn(widget: LoginScreen()));
        },
      ),
      body: Container(
        width: mediaQuery.width,
        child: Stack(
          children: <Widget>[
            PageView.builder(
              controller: pageController,
              itemCount: 3,
              itemBuilder: (context, position) => pages[position],
            ),
            /*LiquidSwipe(
              pages: <Container>[
                ObservationsPage(),
                Page2(),
                Page3(),
              ],
              enableLoop: true,
              fullTransitionValue: 300,
              enableSlideIcon: true,
              waveType: WaveType.liquidReveal,
              positionSlideIcon: 0.5,
              liquidController: liquidController,
              ignoreUserGestureWhileAnimating: true,
              disableUserGesture: true,
              //TODO - onPageChangeCallback: pageChangeCallback,
            ),*/
          ],
        ),
      ),
      bottomNavigationBar: StatsObservationsMapNavigationBar(pageController),
      drawer: ElasticDrawer(
        percentOfWidth: sidebarPercentWidthWhenOpen,
        animationDuration: sidebarAnimationDuration,
        pixelsShownWhenClosed: sidebarPixelsShownWhenClosed,
        archHeight: sidebarArchHeight,
      ),
    );
  }
}