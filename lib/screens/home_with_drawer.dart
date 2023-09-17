// ignore_for_file: depend_on_referenced_packages
import 'dart:io';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
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
import 'package:material_themes_widgets/utils/ui_utils.dart';
import 'package:pika_patrol/model/app_user.dart';
import 'package:pika_patrol/model/app_user_profile.dart';
import 'package:pika_patrol/model/observation.dart';
import 'package:pika_patrol/services/firebase_auth_service.dart';
import 'package:pika_patrol/services/firebase_database_service.dart';
import 'package:pika_patrol/utils/network_utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pika_patrol/screens/training_screens_pager.dart';
import 'observation_screen.dart';
import 'observations_screen.dart';

//TODO - CHRIS - these should be somewhere else
var navbarColor = Colors.white;
var navbarBgColor = Colors.transparent;
var navbarButtonColor = Colors.white;
var navbarIconColor = Colors.black45;

var navbarHeight = 50.0;
var navbarIconSize = 30.0;
var navbarAnimationDuration = 500;
var initialPage = 2;

class HomeWithDrawer extends StatefulWidget {

  const HomeWithDrawer({super.key});

  @override
  HomeWithDrawerState createState() => HomeWithDrawerState();
}

class HomeWithDrawerState extends State<HomeWithDrawer> {

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Key _registerKey = UniqueKey();
  final Key _loginKey = UniqueKey();
  final Key _editProfileKey = UniqueKey();
  final Key _editProfileNullKey = UniqueKey();
  final Key _profileKey = UniqueKey();
  final Key _nullProfileKey = UniqueKey();
  final Key _leftDrawerKey = UniqueKey();
  final Key _nullLeftDrawerKey = UniqueKey();

  //TODO - replace the following with liquidController eventually
  PageController pageController = PageController(initialPage: initialPage);
  LiquidController liquidController = LiquidController();

  bool showSignIn = true;
  bool loading = false;
  bool isEditingProfile = false;
  bool userAckedGeoTracking = false;

  String? email;
  String? password;
  String? firstName;
  String? lastName;
  String? tagline;
  String? pronouns;
  String? organization;
  String? address;
  String? city;
  String? state;
  String? zip;
  bool? frppOptIn;
  bool? rmwOptIn;
  bool? dzOptIn;

  @override
  Widget build(BuildContext context) {

    MediaQueryData mediaQuery = MediaQuery.of(context);
    Size size = mediaQuery.size;
    double width = size.width;
    double bottom = mediaQuery.viewInsets.bottom;

    //List<Widget> pages=[ObservationsPage()];

    AppUser? user = Provider.of<AppUser?>(context);
    AppUserProfile? userProfile = Provider.of<AppUserProfile?>(context);

    return Scaffold(
        key: _scaffoldKey,
        extendBodyBehindAppBar: true,
        extendBody: true,
        appBar: buildAppBar(context),
        body: buildBody(context, width),
        bottomNavigationBar: buildBottomNavigationBar(context, user),
        drawer: buildDrawer(context, user, userProfile, bottom),
        endDrawer: buildEndDrawer(context, user, userProfile, bottom)
    );
  }

  PreferredSizeWidget buildAppBar(BuildContext context) {
    return IconTitleIconAppBar(
      title: 'Pika Patrol',
      titleType: ThemeGroupType.MOP,
      leftIconClickedCallback: (){ _scaffoldKey.currentState?.openDrawer(); },
      leftIconType: ThemeGroupType.MOP,
      rightIconClickedCallback: (){ _scaffoldKey.currentState?.openEndDrawer(); },
      rightIconType: ThemeGroupType.MOP,
    );
  }

  Widget buildBody(BuildContext context, double width) {
    return SizedBox(
      width: width,
      child: Stack(
        children: <Widget>[
          PageView.builder(
              controller: pageController,
              itemCount: 1,
              itemBuilder: (context, position) => StreamBuilder<List<Observation>>(
                  stream: Provider.of<FirebaseDatabaseService>(context).observations,
                  builder: (context, snapshot) {
                    List<Observation>? observations = snapshot.hasData ? snapshot.data : null;//Provider.of<List<Observation>?>(context)
                    return ObservationsPage(observations ?? <Observation>[]);
                  })
          )
          /*LiquidSwipe(
              pages: <Container>[
                ObservationsPage(),
                Page2(),
                Page3(),
              ],
              enableLoop: true,
              fullTransitionValue: 300,
              slideIconWidget: const Icon(Icons.arrow_back_ios),
              waveType: WaveType.liquidReveal,
              positionSlideIcon: 0.5,
              liquidController: liquidController,
              ignoreUserGestureWhileAnimating: true,
              disableUserGesture: true,
              //TODO - onPageChangeCallback: pageChangeCallback,
            ),*/
        ],
      ),
    );
  }

