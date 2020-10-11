import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/appbars/menu_title_profile_appbar.dart';
import 'package:material_themes_widgets/clippaths/clip_paths.dart';
import 'package:material_themes_widgets/drawers/simple_clith_path_drawer.dart';
import 'package:material_themes_widgets/forms/loading.dart';
import 'package:material_themes_widgets/lists/header_list.dart';
import 'package:material_themes_widgets/lists/list_item_model.dart';
import 'package:material_themes_widgets/screens/login_screen.dart';
import 'package:material_themes_widgets/screens/profile_screen.dart';
import 'package:pika_joe/model/user.dart';
import 'package:pika_joe/screens/observations_page.dart';
import 'package:pika_joe/screens/training/training_screens_pager.dart';
import 'package:pika_joe/services/firebase_auth_service.dart';
import 'package:pika_joe/styles/styles.dart';
import 'package:pika_joe/utils/network_utils.dart';
import 'package:pika_joe/widget/navigation/stats_observations_map_navigationbar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

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

  final FirebaeAuthService _auth = FirebaeAuthService();
  bool loading = false;
  String email = "";
  String password = "";
  bool showSignIn = true;

  @override
  Widget build(BuildContext context) {

    Size mediaQuery = MediaQuery.of(context).size;
    List<Widget> pages=[ObservationsPage(),ObservationsPage(),ObservationsPage()];

    //TODO - final user = Provider.of<User>(context);

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
        leftIconType: ThemeGroupType.MOP,
        leftIconClickedCallback: () => Navigator.pop(context),
        rightIconType: ThemeGroupType.MOP,
        rightIconClickedCallback: () => _scaffoldKey.currentState.openEndDrawer(),
        child: HeaderList(
          [
            ListItemModel(title: "Front Range Pika Project", itemClickedCallback: () => launchInBrowser("http://www.pikapartners.org/")),
            ListItemModel(title: "Denver Zoo", itemClickedCallback: () => launchInBrowser("https://denverzoo.org/")),
            ListItemModel(title: "Rocky Mountain Wild", itemClickedCallback: () => launchInBrowser("https://rockymountainwild.org/")),
            ListItemModel(title: "Training", itemClickedCallback: () => {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (BuildContext context) => TrainingScreensPager())
              )
            })
          ],
          imageUrl: "assets/pika3.jpg",
          avatarImageUrl: "assets/pika4.jpg",
          avatarTitle: "Chris Sprague",
          avatarSubtitle: "Lead Developer",
          cardElevationLevel: ElevationLevel.LOW,
          usePolygonAvatar: true,
          headerGradientType: BackgroundGradientType.PRIMARY,
        ),
        padding: 0.0,
        clipPathType: ClipPathType.NONE,
        backgroundGradientType: BackgroundGradientType.MAIN_BG,
      ),
      endDrawer: SimpleClipPathDrawer(
        leftIconType: ThemeGroupType.MOP,
        leftIconClickedCallback: () => Navigator.pop(context),
        showRightIcon: false,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            if(showSignIn) ... [
              LoginScreen(
                showForgots: false,
                showLabels: false,
                onPasswordChangedCallback: (value) => { password = value },
                onEmailChangedCallback: (value) => { email = value },
                onTapLogin: () async {
                  setState(() => loading = true);
                  dynamic result = await _auth.signInWithEmailAndPassword(email, password);
                  if(result == null) {
                    Fluttertoast.showToast(
                        msg: "Could not sign in with those credentials",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.CENTER,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.teal,//TODO - need to use Toast with context to link to the primary color
                        textColor: Colors.white,
                        fontSize: 16.0
                    );
                    setState((){
                      loading = false;
                    });
                    //TODO - our previous setup says, "once the user is signed in, the home page is displayed via the stream"
                  } else {
                    Fluttertoast.showToast(
                        msg: "Successfully Logged In",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.CENTER,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.teal,//TODO - need to use Toast with context to link to the primary color
                        textColor: Colors.white,
                        fontSize: 16.0
                    );
                  }
                },
                onTapRegister: () => { setState(() => showSignIn = !showSignIn) },
              ),
            ] else ... [
              ProfileScreen(
                onTapLogin: () => { setState(() => showSignIn = !showSignIn) },
              ),
            ],
            if(loading) ... [
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.white.withOpacity(0.70),
                child: Loading(),
              )
            ]
          ],
        ),
        padding: 0.0,
        clipPathType: ClipPathType.NONE,
        backgroundGradientType: BackgroundGradientType.PRIMARY
      ),
    );
  }
}