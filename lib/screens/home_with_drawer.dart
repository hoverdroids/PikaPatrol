import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/appbars/icon_title_icon_appbar.dart';
import 'package:material_themes_widgets/clippaths/clip_paths.dart';
import 'package:material_themes_widgets/drawers/simple_clith_path_drawer.dart';
import 'package:material_themes_widgets/forms/loading.dart';
import 'package:material_themes_widgets/lists/header_list.dart';
import 'package:material_themes_widgets/lists/list_item_model.dart';
import 'package:material_themes_widgets/screens/login_register_screen.dart';
import 'package:material_themes_widgets/screens/profile_screen.dart';
import 'package:pika_patrol/model/app_user.dart';
import 'package:pika_patrol/model/app_user_profile.dart';
import 'package:pika_patrol/model/observation.dart';
import 'package:pika_patrol/screens/observations_screen.dart';
import 'package:pika_patrol/screens/training_screens_pager.dart';
import 'package:pika_patrol/services/firebase_auth_service.dart';
import 'package:pika_patrol/services/firebase_database_service.dart';
import 'package:pika_patrol/utils/network_utils.dart';
import 'package:provider/provider.dart';
import 'observation_screen.dart';

var navbarColor = Colors.white;
var navbarBgColor = Colors.transparent;
var navbarButtonColor = Colors.white;
var navbarIconColor = Colors.black45;

