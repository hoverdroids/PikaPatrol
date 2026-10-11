// ignore_for_file: depend_on_referenced_packages
import 'dart:developer' as developer;
import 'dart:io';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:dash_flags/dash_flags.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/clippaths/clip_paths.dart';
import 'package:material_themes_widgets/defaults/dimens.dart';
import 'package:material_themes_widgets/drawers/simple_clip_path_drawer.dart';
import 'package:material_themes_widgets/forms/loading.dart';
import 'package:material_themes_widgets/fundamental/icons.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';
import 'package:material_themes_widgets/lists/header_list.dart';
import 'package:material_themes_widgets/lists/list_item_model.dart';
import 'package:material_themes_widgets/screens/login_register_screen.dart';
import 'package:material_themes_widgets/screens/profile_screen.dart';
import 'package:material_themes_widgets/utils/ui_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pika_patrol/l10n/l10n.dart';
import 'package:pika_patrol/model/app_user.dart';
import 'package:pika_patrol/model/app_user_profile.dart';
import 'package:pika_patrol/model/observation_view_model.dart';
import 'package:pika_patrol/services/firebase_auth_service.dart';
import 'package:pika_patrol/services/firebase_database_service.dart';
import 'package:pika_patrol/services/firebase_user_profiles_database_service.dart';
import 'package:pika_patrol/services/google_sheets_service.dart';
import 'package:pika_patrol/services/observations_service.dart';
import 'package:pika_patrol/utils/network_utils.dart';
import 'package:pika_patrol/utils/observation_utils.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pika_patrol/screens/training_screens_pager.dart';
import '../l10n/translations.dart';
import '../model/firebase_registration_result.dart';
import '../services/settings_service.dart';
import 'observation_screen.dart';
import 'observations_dashboard_screen.dart';
import 'observations_map_screen.dart';
import 'observations_screen.dart';
import 'correlate_files_screen.dart';
import 'duplicate_observations_screen.dart';
import 'unused_files_screen.dart';
import '../widgets/set_supporter_dialog.dart';

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
  final GlobalKey<CurvedNavigationBarState> _navigationBarKey = GlobalKey<CurvedNavigationBarState>();
  final Key _registerKey = UniqueKey();
  final Key _loginKey = UniqueKey();
  final Key _editProfileKey = UniqueKey();
  final Key _editProfileNullKey = UniqueKey();
  final Key _profileKey = UniqueKey();
  final Key _nullProfileKey = UniqueKey();

  //TODO - replace the following with liquidController eventually
  PageController pageController = PageController(initialPage: initialPage);
  LiquidController liquidController = LiquidController();

  bool showSignIn = true;
  bool loading = false;
  bool isEditingProfile = false;
  bool userAckedGeoTracking = false;

  String appVersion = '';

  // Tracks which logged-in user's uid we've already offered to associate unassociated local
  // observations with, so the dialog doesn't reappear on every rebuild while logged in. Reset to
  // null on logout so the *next* login (even by the same user) asks again, per product intent.
  String? _promptedToAssociateObservationsForUserUid;

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

  late Translations translations;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  // Belt-and-suspenders alongside the build()-level _promptedToAssociateObservationsForUserUid
  // guard: prevents a second call to this method (from whatever triggered it) from opening a
  // second dialog on top of one that's still open and waiting on the user's choice.
  bool _isAssociateDialogShowing = false;

  Future<void> _maybeShowAssociateObservationsDialog(AppUser user) async {
    if (_isAssociateDialogShowing) return;

    final observationsService = Provider.of<ObservationsService>(context, listen: false);
    final unassociated = observationsService.getUnassociatedLocalObservations();
    if (unassociated.isEmpty || !mounted) return;

    _isAssociateDialogShowing = true;

    final shouldAssociate = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(translations.associateLocalObservationsDialogTitle),
        content: Text(translations.associateLocalObservationsDialogDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(translations.doNotAssociateLocalObservations),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(translations.associateLocalObservations),
          ),
        ],
      ),
    );

    _isAssociateDialogShowing = false;

    if (shouldAssociate == true) {
      await observationsService.associateLocalObservationsWithUser(user.uid);

      // Upload right away rather than waiting for the next unrelated trigger (a connectivity
      // *change*, or the app being backgrounded and resumed) - logging in only ever happens
      // while already online, so neither of those would otherwise fire for a while.
      if (await isConnectedToNetwork()) {
        await observationsService.uploadPendingLocalObservations(user);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    translations = Provider.of<Translations>(context);
    translations.update(context);

    // Keep existing observation cards in sync with the selected locale.
    Provider.of<ObservationsService>(context, listen: false).refreshLocalizedCardText();

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
    } else if (userProfile != null && userProfile.dateUpdatedInGoogleSheets == null){
      //Save a user's profile to google sheets and update profile in Firebase if the user data isn't yet synced
      FirebaseAuthService firebaseAuthService = Provider.of<FirebaseAuthService>(context, listen: false);
      FirebaseDatabaseService firebaseDatabaseService = Provider.of<FirebaseDatabaseService>(context, listen: false);
      saveProfile(firebaseAuthService, firebaseDatabaseService, user, userProfile, DateTime.now());
    }

    if (user == null) {
      _promptedToAssociateObservationsForUserUid = null;
    } else if (_promptedToAssociateObservationsForUserUid != user.uid) {
      _promptedToAssociateObservationsForUserUid = user.uid;
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowAssociateObservationsDialog(user));
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
          if (isOpen && forceProfileOpen && !isEditingProfile) {
            //If the user tries to close the profile screen with an incomplete profile, force it back open
            setState((){ isEditingProfile = true; });
          } else if (forceProfileOpen && !isOpen) {
            _scaffoldKey.currentState?.openEndDrawer();
            showToast(translations.enterRequiredFields);
          }
        },
    );
  }

  PreferredSizeWidget buildAppBar(BuildContext context) {
    var locale = Provider.of<SettingsService>(context, listen: true).locale;
    var language = Language.fromCode(locale.languageCode);

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0.0,
      centerTitle: true,
      leading: ThemedIconButton(
        Icons.menu,
        type: ThemeGroupType.MOP,
        emphasis: Emphasis.HIGH,
        onPressedCallback: (){ _scaffoldKey.currentState?.openDrawer(); },
      ),
      title: ThemedTitle(
        translations.appName,
        type: ThemeGroupType.MOP,
        emphasis: Emphasis.HIGH,
      ),
      actions: <Widget>[
        IconButton(
          tooltip: locale.languageCode,
          onPressed: (){ _toggleLanguage(); },
          icon: LanguageFlag(language: language, height: 24),
        ),
        ThemedIconButton(
          Icons.account_circle,
          type: ThemeGroupType.MOP,
          emphasis: Emphasis.HIGH,
          onPressedCallback: (){ _scaffoldKey.currentState?.openEndDrawer(); },
        ),
      ],
    );
  }

  _toggleLanguage() async {
    var settingsService = Provider.of<SettingsService>(context, listen: false);
    var locale = settingsService.locale;
    Locale nextLocale;
    if (locale == L10n.ENGLISH) {
      nextLocale = L10n.SPANISH;
    } else if (locale == L10n.SPANISH) {
      nextLocale = L10n.FRENCH;
    } else {
      nextLocale = L10n.ENGLISH;
    }
    settingsService.updateLocale(nextLocale);
  }

  Widget buildBody(BuildContext context, double width) {
    return SizedBox(
      width: width,
      child: Stack(
        children: <Widget>[
          ObservationsPage()
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
      key: _navigationBarKey,
      color: navbarColor,
      backgroundColor: navbarBgColor,
      buttonBackgroundColor: navbarButtonColor,
      height: navbarHeight,
      items: <Widget>[
        Icon(Icons.loupe, size: navbarIconSize, color: navbarIconColor),
        Icon(Icons.map, size: navbarIconSize, color: navbarIconColor),
        Icon(Icons.show_chart, size: navbarIconSize, color: navbarIconColor),
      ],
      onTap: (index) {
        switch (index) {
          case 1:
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ObservationsMapScreen()));
          case 2:
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ObservationsDashboardScreen()));
          default:
            showGeoTrackingDialog(context, user);
        }
        // The map and dashboard open as their own screens, so the raised button stays on new observation
        if (index != 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _navigationBarKey.currentState?.setPage(0));
        }
      },
      animationDuration: Duration(milliseconds: navbarAnimationDuration),
      animationCurve: Curves.easeInOut,
    );
  }

  Widget buildDrawer(BuildContext context, AppUser? user, AppUserProfile? userProfile, double bottom) {

    var avatarTitle = translations.login;
    var avatarSubtitle = "";
    var isAdmin = user?.isAdmin ?? false;
    if (user != null) {
      if (userProfile == null) {
        //A profile has not been initialized
        avatarTitle = translations.emptyUserProfile;
      } else {
        //A profile has been initialized
        avatarTitle = "${userProfile.firstName} ${userProfile.lastName}";
        avatarSubtitle = userProfile.tagline;
      }
    }

    var canInitializeGoogleSheets = userProfile?.tagline == "initializer";

    final settingsService = Provider.of<SettingsService>(context);
    final showIndigenousMapPreference = settingsService.showIndigenousMap;
    final showSplashScreenPreference = settingsService.showSplashScreen;
    final isMetricPreference = settingsService.isMetric;

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
            ListItemModel(title: translations.appHelpAndInfo, itemClickedCallback: () => launchInBrowser(translations.appHelpAndInfoUrl)),
            ListItemModel(title: translations.identifyingPikasAndTheirSigns, itemClickedCallback: () => {
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
            ListItemModel(title: translations.mapOfPikaObservations, itemClickedCallback: () => launchInBrowser(translations.mapOfPikaObservationsUrl ?? "")),
            ListItemModel(title: translations.takeClimateAction, itemClickedCallback: () => launchInBrowser(translations.takeClimateActionUrl ?? "")),
            ListItemModel(title: translations.userSettings, titleType: ThemeGroupType.SOM),
            ListItemModel(
              title: translations.indigenousMap,
              subtitle: translations.indigenousMapDescription,
              margin: indentationLevel1,
              trailingIcon: showIndigenousMapPreference ? Icons.check_box : Icons.check_box_outline_blank,
              trailingIconType: ThemeGroupType.POM,
              trailingEmphasis: Emphasis.HIGH,
              trailingIconClickedCallback: () => settingsService.setShowIndigenousMap(!showIndigenousMapPreference),
              itemClickedCallback: () => settingsService.setShowIndigenousMap(!showIndigenousMapPreference),
            ),
            ListItemModel(
              title: translations.splashScreen,
              subtitle: translations.splashScreenDescription,
              margin: indentationLevel1,
              trailingIcon: showSplashScreenPreference ? Icons.check_box : Icons.check_box_outline_blank,
              trailingIconType: ThemeGroupType.POM,
              trailingEmphasis: Emphasis.HIGH,
              trailingIconClickedCallback: () => settingsService.setShowSplashScreen(!showSplashScreenPreference),
              itemClickedCallback: () => settingsService.setShowSplashScreen(!showSplashScreenPreference),
            ),
            ListItemModel(title: translations.units, margin: indentationLevel1),
            ListItemModel(
              title: "${translations.imperial} (${translations.feet})",
              margin: indentationLevel2,
              trailingIcon: isMetricPreference ? Icons.radio_button_unchecked : Icons.radio_button_checked,
              trailingIconType: ThemeGroupType.POM,
              trailingEmphasis: Emphasis.HIGH,
              trailingIconClickedCallback: () => settingsService.setUnits(SettingsService.UNITS_IMPERIAL),
              itemClickedCallback: () => settingsService.setUnits(SettingsService.UNITS_IMPERIAL),
            ),
            ListItemModel(
              title: "${translations.metric} (${translations.meters})",
              margin: indentationLevel2,
              trailingIcon: isMetricPreference ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              trailingIconType: ThemeGroupType.POM,
              trailingEmphasis: Emphasis.HIGH,
              trailingIconClickedCallback: () => settingsService.setUnits(SettingsService.UNITS_METRIC),
              itemClickedCallback: () => settingsService.setUnits(SettingsService.UNITS_METRIC),
            ),
            ListItemModel(
              title: translations.defaultObservation,
              subtitle: translations.defaultObservationDescription,
              margin: indentationLevel1,
              itemClickedCallback: () => showDefaultObservationTemplateScreen(context),
            ),
            ListItemModel(title: translations.sponsorsAndSupport, titleType: ThemeGroupType.SOM),
            ListItemModel(title: translations.coloradoPikaProject, itemClickedCallback: () => launchInBrowser(translations.coloradoPikaProjectUrl ?? ""), margin: indentationLevel1),
            ListItemModel(title: translations.rockyMountainWild, itemClickedCallback: () => launchInBrowser(translations.rockyMountainWildUrl ?? ""), margin: indentationLevel1),
            ListItemModel(title: translations.denverZoo, itemClickedCallback: () => launchInBrowser(translations.denverZooUrl ?? ""), margin: indentationLevel1),
            ListItemModel(title: translations.ifThen, itemClickedCallback: () => launchInBrowser(translations.ifThenUrl ?? ""), margin: indentationLevel1),
            ListItemModel(title: translations.canadianPikaProject, itemClickedCallback: () => launchInBrowser(translations.canadianPikaProjectUrl ?? ""), margin: indentationLevel1),
            ListItemModel(title: translations.appVersion, titleType: ThemeGroupType.SOM),
            ListItemModel(title: appVersion, margin: indentationLevel1),
            if (isAdmin)...[
              ListItemModel(title: translations.adminSettings, titleType: ThemeGroupType.SOM),
              ListItemModel(title: translations.exportFirebaseUserProfilesToGoogleSheets, itemClickedCallback: () => showExportFirebaseUserProfilesToGoogleSheetsDialog(), margin: indentationLevel1),
              ListItemModel(title: translations.exportFirebaseObservationsToGoogleSheets, itemClickedCallback: () => showExportFirebaseObservationsToGoogleSheetsDialog(), margin: indentationLevel1),
              ListItemModel(title: translations.duplicateObservations, itemClickedCallback: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DuplicateObservationsScreen())), margin: indentationLevel1),
              ListItemModel(title: translations.correlateFiles, itemClickedCallback: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CorrelateFilesScreen())), margin: indentationLevel1),
              ListItemModel(title: translations.setSupporterStatus, itemClickedCallback: () => showSetSupporterDialog(context), margin: indentationLevel1),
              ListItemModel(title: translations.unusedFiles, itemClickedCallback: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UnusedFilesScreen())), margin: indentationLevel1),
              if (canInitializeGoogleSheets) ... [
                ListItemModel(title: translations.initializeGoogleSheets, itemClickedCallback: () => initializeGoogleSheets(), margin: indentationLevel1),
              ]
              /*TODO - CHRIS - show user profiles so that they can be delted or have admin access granted. the later will require me interacting with node.js scripts locally*/
            ],
          ],
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
                  buildProfilePanel(context, firebaseAuthService, firebaseDatabaseService, user, userProfile),
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

  Widget buildProfilePanel(
    BuildContext context,
    FirebaseAuthService firebaseAuthService,
    FirebaseDatabaseService firebaseDatabaseService,
    AppUser? user,
    AppUserProfile? userProfile,
  ) {
    return buildProfileScreen(context, firebaseAuthService, firebaseDatabaseService, user, userProfile);
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
      screenTitle: translations.profile,
      isEditMode: isEditingProfile,
      logoutText: translations.logout,
      onTapLogout: () async {
        setState(() { showSignIn = true; });//makes more sense to show signIn than register after signOut

        // Resetting isAdmin after signing out because the user can have an admin and non admin account (e.g. the dev)
        await Provider.of<SettingsService>(context, listen: false).setIsAdmin(false);

        var result = await firebaseAuthService.signOut();
        final message = result?.message;
        if (message != null) {
          showToast(message);
        }
      },
      editText: translations.edit,
      onTapEdit: () {
        resetEditedUserProfileFields();
        setState(() => isEditingProfile = true);
      },
      saveText: translations.save,
      onTapSave: () async {
        saveProfile(firebaseAuthService, firebaseDatabaseService, user, userProfile, userProfile?.dateUpdatedInGoogleSheets);
      },
      deleteAccount: translations.deleteAccount,
      onTapDeleteAccount: () async {
        final passwordController = TextEditingController();

        Widget cancelButton = TextButton(
          child: Text(translations.cancel),
          onPressed: () => Navigator.pop(context, false),
        );

        Widget okButton = TextButton(
          child: Text(translations.ok),
          onPressed:  () async {
            //Hide the alert
            Navigator.pop(context, true);

            // Confirm the password first. Firebase refuses to delete an account without a recent
            // sign-in, and deleting the profile before that check left a login with no profile.
            var reauthResult = await firebaseAuthService.reauthenticateCurrentUser(password: passwordController.text);
            if (reauthResult != null) {
              showToast(translations.deleteAccountWrongPassword);
              return;
            }

            setState(() { showSignIn = true; });//makes more sense to show signIn than register after signOut

            await firebaseDatabaseService.userProfilesService.deleteUserProfile();

            var result = await firebaseAuthService.deleteUser();
            var message = result?.message;
            if (message != null) {
              //There was an error deleting the user, show the error and exit the process
              showToast(message);
              return;
            }
            showToast(translations.accountDeleted);
          },
        );

        AlertDialog alert = AlertDialog(
          title: Text(translations.deleteAccountDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(translations.deleteAccountDialogDetails),
              // Google and Apple accounts confirm with their own sign-in sheet instead of a password
              if (firebaseAuthService.currentUserProviderIds.contains("password")) ... [
                const SizedBox(height: 16),
                Text(translations.deleteAccountEnterPassword),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(labelText: translations.password),
                ),
              ],
            ],
          ),
          actions: [
            cancelButton,
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
      email: user?.email ?? "",
      emailLabel: translations.email,
      emailHint: translations.email,
      invalidEmailText: translations.invalidEmail,
      password: isEditingProfile ? "" : "**********",//Auth doesn't provide password, so just show hint
      showPasswordHint: true,
      passwordHint: "**********",
      passwordLabel: translations.password,
      invalidPasswordText: translations.invalidPassword,
      validatePassword: editedPassword != null,
      firstName: userProfile?.firstName ?? "" ,
      firstNameLabel: translations.firstName,
      invalidFirstNameText: translations.invalidFirstName,
      lastName: userProfile?.lastName ?? "",
      lastNameLabel: translations.lastName,
      invalidLastNameText: translations.invalidLastName,
      tagline: userProfile?.tagline ?? "",
      taglineLabel: translations.tagline,
      pronouns: userProfile?.pronouns ?? "",
      pronounsLabel: translations.pronouns,
      organization: userProfile?.organization ?? "",
      organizationLabel: translations.organization,
      address: userProfile?.address ?? "",
      addressLabel: translations.address,
      city: userProfile?.city ?? "",
      cityLabel: translations.city,
      state: userProfile?.state ?? "",
      stateLabel: translations.state,
      zip: userProfile?.zip ?? "",
      zipLabel: translations.zip,
      invalidZipText: translations.invalidZip,
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

  Widget buildLoginScreen(BuildContext context, FirebaseAuthService firebaseAuthService) => LoginRegisterScreen(
    key: _loginKey,
    isLogin: true,
    showLabels: false,
    passwordLabel: translations.password,
    passwordHint: translations.password,
    invalidPasswordText: translations.invalidPassword,
    onPasswordChangedCallback: (value) => { editedPassword = value },
    emailLabel: translations.email,
    emailHint: translations.email,
    invalidEmailText: translations.invalidEmail,
    onEmailChangedCallback: (value) => { editedEmail = value },
    loginText: translations.login,
    onTapLogin: () async {

      var trimmedEmail = editedEmail?.trim() ?? "";
      var trimmedPassword = editedPassword?.trim() ?? "";

      if (trimmedEmail.isEmpty) {
        showToast(translations.emailCannotBeEmpty);
        return;
      } else if (trimmedPassword.isEmpty) {
        showToast(translations.passwordCannotBeEmpty);
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
            showToast(translations.couldNotSignInWithThoseCredentials);
          }
        } on SocketException catch (_) {
          showToast(translations.cannotSignInNoConnection);
        }
      } else {
        showToast(translations.successfullyLoggedIn);
      }

      setState((){ loading = false; });
    },
    forgotPasswordText: translations.forgotPassword,
    onTapForgotPassword: () async {
      var trimmedEmail = editedEmail?.trim() ?? "";
      if (trimmedEmail.isEmpty) {
        showToast(translations.invalidEmailCannotSendPasswordResetEmail);
      } else {
        var result = await firebaseAuthService.requestPasswordReset(trimmedEmail);
        if (result == null) {
          showToast(translations.passwordResetEmailSent);
        } else {
          showToast(translations.passwordResetEmailCouldNotBeSent);
        }
      }
    },
    registerText: translations.register,
    onTapRegister: () => {
      setState(() => showSignIn = false)
    },
    footerChildren: buildSocialSignInButtons(firebaseAuthService),
  );

  // Hidden for now; set to true to bring the Google and Apple sign-in buttons back
  static const bool showSocialSignIn = false;

  /// "Sign in with Google" on every phone, plus "Sign in with Apple" on iPhones, where Apple
  /// requires it whenever another social sign-in is offered.
  List<Widget> buildSocialSignInButtons(FirebaseAuthService firebaseAuthService) {
    if (!showSocialSignIn) return [];
    return [
      smallTransparentDivider,
      ElevatedButton(
        onPressed: () => signInWithProvider(firebaseAuthService.signInWithGoogle),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 14.0),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          shape: const StadiumBorder(),
        ),
        child: Text(translations.signInWithGoogle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ),
      if (Platform.isIOS) ... [
        smallTransparentDivider,
        SizedBox(
          width: 260,
          child: SignInWithAppleButton(
            text: translations.signInWithApple,
            borderRadius: const BorderRadius.all(Radius.circular(24.0)),
            onPressed: () => signInWithProvider(firebaseAuthService.signInWithApple),
          ),
        ),
      ],
    ];
  }

  Future<void> signInWithProvider(Future<UserCredential?> Function() signIn) async {
    var firebaseDatabaseService = Provider.of<FirebaseDatabaseService>(context, listen: false);
    setState(() => loading = true);
    try {
      final credential = await signIn();
      if (credential != null) {
        // First Google/Apple sign-in creates the account, so give it a profile like email registration does
        final user = credential.user;
        if (credential.additionalUserInfo?.isNewUser == true && user != null) {
          await firebaseDatabaseService.userProfilesService.initializeUser(user.uid);
        }
        showToast(translations.successfullyLoggedIn);
      }
    } catch (e) {
      developer.log("Social sign-in failed: $e");
      showToast(translations.couldNotSignIn);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget buildRegisterScreen(BuildContext context, FirebaseAuthService firebaseAuthService, FirebaseDatabaseService firebaseDatabaseService) {
    return LoginRegisterScreen(
      key: _registerKey,
      isLogin: false,
      showLabels: false,
      passwordLabel: translations.password,
      passwordHint: translations.password,
      invalidPasswordText: translations.invalidPassword,
      onPasswordChangedCallback: (value) => { editedPassword = value },
      emailLabel: translations.email,
      emailHint: translations.email,
      invalidEmailText: translations.invalidEmail,
      onEmailChangedCallback: (value) => { editedEmail = value },
      loginText: translations.login,
      onTapLogin: () => { setState(() => showSignIn = true) },
      footerChildren: buildSocialSignInButtons(firebaseAuthService),
      registerText: translations.register,
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

        //Required so that the profile screen doesn't think the user manually edited the password or email when it
        //is automatically forced open after registration
        editedEmail = null;
        editedPassword = null;

        if (result.appUser != null) {
          await onRegistrationSuccess(firebaseDatabaseService, result);
        } else {
          await onRegistrationFailed(result);
        }

        setState(() => loading = false);
      },
    );
  }

  onRegistrationSuccess(FirebaseDatabaseService firebaseDatabaseService, FirebaseRegistrationResult registrationResult) async {
    showToast("${translations.registered} ${registrationResult.email}");

    var newlyRegisteredUid = registrationResult.appUser?.uid;
    if (newlyRegisteredUid != null) {
      var initializationException = await firebaseDatabaseService.userProfilesService.initializeUser(newlyRegisteredUid);
      if (initializationException == null) {
        showToast("${translations.initialized} ${registrationResult.email}");
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

  // The observation is made once, outside the route builder. Flutter can call a route's builder
  // again whenever the route's dependencies change, and making the observation in there swapped
  // the open form for a blank one, for example right after an upload.
  showObservationScreen(BuildContext context, AppUser? user) {
    final translations = Provider.of<Translations>(context, listen: false);
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    //New observations start from the user's default observation template
    final observation = observationFromTemplateJson(
      settingsService.defaultObservationTemplateJson,
      observerUid: user?.uid,
      date: DateTime.now(),
    );
    final observationViewModel = ObservationViewModel(observation, translations);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ObservationScreen(observationViewModel)),
    );
  }

  showDefaultObservationTemplateScreen(BuildContext context) {
    final translations = Provider.of<Translations>(context, listen: false);
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    final observation = observationFromTemplateJson(settingsService.defaultObservationTemplateJson, date: DateTime.now());
    final observationViewModel = ObservationViewModel(observation, translations);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ObservationScreen(observationViewModel, isTemplate: true)),
    );
  }

  showGeoTrackingDialog(BuildContext context, AppUser? user) async {
    final userAcked = await Provider.of<SettingsService>(context, listen: false).getUserAcknowledgedGeo();

    if (userAcked != null && userAcked == true) {
      if (mounted) showObservationScreen(context, user);
    } else {
      Widget launchButton = TextButton(
        child: Text(translations.ok),
        onPressed:  () async {
          Navigator.pop(context, true);

          Permission.location.request();
          await Provider.of<SettingsService>(context, listen: false).setUserAcknowledgedGeo();
          if (mounted) showObservationScreen(context, user);
        },
      );
      // set up the AlertDialog
      AlertDialog alert = AlertDialog(
        title: Text(translations.locationTrackingDialogTitle),
        content: Text(translations.locationTrackingDialogDescription),
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

  showExportFirebaseUserProfilesToGoogleSheetsDialog() {
    Widget launchButton = TextButton(
      child: Text(translations.ok),
      onPressed: () async {
        Navigator.pop(context, true);
        exportFirebaseUserProfilesNotInGoogleSheetsToGoogleSheets();
      },
    );
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(translations.exportFirebaseUserProfilesToGoogleSheetsDialogTitle),
      content: Text(translations.exportFirebaseUserProfilesToGoogleSheetsDialogDescription),
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

  showExportFirebaseObservationsToGoogleSheetsDialog() {
    Widget launchButton = TextButton(
      child: Text(translations.ok),
      onPressed: () async {
        Navigator.pop(context, true);
        exportFirebaseObservationsNotInGoogleSheetsToGoogleSheets();
      },
    );
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(translations.exportFirebaseObservationsToGoogleSheetsDialogTitle),
      content: Text(translations.exportFirebaseObservationsToGoogleSheetsDialogDescription),
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

  initializeGoogleSheets() async {
    if (context.mounted) {
      showToast("Starting initialization");
      var googleSheetsService = Provider.of<GoogleSheetsService>(context, listen: false);
      for (var service in googleSheetsService.pikaPatrolSpreadsheetServices) {
        await service.userProfilesWorksheetService?.initHeaderRow();
        showToast("Initialized ${service.organization} User Profiles");
        await Future.delayed(const Duration(milliseconds: GoogleSheetsService.WRITE_THEN_TOAST_DELAY_MS));

        await service.observationWorksheetService?.initHeaderRow();
        showToast("Initialized ${service.organization} Observations");
        await Future.delayed(const Duration(milliseconds: GoogleSheetsService.WRITE_THEN_TOAST_DELAY_MS));
      }
      showToast("Finished initialization");
    }
  }

  exportFirebaseUserProfilesNotInGoogleSheetsToGoogleSheets() async {
    var firebaseDatabaseService = Provider.of<FirebaseDatabaseService>(context, listen: false);
    var appUserProfiles = await firebaseDatabaseService.userProfilesService.getAllUserProfiles(limit: FirebaseUserProfilesDatabaseService.NO_LIMIT);

    for (var appUserProfile in appUserProfiles) {
      var now = DateTime.now();
      appUserProfile.dateUpdatedInGoogleSheets = now;

      //Update Firebase so that the next query for profiles not in sheets, doesn't return these results
      /*await firebaseDatabaseService.userProfilesService.addOrUpdateUserProfile(
          appUserProfile.firstName,
          appUserProfile.lastName,
          appUserProfile.uid,
          appUserProfile.tagline,
          appUserProfile.pronouns,
          appUserProfile.organization,
          appUserProfile.address,
          appUserProfile.city,
          appUserProfile.state,
          appUserProfile.zip,
          appUserProfile.frppOptIn,
          appUserProfile.rmwOptIn,
          appUserProfile.dzOptIn,
          now,
          translations
      );*/
    }

    if (context.mounted) {
      // Names and emails go to the master sheet only, never to partner sheets (data use agreement)
      var googleSheetsService = Provider.of<GoogleSheetsService>(context, listen: false);
      for (var service in googleSheetsService.masterSpreadsheetServices) {
        await service.userProfilesWorksheetService?.addOrUpdateAppUserProfiles(appUserProfiles, service.organization);
      }
    }
  }

  exportFirebaseObservationsNotInGoogleSheetsToGoogleSheets() async {
    var firebaseDatabaseService = Provider.of<FirebaseDatabaseService>(context, listen: false);
    var observations = await firebaseDatabaseService.observationsService.getAllObservations(limit: FirebaseUserProfilesDatabaseService.NO_LIMIT);

    var now = DateTime.now();
    for (var observation in observations) {
      observation.dateUpdatedInGoogleSheets = now;
    }

    if (context.mounted) {
      //TODO - CHRIS - it would be best to check what organization the data can be shared with and then share in those lists only
      var googleSheetsService = Provider.of<GoogleSheetsService>(context, listen: false);
      for (var service in googleSheetsService.pikaPatrolSpreadsheetServices) {
        await service.observationWorksheetService?.addOrUpdateObservations(observations, service.organization);
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

  saveProfile(
      FirebaseAuthService firebaseAuthService,
      FirebaseDatabaseService firebaseDatabaseService,
      AppUser? user,
      AppUserProfile? userProfile,
      DateTime? dateUpdatedInGoogleSheets
  ) async {
    if (loading) return;

    setState(() => loading = true);

    var hasError = false;
    var emailUpdated = false;
    var updatedEmail = editedEmail?.trim();
    if (updatedEmail != null) {
      FirebaseAuthException? exception = await firebaseAuthService.changeCurrentUserEmail(updatedEmail);
      var message = exception?.message;
      if (message != null) {
        showToast(message);
        hasError = true;
      } else {
        emailUpdated = true;
        dateUpdatedInGoogleSheets = DateTime.now();
      }
    }

    var passwordUpdated = false;
    var updatedPassword = editedPassword?.trim();
    if (updatedPassword != null && !hasError) {
      FirebaseAuthException? exception = await firebaseAuthService.changeCurrentUserPassword(updatedPassword);
      var message = exception?.message;
      if (message != null) {
        showToast(message);
        hasError = true;
      } else {
        passwordUpdated = true;
        dateUpdatedInGoogleSheets = DateTime.now();
      }
    }

    var isAdminChanged = false;
    if (context.mounted && user != null) {
      var settings = Provider.of<SettingsService>(context, listen: false);
      var savedIsAdmin = await settings.getIsAdmin() ?? false;
      isAdminChanged = savedIsAdmin != user.isAdmin;
      if (isAdminChanged) {
        settings.setIsAdmin(user.isAdmin);
        dateUpdatedInGoogleSheets = DateTime.now();
      }
    }

    var profileUpdated = false;
    AppUserProfile? updatedUserProfile;
    if (!hasError) {
      updatedUserProfile = await firebaseDatabaseService.userProfilesService.addOrUpdateUserProfile(
          editedFirstName ?? userProfile?.firstName ?? "",
          editedLastName ?? userProfile?.lastName ?? "",
          userProfile?.uid,
          editedTagline ?? userProfile?.tagline ?? "",
          editedPronouns ?? userProfile?.pronouns ?? "",
          editedOrganization ?? userProfile?.organization ?? "",
          editedAddress ?? userProfile?.address ?? "",
          editedCity ?? userProfile?.city ?? "",
          editedState ?? userProfile?.state ?? "",
          editedZip ?? userProfile?.zip ?? "",
          editedFrppOptIn ?? userProfile?.frppOptIn ?? false,
          editedRmwOptIn ?? userProfile?.rmwOptIn ?? false,
          editedDzOptIn ?? userProfile?.dzOptIn ?? false,
          dateUpdatedInGoogleSheets ?? userProfile?.dateUpdatedInGoogleSheets,
          translations
      );
      profileUpdated = updatedUserProfile != null;

      //Copying the uid because it won't be available in the returned userProfile if the profile was added
      var uid = userProfile?.uid;
      updatedUserProfile = updatedUserProfile?.copy(uid: uid);

      if (uid != null && (emailUpdated || profileUpdated || isAdminChanged)) {
        var profile = updatedUserProfile ?? userProfile;
        if (profile != null && context.mounted) {
          // Names and emails go to the master sheet only, never to partner sheets (data use agreement)
          var googleSheetsService = Provider.of<GoogleSheetsService>(context, listen: false);
          for (var service in googleSheetsService.masterSpreadsheetServices) {
            await service.userProfilesWorksheetService?.addOrUpdateAppUserProfile(user, profile);
          }
        }
      }
    }

    if (!hasError) {
      if (emailUpdated || passwordUpdated || profileUpdated || isAdminChanged) {
        showToast(translations.profileUpdated);
      } else {
        showToast(translations.profileIsAlreadyUpToDate);
      }
    }

    resetEditedUserProfileFields();
    setState(() => isEditingProfile = false);
    setState(() => loading = false);
  }
}