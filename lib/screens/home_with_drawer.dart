import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/appbars/menu_title_profile_appbar.dart';
import 'package:material_themes_widgets/clippaths/clip_paths.dart';
import 'package:material_themes_widgets/drawers/simple_clith_path_drawer.dart';
import 'package:material_themes_widgets/lists/list_item_model.dart';
import 'package:material_themes_widgets/lists/scaling_items_list.dart';
import 'package:material_themes_widgets/screens/login_screen.dart';
import 'package:pika_joe/screens/observations_page.dart';
import 'package:pika_joe/styles/styles.dart';
import 'package:pika_joe/widget/navigation/stats_observations_map_navigationbar.dart';

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
        title: 'Pika Patrol',
        openMenuCallback: (){ _scaffoldKey.currentState.openDrawer(); },
        openProfileCallback: (){ _scaffoldKey.currentState.openEndDrawer(); },
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
      drawer: SimpleClipPathDrawer(
        child: ScalingItemsList(
            "assets/pika3.jpg",
            [
              ListItemModel("Front Range Pika Project", Icons.add, iconClickedCallback: () => print("Clicked item 1")),
              ListItemModel("Denver Zoo", Icons.account_circle, iconClickedCallback: () => print("Clicked item 1")),
              ListItemModel("Rocky Mountain Wild", Icons.ac_unit, iconClickedCallback: () => print("Clicked item 1")),
            ]
        ),
        padding: 0.0,
        clipPathType: ClipPathType.NONE,
        backgroundGradientType: BackgroundGradientType.MAIN_BG,
      ),
      endDrawer: SimpleClipPathDrawer(
        child: LoginScreen(),
        padding: 0.0,
        clipPathType: ClipPathType.NONE,
        backgroundGradientType: BackgroundGradientType.MAIN_BG,
      ),
    );
  }
}