var navbarHeight = 50.0;
var navbarIconSize = 30.0;
var navbarAnimationDuration = 500;
var initialPage = 2;

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

  final FirebaseAuthService _auth = FirebaseAuthService();
  bool showSignIn = true;
  bool loading = false;
  bool isEditingProfile = false;

  String email;
  String password;
  String firstName;
  String lastName;
  String tagline;
  String pronouns;
  String organization;
  String address;
  String city;
  String state;
  String zip;
  bool frppOptIn;
  bool rmwOptIn;
  bool dzOptIn;

  final Key _registerKey = new UniqueKey();
  final Key _loginKey = new UniqueKey();
  final Key _editProfileKey = new UniqueKey();
  final Key _editProfileNullKey = new UniqueKey();
  final Key _profileKey = new UniqueKey();
  final Key _nullProfileKey = new UniqueKey();
  final Key _leftDrawerKey = new UniqueKey();
  final Key _nullLeftDrawerKey = new UniqueKey();

  @override
  Widget build(BuildContext context) {

    Size mediaQuery = MediaQuery.of(context).size;
    //List<Widget> pages=[ObservationsPage()];

    final user = Provider.of<AppUser>(context);

    return StreamProvider<List<Observation>>.value(
      value: FirebaseDatabaseService(uid: user != null ? user.uid : null).observations,
      child: Scaffold(
        key: _scaffoldKey,
        extendBodyBehindAppBar: true,
        extendBody: true,
        appBar: IconTitleIconAppBar(
          title: 'Pika Patrol',
          titleType: ThemeGroupType.MOP,
          leftIconClickedCallback: (){ _scaffoldKey.currentState.openDrawer(); },
          leftIconType: ThemeGroupType.MOP,
          rightIconClickedCallback: (){ _scaffoldKey.currentState.openEndDrawer(); },
          rightIconType: ThemeGroupType.MOP,
        ),
        body: Container(
          width: mediaQuery.width,
          child: Stack(
            children: <Widget>[
              PageView.builder(
                controller: pageController,
                itemCount: 1,
                itemBuilder: (context, position) => ObservationsPage(Provider.of<List<Observation>>(context) ?? <Observation>[]),
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
        bottomNavigationBar: CurvedNavigationBar (//TODO - migrate this into its own widget
          color: navbarColor,
          backgroundColor: navbarBgColor,
          buttonBackgroundColor: navbarButtonColor,
          height: navbarHeight,
          items: <Widget>[
            //Icon(Icons.show_chart, size: navbarIconSize, color: navbarIconColor),
            Icon(Icons.loupe, size: navbarIconSize, color: navbarIconColor),
            //Icon(Icons.map, size: navbarIconSize, color: navbarIconColor),
          ],
          onTap: (index) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ObservationScreen(Observation(observerUid: user != null ? user.uid : null, date: new DateTime.now())),
              ),
            );
            //TODO - combine these when we have more pages
            /*pageController.animateToPage(
          index,
          duration: Duration(milliseconds: navbarAnimationDuration),
          curve: Curves.easeInOut);*/
          },
          animationDuration: Duration(milliseconds: navbarAnimationDuration),
          animationCurve: Curves.easeInOut,
          //index: pageController.initialPage,
        ),
        drawer: SimpleClipPathDrawer(
          leftIconType: ThemeGroupType.MOP,
          leftIconClickedCallback: () => Navigator.pop(context),
          rightIconType: ThemeGroupType.MOP,
          rightIconClickedCallback: () => _scaffoldKey.currentState.openEndDrawer(),
          child: StreamBuilder<AppUserProfile>(
            stream: FirebaseDatabaseService(uid: user != null ? user.uid : null).userProfile,
            builder: (context, snapshot) {
              AppUserProfile userProfile = snapshot.hasData ? snapshot.data : null;
              return HeaderList(
                [
                  ListItemModel(title: "Colorado Pika Project", itemClickedCallback: () => launchInBrowser("http://www.pikapartners.org/")),
                  ListItemModel(title: "Denver Zoo", itemClickedCallback: () => launchInBrowser("https://denverzoo.org/")),
                  ListItemModel(title: "Rocky Mountain Wild", itemClickedCallback: () => launchInBrowser("https://rockymountainwild.org/")),
                  ListItemModel(title: "Carbon", itemClickedCallback: () => launchInBrowser("https://pikapartners.org/carbon/")),
                  ListItemModel(title: "Identifying Pikas and Their Signs", itemClickedCallback: () => {
                    Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (BuildContext context) =>
                            TrainingScreensPager(backClickedCallback: () => {
                              Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (BuildContext context) => HomeWithDrawer())
                              )
                            })
                        )
                    )
                  })
                ],
                key: userProfile == null ? _nullLeftDrawerKey: _leftDrawerKey,
                imageUrl: "assets/images/pika3.jpg",
                avatarImageUrl: "assets/images/pika4.jpg",
                avatarTitle: userProfile == null ? "Login" : userProfile.firstName + " " + userProfile.lastName,
                avatarSubtitle: userProfile == null ? "" : userProfile.tagline,
                avatarClickedCallback: () => _scaffoldKey.currentState.openEndDrawer(),
                cardElevationLevel: ElevationLevel.LOW,
                usePolygonAvatar: true,
                headerGradientType: BackgroundGradientType.PRIMARY,
                isHeaderSticky: false
              );
            },
          ),
          clipPathType: ClipPathType.NONE,
          backgroundGradientType: BackgroundGradientType.MAIN_BG,
        ),
        endDrawer: SimpleClipPathDrawer(
            leftIconType: ThemeGroupType.MOP,
            leftIconClickedCallback: () => Navigator.pop(context),
            showRightIcon: isEditingProfile ? true : false,
            rightIconType: ThemeGroupType.MOP,
            rightIcon: Icons.close,
            rightIconClickedCallback: () => setState(() => isEditingProfile = false),
            child: SafeArea(
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    if (user != null) ... [
                      StreamBuilder<AppUserProfile>(
                          stream: FirebaseDatabaseService(uid: user != null ? user.uid : null).userProfile,
                          builder: (context, snapshot){

                            AppUserProfile userProfile = snapshot.hasData ? snapshot.data : null;

                            return ProfileScreen(
                              //_nullProfileKey and _profileKey need to be different or else the ProfileScreen will not update without first receiving user input
                              //also, one key for null and one for not null because, without the distinction, and if we use a new uniqueKey each time, the keyboard
                              //pops up and then immediately pops back down when trying to type text
                              key: isEditingProfile ? (userProfile == null ? _editProfileNullKey : _editProfileKey) : (userProfile == null ? _nullProfileKey : _profileKey),
                              isEditMode: isEditingProfile,
                              onTapLogout: () async {
                                setState(() { showSignIn = true; });//makes more sense to show signIn than register after signOut
                                await _auth.signOut();
                              },
                              onTapEdit: () => setState(() => isEditingProfile = true),
                              onTapSave: () async {
                                setState(() => loading = true);
                                dynamic result = await FirebaseDatabaseService(uid: user.uid).updateUserProfile(
                                    firstName ?? userProfile.firstName,
                                    lastName ?? userProfile.lastName,
                                    tagline ?? userProfile.tagline,
                                    pronouns ?? userProfile.pronouns,
                                    organization ?? userProfile.organization,
                                    address ?? userProfile.address,
                                    city ?? userProfile.city,
                                    state ?? userProfile.state,
                                    zip ?? userProfile.zip,
                                    frppOptIn ?? userProfile.frppOptIn,
                                    rmwOptIn ?? userProfile.rmwOptIn,
                                    dzOptIn ?? userProfile.dzOptIn
                                );
                                setState(() => isEditingProfile = false);
                                setState(() => loading = false);
                              },
                              showEmail: false, //TODO - need to wait until we allow the user to change their email
                              showPassword: false, //TODO - need to wait until we allow the user to change their password
                              firstName: userProfile != null ? userProfile.firstName : "" ,
                              lastName: userProfile != null ? userProfile.lastName : "",
                              tagline: userProfile != null ? userProfile.tagline : "",
                              pronouns: userProfile != null ? userProfile.pronouns : "",
                              organization: userProfile != null ? userProfile.organization : "",
                              address: userProfile != null ? userProfile.address : "",
                              city: userProfile != null ? userProfile.city : "",
                              state: userProfile != null ? userProfile.state : "",
                              zip: userProfile != null ? userProfile.zip : "",
                              onEmailChangedCallback: (value) => { email = value },
                              onPasswordChangedCallback: (value) => { password = value },
                              onFirstNameChangedCallback: (value) => { firstName = value },
                              onLastNameChangedCallback: (value) => { lastName = value },
                              onTaglineChangedCallback: (value) => { tagline = value },
                              onPronounsChangedCallback: (value) => { pronouns = value },
                              onOrganizationChangedCallback: (value) => { organization = value },
                              onAddressChangedCallback: (value) => { address = value },
                              onCityChangedCallback: (value) => { city = value },
                              onStateChangedCallback: (value) => { state = value },
                              onZipChangedCallback: (value) => { zip = value },
                            );
                          }
                      )
                    ] else if(showSignIn) ... [
                      LoginRegisterScreen(
                        key: _loginKey,
                        isLogin: true,
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
                          setState(() => showSignIn = false)
                        },
                      ),
                    ] else ... [
                      LoginRegisterScreen(
                        key: _registerKey,
                        isLogin: false,
                        showLabels: false,
                        onPasswordChangedCallback: (value) => { password = value },
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
                          dynamic result = await _auth.registerWithEmailAndPassword(
                              email,
                              password,
                              firstName,
                              lastName,
                              tagline,
                              pronouns,
                              organization,
                              address,
                              city,
                              state,
                              zip,
                              frppOptIn,
                              rmwOptIn,
                              dzOptIn
                          );
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
            clipPathType: ClipPathType.NONE,
            backgroundGradientType: BackgroundGradientType.PRIMARY
        ),
      ),
      catchError: (_, e) => showErr(e.toString()),
    );
  }

  List<Observation> showErr(String e) {
    print("ErrorSon" + e);
    return <Observation>[];
  }
}