  Widget buildBottomNavigationBar(BuildContext context, AppUser? user) {
    return CurvedNavigationBar (//TODO - migrate this into its own widget
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
        showGeoTrackingDialog(context, user);
        //TODO - combine these when we have more pages
/*
            pageController.animateToPage(
              index,
              duration: Duration(milliseconds: navbarAnimationDuration),
              curve: Curves.easeInOut
            );
*/
      },
      animationDuration: Duration(milliseconds: navbarAnimationDuration),
      animationCurve: Curves.easeInOut,
      //index: pageController.initialPage,
    );
  }

  Widget buildDrawer(BuildContext context, AppUser? user, AppUserProfile? userProfile, double bottom) {
    return SimpleClipPathDrawer(
      padding: EdgeInsets.fromLTRB(0, 0, 0, bottom),
      leftIconType: ThemeGroupType.MOP,
      leftIconClickedCallback: () => Navigator.pop(context),
      rightIconType: ThemeGroupType.MOP,
      rightIconClickedCallback: () => _scaffoldKey.currentState?.openEndDrawer(),
      clipPathType: ClipPathType.NONE,
      backgroundGradientType: BackgroundGradientType.MAIN_BG,
      child: HeaderList(
          [
            ListItemModel(title: "Colorado Pika Project", itemClickedCallback: () => launchInBrowser("http://www.pikapartners.org/")),
            ListItemModel(title: "Denver Zoo", itemClickedCallback: () => launchInBrowser("https://denverzoo.org/")),
            ListItemModel(title: "Rocky Mountain Wild", itemClickedCallback: () => launchInBrowser("https://rockymountainwild.org/")),
            ListItemModel(title: "If/Then", itemClickedCallback: () => launchInBrowser("http://www.ifthenshecan.org/")),
            ListItemModel(title: "Take Climate Action", itemClickedCallback: () => launchInBrowser("https://pikapartners.org/carbon/")),
            ListItemModel(title: "App Help and Info", itemClickedCallback: () => launchInBrowser("https://pikapartners.org/pika-patrol-tutorials/")),
            ListItemModel(title: "Identifying Pikas and Their Signs", itemClickedCallback: () => {
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (BuildContext context) =>
                      TrainingScreensPager(backClickedCallback: () => {
                        Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (BuildContext context) => const HomeWithDrawer())
                        )
                      })
                  )
              )
            })
          ],
          key: userProfile == null ? _nullLeftDrawerKey: _leftDrawerKey,
          imageUrl: "assets/images/pika3.jpg",
          avatarImageUrl: "assets/images/pika4.jpg",
          avatarTitle: userProfile == null ? "Login" : "${userProfile.firstName} ${userProfile.lastName}",
          avatarSubtitle: userProfile == null ? "" : userProfile.tagline,
          avatarClickedCallback: () => _scaffoldKey.currentState?.openEndDrawer(),
          cardElevationLevel: ElevationLevel.LOW,
          usePolygonAvatar: true,
          headerGradientType: BackgroundGradientType.PRIMARY,
          isHeaderSticky: false
      ),
    );
  }

  Widget buildEndDrawer(BuildContext context, AppUser? user, AppUserProfile? userProfile, double bottom) {

    final FirebaseAuthService firebaseAuthService = Provider.of<FirebaseAuthService>(context);
    final FirebaseDatabaseService firebaseDatabaseService = Provider.of<FirebaseDatabaseService>(context);

    return SimpleClipPathDrawer(
        padding: EdgeInsets.fromLTRB(0, 0, 0,bottom),
        widthPercent: 0.9,
        leftIconType: ThemeGroupType.MOP,
        leftIconClickedCallback: () => Navigator.pop(context),
        showRightIcon: isEditingProfile ? true : false,
        rightIconType: ThemeGroupType.MOP,
        rightIcon: Icons.close,
        rightIconClickedCallback: () => setState(() => isEditingProfile = false),
        clipPathType: ClipPathType.NONE,
        backgroundGradientType: BackgroundGradientType.PRIMARY,
        child: SafeArea(
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                if (user != null) ... [
                  buildProfileScreen(context, firebaseAuthService, firebaseDatabaseService, user, userProfile),
                ] else if(showSignIn) ... [
                  buildLoginScreen(context, firebaseAuthService),
                ] else ... [
                  buildRegisterScreen(context, firebaseAuthService),
                ],
                if(loading) ... [
                  buildLoadingOverlay(context)
                ]
              ],
            )
        )
    );
  }

  Widget buildProfileScreen(
      BuildContext context,
      FirebaseAuthService firebaseAuthService,
      FirebaseDatabaseService firebaseDatabaseService,
      AppUser? user,
      AppUserProfile? userProfile
  ) {

    var editProfileKey = userProfile == null ? _editProfileNullKey : _editProfileKey;
    var viewProfileKey = userProfile == null ? _nullProfileKey : _profileKey;

    return ProfileScreen(
      //_nullProfileKey and _profileKey need to be different or else the ProfileScreen will not update without first receiving user input
      //also, one key for null and one for not null because, without the distinction, and if we use a new uniqueKey each time, the keyboard
      //pops up and then immediately pops back down when trying to type text
      key: isEditingProfile ? editProfileKey : viewProfileKey,
      isEditMode: isEditingProfile,
      onTapLogout: () async {
        setState(() { showSignIn = true; });//makes more sense to show signIn than register after signOut
        await firebaseAuthService.signOut();
      },
      onTapEdit: () => setState(() => isEditingProfile = true),
      onTapSave: () async {
        setState(() => loading = true);

        await firebaseDatabaseService.updateUserProfile(
            firstName ?? userProfile?.firstName ?? "NO USER PROFILE",
            lastName ?? userProfile?.lastName ?? "",
            tagline ?? userProfile?.tagline ?? "",
            pronouns ?? userProfile?.pronouns ?? "",
            organization ?? userProfile?.organization ?? "",
            address ?? userProfile?.address ?? "",
            city ?? userProfile?.city ?? "",
            state ?? userProfile?.state ?? "",
            zip ?? userProfile?.zip ?? "",
            frppOptIn ?? userProfile?.frppOptIn ?? false,
            rmwOptIn ?? userProfile?.rmwOptIn ?? false,
            dzOptIn ?? userProfile?.dzOptIn ?? false
        );
        setState(() => isEditingProfile = false);
        setState(() => loading = false);
      },
      onTapDelete: () async {
        Widget okButton = TextButton(
          child: const Text("OK"),
          onPressed:  () async {
            //Hide the alert
            Navigator.pop(context, true);

            setState(() { showSignIn = true; });//makes more sense to show signIn than register after signOut

            await firebaseAuthService.deleteUser();

            // Don't sign out before deleting user because the user must be signed into to delete themselves
            await firebaseAuthService.signOut();
            showToast("Account Deleted");
          },
        );

        AlertDialog alert = AlertDialog(
          title: const Text("Delete Account"),
          content: const Text("Are you sure you want to delete your account.? This cannot be undone. Your uploaded observations will remain on the server. Local observations that have not been uploaded will be removed from your device."),
          actions: [
            okButton,
          ],
        );

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return alert;
          },
        );
      },
      showEmail: false, //TODO - need to wait until we allow the user to change their email
      showPassword: false, //TODO - need to wait until we allow the user to change their password
      firstName: userProfile?.firstName ?? "" ,
      lastName: userProfile?.lastName ?? "",
      tagline: userProfile?.tagline ?? "",
      pronouns: userProfile?.pronouns ?? "",
      organization: userProfile?.organization ?? "",
      address: userProfile?.address ?? "",
      city: userProfile?.city ?? "",
      state: userProfile?.state ?? "",
      zip: userProfile?.zip ?? "",
      onEmailChangedCallback: (value) => { email = value },
      onPasswordChangedCallback: (value) => { password = value },
    );
  }

  Widget buildLoginScreen(BuildContext context, FirebaseAuthService firebaseAuthService) {
    return LoginRegisterScreen(
      key: _loginKey,
      isLogin: true,
      showLabels: false,
      onPasswordChangedCallback: (value) => { password = value },
      onEmailChangedCallback: (value) => { email = value },
      onTapLogin: () async {

        var trimmedEmail = email?.trim() ?? "";
        var trimmedPassword = password?.trim() ?? "";

        if (trimmedEmail.isEmpty) {
          showToast("Email cannot be empty");
          return;
        } else if (trimmedPassword.isEmpty) {
          showToast("Password cannot be empty");
          return;
        }

        setState(() => loading = true);

        dynamic result = await firebaseAuthService.signInWithEmailAndPassword(trimmedEmail, trimmedPassword);
        //dynamic result = await _auth.signInWithGoogle();

        if(result == null) {
          // Need to determine if this was because there is no internet or if the sign in really wasn't accepted
          try {
            final result = await InternetAddress.lookup('google.com');
            if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
              showToast("Could not sign in with those credentials");
            }
          } on SocketException catch (_) {
            showToast("Can not sign in. Not connected to internet.");
          }
        } else {
          showToast("Successfully Logged In");
        }

        setState((){ loading = false; });
      },
      onTapRegister: () => {
        setState(() => showSignIn = false)
      },
    );
  }

  Widget buildRegisterScreen(BuildContext context, FirebaseAuthService firebaseAuthService) {
    return LoginRegisterScreen(
      key: _registerKey,
      isLogin: false,
      showLabels: false,
      onPasswordChangedCallback: (value) => { password = value },
      onEmailChangedCallback: (value) => { email = value },
      onTapLogin: () => { setState(() => showSignIn = true) },
      onTapRegister: () async {

        var trimmedEmail = email?.trim() ?? "";
        var trimmedPassword = password?.trim() ?? "";
        var trimmedFirstName = firstName?.trim() ?? "";
        var trimmedLastName = lastName?.trim() ?? "";
        var trimmedZip = zip?.trim() ?? "";

        if (trimmedEmail.isEmpty ||
            trimmedPassword.isEmpty ||
            trimmedFirstName.isEmpty ||
            trimmedLastName.isEmpty ||
            trimmedZip.isEmpty
        ) {
          return;
        }

        setState(() => loading = true);

        dynamic result = await firebaseAuthService.registerWithEmailAndPassword(
            trimmedEmail,
            trimmedPassword,
            trimmedFirstName,
            trimmedLastName,
            tagline ?? "",
            pronouns ?? "",
            organization ?? "",
            address ?? "",
            city ?? "",
            state ?? "",
            zip ?? "",
            frppOptIn ?? false,
            rmwOptIn ?? false,
            dzOptIn ?? false
        );

        if(result == null) {
          // Need to determine if this was because there is no internet or if the sign in really wasn't accepted
          try {
            final result = await InternetAddress.lookup('google.com');
            if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
              showToast("Could not register with those credentials");
            }
          } on SocketException catch (_) {
            showToast("Can not register. Not connected to internet.");
          }
        } else {
          showToast("Successfully Registered");
        }
        setState(() => loading = false);
      },
    );
  }

  Widget buildLoadingOverlay(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white.withOpacity(0.70),
      child: Loading(),
    );
  }

  showObservationScreen(BuildContext contxt, AppUser? user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ObservationScreen(Observation(observerUid: user?.uid, date: DateTime.now())),
      ),
    );
  }

  showGeoTrackingDialog(BuildContext context, AppUser? user) async {
    final prefs = await SharedPreferences.getInstance();
    final userAcked = prefs.getBool('userAckGeo');

    if (userAcked != null && userAcked == true) {
      if (mounted) showObservationScreen(context, user);
    } else {
      Widget launchButton = TextButton(
        child: const Text("OK"),
        onPressed:  () async {
          Navigator.pop(context, true);

          Permission.location.request();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('userAckGeo', true);

          if (mounted) showObservationScreen(context, user);
        },
      );
      // set up the AlertDialog
      AlertDialog alert = AlertDialog(
        title: const Text("Location Tracking"),
        content: const Text("Pika Patrol records the current location when an observation is recorded in order to determine where the observation occurred. The observation, including the saved location, is sent in the background to our servers when WiFi is available."),
        actions: [
          launchButton,
        ],
      );
      // show the dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return alert;
          },
        );
      }
    }
  }
}