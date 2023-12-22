// ignore_for_file: depend_on_referenced_packages
import 'dart:io';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:language_code_icons/language_code_icons.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/appbars/icon_title_icon_icon_appbar.dart';
import 'package:material_themes_widgets/clippaths/clip_paths.dart';
import 'package:material_themes_widgets/defaults/dimens.dart';
import 'package:material_themes_widgets/drawers/simple_clip_path_drawer.dart';
import 'package:material_themes_widgets/forms/loading.dart';
import 'package:material_themes_widgets/lists/header_list.dart';
import 'package:material_themes_widgets/lists/list_item_model.dart';
import 'package:material_themes_widgets/screens/login_register_screen.dart';
import 'package:material_themes_widgets/screens/profile_screen.dart';
import 'package:material_themes_widgets/utils/ui_utils.dart';
import 'package:pika_patrol/l10n/l10n.dart';
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
import '../model/firebase_registration_result.dart';
import '../services/settings_service.dart';
import '../utils/constants.dart';
import 'observation_screen.dart';
import 'observations_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

  String? editedEmail;
  String? editedPassword;
  String? editedFirstName;
  String? editedLastName;
  String? editedTagline;
  String? editedPronouns;
  String? editedOrganization;
  String? editedAddress;
  String? editedCity;
  String? editedState;
  String? editedZip;
  bool? editedFrppOptIn;
  bool? editedRmwOptIn;
  bool? editedDzOptIn;

  @override
  Widget build(BuildContext context) {

    MediaQueryData mediaQuery = MediaQuery.of(context);
    Size size = mediaQuery.size;
    double width = size.width;
    double bottom = mediaQuery.viewInsets.bottom;

    //List<Widget> pages=[ObservationsPage()];

    AppUser? user = Provider.of<AppUser?>(context);
    AppUserProfile? userProfile = Provider.of<AppUserProfile?>(context);

    var forceProfileOpen = user != null && userProfile != null && !userProfile.areRequiredFieldsValid();

    //If the user signed in and the user profile hasn't been filled out, force the profile open
    //This should only happen when the app is opened and the user is signed in, so the profile screen isn't displayed yet.
    if (forceProfileOpen) {
      isEditingProfile = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scaffoldKey.currentState?.openEndDrawer();
      });
    }

    return Scaffold(
        key: _scaffoldKey,
        extendBodyBehindAppBar: true,
        extendBody: true,
        appBar: buildAppBar(context),
        body: buildBody(context, width),
        bottomNavigationBar: buildBottomNavigationBar(context, user),
        drawer: buildDrawer(context, user, userProfile, bottom),
        endDrawer: buildEndDrawer(context, user, userProfile, bottom),
        onEndDrawerChanged: (isOpen) {
          // developer.log("IsOpen:$isOpen");

          //If the user tries to close the profile screen with an incomplete profile, force it back open
          if (isOpen && forceProfileOpen && !isEditingProfile) {
            // developer.log("Setting isEditingProfile true. IsOpen:$isOpen, ForceProfileOpen:$forceProfileOpen");
            setState((){ isEditingProfile = true; });
          } else if (forceProfileOpen && !isOpen) {
            // developer.log("Calling openEndDrawer and Toast. IsOpen:$isOpen, ForceProfileOpen:$forceProfileOpen");
            _scaffoldKey.currentState?.openEndDrawer();
            showToast(AppLocalizations.of(context)?.enterRequiredFields ?? "ERROR");
          }
        },
    );
  }

  PreferredSizeWidget buildAppBar(BuildContext context) {
    var locale = Provider.of<SettingsService>(context, listen: false).locale;
    var localeIcon = locale == L10n.ENGLISH ? LanguageCodeIcons.EN : LanguageCodeIcons.ES;

    return IconTitleIconIconAppBar(
      title: AppLocalizations.of(context)?.appName ?? "ERROR",
      titleType: ThemeGroupType.MOP,
      leftIconClickedCallback: (){ _scaffoldKey.currentState?.openDrawer(); },
      leftIconType: ThemeGroupType.MOP,
      rightIconClickedCallback: (){ _scaffoldKey.currentState?.openEndDrawer(); },
      rightIconType: ThemeGroupType.MOP,
      rightIcon2: localeIcon,
      rightIcon2ClickedCallback: (){ _toggleLanguage(); },
      rightIcon2Type: ThemeGroupType.MOP,
    );
  }

  _toggleLanguage() async {
    var settingsService = Provider.of<SettingsService>(context, listen: false);
    var locale = settingsService.locale;
    settingsService.updateLocale(locale == L10n.ENGLISH ? L10n.SPANISH : L10n.ENGLISH);
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
                if (observations != null) {
                  for (var observation in  observations) {
                    observation.buttonText = AppLocalizations.of(context)?.viewObservation;
                  }
                }

                return ObservationsPage(observations ?? <Observation>[]);
              }
            )
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
    var okText = AppLocalizations.of(context)?.ok ?? "ERROR";
    var locationTrackingDialogTitleText = AppLocalizations.of(context)?.locationTrackingDialogTitle ?? "ERROR";
    var locationTrackingDialogDetailsText = AppLocalizations.of(context)?.locationTrackingDialogDetails ?? "ERROR";

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
        showGeoTrackingDialog(context, user, okText, locationTrackingDialogTitleText, locationTrackingDialogDetailsText);
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

    var avatarTitle = AppLocalizations.of(context)?.login ?? "ERROR";
    var avatarSubtitle = "";
    if (user != null) {
      if (userProfile == null) {
        //A profile has not been initialized
        avatarTitle = AppLocalizations.of(context)?.emptyUserProfile ?? "ERROR";
      } else {
        //A profile has been initialized
        avatarTitle = "${userProfile.firstName} ${userProfile.lastName}";
        avatarSubtitle = userProfile.tagline;
      }
    }

    return SimpleClipPathDrawer(
      padding: EdgeInsets.fromLTRB(0, 0, 0, bottom),
      widthPercent: .92,
      leftIconType: ThemeGroupType.MOP,
      leftIconClickedCallback: () => Navigator.pop(context),
      rightIconType: ThemeGroupType.MOP,
      rightIconClickedCallback: () => _scaffoldKey.currentState?.openEndDrawer(),
      clipPathType: ClipPathType.NONE,
      backgroundGradientType: BackgroundGradientType.MAIN_BG,
      child: HeaderList(
          [
            ListItemModel(title: AppLocalizations.of(context)?.appHelpAndInfo, itemClickedCallback: () => launchInBrowser(AppLocalizations.of(context)?.appHelpAndInfoUrl ?? "")),
            ListItemModel(title: AppLocalizations.of(context)?.identifyingPikasAndTheirSigns, itemClickedCallback: () => {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (BuildContext context) =>
                  TrainingScreensPager(backClickedCallback: () => {
                    Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (BuildContext context) => const HomeWithDrawer())
                    )
                  })
                )
              )
            }),
            ListItemModel(title: AppLocalizations.of(context)?.mapOfPikaObservations, itemClickedCallback: () => launchInBrowser(AppLocalizations.of(context)?.mapOfPikaObservationsUrl ?? "")),
            ListItemModel(title: AppLocalizations.of(context)?.takeClimateAction, itemClickedCallback: () => launchInBrowser(AppLocalizations.of(context)?.takeClimateActionUrl ?? "")),
            ListItemModel(title: AppLocalizations.of(context)?.sponsorsAndSupport, titleType: ThemeGroupType.SOM),
            ListItemModel(title: AppLocalizations.of(context)?.coloradoPikaProject, itemClickedCallback: () => launchInBrowser(AppLocalizations.of(context)?.coloradoPikaProjectUrl ?? ""), margin: indentationLevel1),
            ListItemModel(title: AppLocalizations.of(context)?.rockyMountainWild, itemClickedCallback: () => launchInBrowser(AppLocalizations.of(context)?.rockyMountainWildUrl ?? ""), margin: indentationLevel1),
            ListItemModel(title: AppLocalizations.of(context)?.denverZoo, itemClickedCallback: () => launchInBrowser(AppLocalizations.of(context)?.denverZooUrl ?? ""), margin: indentationLevel1),
            ListItemModel(title: AppLocalizations.of(context)?.ifThen, itemClickedCallback: () => launchInBrowser(AppLocalizations.of(context)?.ifThenUrl ?? ""), margin: indentationLevel1),
          ],
          key: userProfile == null ? _nullLeftDrawerKey: _leftDrawerKey,
          imageUrl: "assets/images/pika3.jpg",
          avatarImageUrl: "assets/images/pika4.jpg",
          avatarTitle: avatarTitle,
          avatarSubtitle: avatarSubtitle,
          avatarClickedCallback: () => _scaffoldKey.currentState?.openEndDrawer(),
          cardElevationLevel: ElevationLevel.FLAT,
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
        widthPercent: 0.99,
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
                  buildRegisterScreen(context, firebaseAuthService, firebaseDatabaseService),
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

    var deleteAccountDialogTitle = AppLocalizations.of(context)?.deleteAccountDialogTitle ?? "ERROR";
    var deleteAccountDialogDetails = "";
    var ok = AppLocalizations.of(context)?.ok ?? "";
    var accountDeleted = AppLocalizations.of(context)?.accountDeleted ?? "Error";

    return ProfileScreen(
      //_nullProfileKey and _profileKey need to be different or else the ProfileScreen will not update without first receiving user input
      //also, one key for null and one for not null because, without the distinction, and if we use a new uniqueKey each time, the keyboard
      //pops up and then immediately pops back down when trying to type text
      key: isEditingProfile ? editProfileKey : viewProfileKey,
      isEditMode: isEditingProfile,
      onTapLogout: () async {
        setState(() { showSignIn = true; });//makes more sense to show signIn than register after signOut

        var result = await firebaseAuthService.signOut();
        final message = result?.message;
        if (message != null) {
          showToast(message);
        }
      },
      onTapEdit: () {
        resetEditedUserProfileFields();
        setState(() => isEditingProfile = true);
      },
      onTapSave: () async {
        setState(() => loading = true);

        await firebaseDatabaseService.addOrUpdateUserProfile(
            editedFirstName ?? userProfile?.firstName ?? "",
            editedLastName ?? userProfile?.lastName ?? "",
            editedTagline ?? userProfile?.tagline ?? "",
            editedPronouns ?? userProfile?.pronouns ?? "",
            editedOrganization ?? userProfile?.organization ?? "",
            editedAddress ?? userProfile?.address ?? "",
            editedCity ?? userProfile?.city ?? "",
            editedState ?? userProfile?.state ?? "",
            editedZip ?? userProfile?.zip ?? "",
            editedFrppOptIn ?? userProfile?.frppOptIn ?? false,
            editedRmwOptIn ?? userProfile?.rmwOptIn ?? false,
            editedDzOptIn ?? userProfile?.dzOptIn ?? false
        );
        resetEditedUserProfileFields();
        setState(() => isEditingProfile = false);
        setState(() => loading = false);
      },
      onTapDelete: () async {
        Widget okButton = TextButton(
          child: Text(ok),
          onPressed:  () async {
            //Hide the alert
            Navigator.pop(context, true);

            setState(() { showSignIn = true; });//makes more sense to show signIn than register after signOut

            await firebaseDatabaseService.deleteUserProfile();

            var result = await firebaseAuthService.deleteUser();
            var message = result?.message;
            if (message != null) {
              //There was an error deleting the user, show the error and exit the process
              showToast(message);
              return;
            }
              showToast(accountDeleted);
            },
        );

        AlertDialog alert = AlertDialog(
          title: Text(deleteAccountDialogTitle),
          content: Text(deleteAccountDialogDetails),
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
      onEmailChangedCallback: (value) => { editedEmail = value },
      onPasswordChangedCallback: (value) => { editedPassword = value },
      onFirstNameChangedCallback: (value) => { editedFirstName = value },
      onLastNameChangedCallback: (value) => { editedLastName = value },
      onTaglineChangedCallback: (value) => { editedTagline = value },
      onPronounsChangedCallback: (value) => { editedPronouns = value },
      onOrganizationChangedCallback: (value) => { editedOrganization = value },
      onAddressChangedCallback: (value) => { editedAddress = value },
      onCityChangedCallback: (value) => { editedCity = value },
      onStateChangedCallback: (value) => { editedState = value },
      onZipChangedCallback: (value) => { editedZip = value },
      // onFrppOptInChangedCallback: (value) => { editedFrppOptIn = value },//TODO - CHRIS
      // onRmwOptInChangedCallback: (value) => { editedRmwOptIn = value },
      // onDzOptInChangedCallback: (value) => { editedDzOptIn = value },
    );
  }

  Widget buildLoginScreen(BuildContext context, FirebaseAuthService firebaseAuthService) {

    var couldNotSignInWithThoseCredentials = AppLocalizations.of(context)?.couldNotSignInWithThoseCredentials ?? "ERROR";
    var cannotSignInNoConnection = AppLocalizations.of(context)?.cannotSignInNoConnection ?? "ERROR";
    var successfullyLoggedIn = AppLocalizations.of(context)?.successfullyLoggedIn ?? "ERROR";
    var invalidEmailCannotSendPasswordResetEmail = AppLocalizations.of(context)?.invalidEmailCannotSendPasswordResetEmail ?? "ERROR";
    var passwordResetEmailSent = AppLocalizations.of(context)?.passwordResetEmailSent ?? "ERROR";
    var passwordResetEmailCouldNotBeSent = AppLocalizations.of(context)?.passwordResetEmailCouldNotBeSent ?? "ERROR";

    return LoginRegisterScreen(
      key: _loginKey,
      isLogin: true,
      showLabels: false,
      onPasswordChangedCallback: (value) => { editedPassword = value },
      onEmailChangedCallback: (value) => { editedEmail = value },
      onTapLogin: () async {

        var trimmedEmail = editedEmail?.trim() ?? "";
        var trimmedPassword = editedPassword?.trim() ?? "";

        if (trimmedEmail.isEmpty) {
          showToast(AppLocalizations.of(context)?.emailCannotBeEmpty ?? "ERROR");
          return;
        } else if (trimmedPassword.isEmpty) {
          showToast(AppLocalizations.of(context)?.passwordCannotBeEmpty ?? "ERROR");
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
              showToast(couldNotSignInWithThoseCredentials);
            }
          } on SocketException catch (_) {
            showToast(cannotSignInNoConnection);
          }
        } else {
          showToast(successfullyLoggedIn);
        }

        setState((){ loading = false; });
      },
      onTapForgotPassword: () async {
        var trimmedEmail = editedEmail?.trim() ?? "";
        if (trimmedEmail.isEmpty) {
          showToast(invalidEmailCannotSendPasswordResetEmail);
        } else {
          var result = await firebaseAuthService.requestPasswordReset(trimmedEmail);
          if (result == null) {
            showToast(passwordResetEmailSent);
          } else {
            showToast(passwordResetEmailCouldNotBeSent);
          }
        }
      },
      onTapRegister: () => {
        setState(() => showSignIn = false)
      },
    );
  }

  Widget buildRegisterScreen(BuildContext context, FirebaseAuthService firebaseAuthService, FirebaseDatabaseService firebaseDatabaseService) {
    var registeredText = AppLocalizations.of(context)?.registered ?? "ERROR";
    var initializedText = AppLocalizations.of(context)?.initialized ?? "ERROR";

    return LoginRegisterScreen(
      key: _registerKey,
      isLogin: false,
      showLabels: false,
      onPasswordChangedCallback: (value) => { editedPassword = value },
      onEmailChangedCallback: (value) => { editedEmail = value },
      onTapLogin: () => { setState(() => showSignIn = true) },
      onTapRegister: () async {

        var trimmedEmail = editedEmail?.trim() ?? "";
        var trimmedPassword = editedPassword?.trim() ?? "";

        //TODO - CHRIS - is this check useful anymore?
        // var trimmedFirstName = editedFirstName?.trim() ?? "";
        // var trimmedLastName = editedLastName?.trim() ?? "";
        // var trimmedZip = editedZip?.trim() ?? "";

        //TODO - CHRIS - is this check useful anymore?
        // if (trimmedEmail.isEmpty ||
        //     trimmedPassword.isEmpty ||
        //     trimmedFirstName.isEmpty ||
        //     trimmedLastName.isEmpty ||
        //     trimmedZip.isEmpty
        // ) {
        //   return;
        // }

        setState(() => loading = true);

        FirebaseRegistrationResult result = await firebaseAuthService.registerWithEmailAndPassword(
            trimmedEmail,
            trimmedPassword,
            editedFirstName ?? "",
            editedLastName ?? "",
            editedTagline ?? "",
            editedPronouns ?? "",
            editedOrganization ?? "",
            editedAddress ?? "",
            editedCity ?? "",
            editedState ?? "",
            editedZip ?? "",
            editedFrppOptIn ?? false,
            editedRmwOptIn ?? false,
            editedDzOptIn ?? false
        );

        if (result.appUser != null) {
          await onRegistrationSuccess(firebaseDatabaseService, result, registeredText, initializedText);
        } else {
          await onRegistrationFailed(result);
        }

        setState(() => loading = false);
      },
    );
  }

  onRegistrationSuccess(
      FirebaseDatabaseService firebaseDatabaseService,
      FirebaseRegistrationResult registrationResult,
      String registeredText,
      String initializedText
  ) async {
    showToast("$registeredText ${registrationResult.email}");

    var newlyRegisteredUid = registrationResult.appUser?.uid;
    if (newlyRegisteredUid != null) {
      var initializationException = await firebaseDatabaseService.initializeUser(newlyRegisteredUid);
      if (initializationException == null) {
        showToast("$initializedText ${registrationResult.email}");
      }
    }
  }

  onRegistrationFailed(FirebaseRegistrationResult result) async {
    //TODO - CHRIS - In cases where we can do something smart, let's do it!
    showToast("${result.exception?.message}");
  }

  Widget buildLoadingOverlay(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white.withOpacity(0.70),
      child: const Loading(),
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

  showGeoTrackingDialog(
    BuildContext context,
    AppUser? user,
    String okText,
    String locationTrackingDialogTitle,
    String locationTrackingDialogDetails
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final userAcked = prefs.getBool(Constants.PREFERENCE_USER_ACK_GEO);

    if (userAcked != null && userAcked == true) {
      if (mounted) showObservationScreen(context, user);
    } else {
      Widget launchButton = TextButton(
        child: Text(okText),
        onPressed:  () async {
          Navigator.pop(context, true);

          Permission.location.request();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(Constants.PREFERENCE_USER_ACK_GEO, true);

          if (mounted) showObservationScreen(context, user);
        },
      );
      // set up the AlertDialog
      AlertDialog alert = AlertDialog(
        title: Text(locationTrackingDialogTitle),
        content: Text(locationTrackingDialogDetails),
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

  resetEditedUserProfileFields() {
    editedEmail = null;
    editedPassword = null;
    editedFirstName = null;
    editedLastName = null;
    editedTagline = null;
    editedPronouns = null;
    editedOrganization = null;
    editedAddress = null;
    editedCity = null;
    editedState = null;
    editedZip = null;
    editedFrppOptIn = null;
    editedRmwOptIn = null;
    editedDzOptIn = null;
  }
}