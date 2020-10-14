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
import 'package:material_themes_widgets/screens/login_register_screen.dart';
import 'package:material_themes_widgets/screens/profile_screen.dart';
import 'package:pika_joe/model/user.dart';
import 'package:pika_joe/model/user_profile.dart';
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
  bool showSignIn = true;
  bool loading = false;
  bool isEditingProfile = false;

  String email = "";
  String password = "";
  String firstName = "";
  String lastName = "";
  String tagline = "";
  String pronouns = "";
  String organization = "";
  String address = "";
  String city = "";
  String state = "";
  String zip = "";
  bool frppOptIn = false;
  bool rmwOptIn = false;
  bool dzOptIn = false;

  final Key _registerKey = new GlobalKey();
  final Key _loginKey = new GlobalKey();
  final Key _editProfileKey = new GlobalKey();
  final Key _profileKey = new GlobalKey();

  @override
  Widget build(BuildContext context) {

    Size mediaQuery = MediaQuery.of(context).size;
    List<Widget> pages=[ObservationsPage(),ObservationsPage(),ObservationsPage()];

    final user = Provider.of<User>(context);

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
        child: SafeArea(
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              if (user != null) ... [
                ProfileScreen(
                  key: isEditingProfile ? _editProfileKey : _profileKey,
                  isEditMode: isEditingProfile,
                  onTapLogout: () async {
                    await _auth.signOut();
                  },
                  onTapEdit: () => setState(() => isEditingProfile = true),
                  onTapSave: () async {
                    setState(() => isEditingProfile = false);
                  },
                ),
              ] else if(showSignIn) ... [
                LoginRegisterScreen(
                  key: _loginKey,
                  isLogin: true,
                  showLabels: false,
                  onPasswordChangedCallback: (value) => { password = value, print("PW:" + password) },
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
                    setState((){ loading = false; });
                  },
                  onTapRegister: () => {
                    setState(() => showSignIn = false),
                    print("1ShowSignIn: " + showSignIn.toString()),
                    this.build(context)
                  },
                ),
              ] else ... [
                LoginRegisterScreen(
                  key: _registerKey,
                  isLogin: false,
                  showLabels: false,
                  onPasswordChangedCallback: (value) => { password = value, print("PW:" + password) },
                  onEmailChangedCallback: (value) => { email = value },
                  onFirstNameChangedCallback: (value) => { firstName = value },
                  onLastNameChangedCallback: (value) => { lastName = value },
                  onTaglineChangedCallback: (value) => { tagline = value },
                  onPronounsChangedCallback: (value) => { pronouns = value },
                  onOrganizationChangedCallback: (value) => { organization = value },
                  onAddressChangedCallback: (value) => { address = value },
                  onCityChangedCallback: (value) => { city = value },
                  onStateChangedCallback: (value) => { state = value },
                  onZipChangedCallback: (value) => { zip = value },
                  onTapLogin: () => { setState(() => showSignIn = true) },
                  onTapRegister: () async {
                    setState(() => loading = true);
                    var userProfile = UserProfile(firstName, lastName,
                        tagline: tagline,
                        pronouns: pronouns,
                        organization: organization,
                        address: address,
                        city: city,
                        state: state,
                        zip: zip,
                        frppOptIn: frppOptIn,
                        rmwOptIn: rmwOptIn,
                        dzOptIn: dzOptIn
                    );
                    dynamic result = await _auth.registerWithEmailAndPassword(email, password, userProfile);
                    if(result == null) {
                      Fluttertoast.showToast(
                          msg: "Could not register in with those credentials",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.CENTER,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.teal,//TODO - need to use Toast with context to link to the primary color
                          textColor: Colors.white,
                          fontSize: 16.0
                      );
                    } else {
                      Fluttertoast.showToast(
                          msg: "Successfully Registered",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.CENTER,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.teal,
                          //TODO - need to use Toast with context to link to the primary color
                          textColor: Colors.white,
                          fontSize: 16.0
                      );
                    }
                    setState(() => loading = false);
                  },
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
          )
        ),
        padding: 0.0,
        clipPathType: ClipPathType.NONE,
        backgroundGradientType: BackgroundGradientType.PRIMARY
      ),
    );
  }
}