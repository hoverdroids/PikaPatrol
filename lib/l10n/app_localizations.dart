import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Pika Patrol'**
  String get appName;

  /// No description provided for @sharedObservationsLine1.
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get sharedObservationsLine1;

  /// No description provided for @sharedObservationsLine2.
  ///
  /// In en, this message translates to:
  /// **'Observations'**
  String get sharedObservationsLine2;

  /// No description provided for @sharedObservationsDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Shared Observations'**
  String get sharedObservationsDialogTitle;

  /// No description provided for @sharedObservationsDialogDetails.
  ///
  /// In en, this message translates to:
  /// **'The five most recent observations uploaded to Pika Patrol\'s server by any user'**
  String get sharedObservationsDialogDetails;

  /// No description provided for @cachedObservationsLine1.
  ///
  /// In en, this message translates to:
  /// **'My'**
  String get cachedObservationsLine1;

  /// No description provided for @cachedObservationsLine2.
  ///
  /// In en, this message translates to:
  /// **'Observations'**
  String get cachedObservationsLine2;

  /// No description provided for @cachedObservationsDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'My Observations'**
  String get cachedObservationsDialogTitle;

  /// No description provided for @cachedObservationsDialogDetails.
  ///
  /// In en, this message translates to:
  /// **'My observations are those created on the current device. Clearing cache, deleting app data, or removing the app will permanently remove these observations from the device. If the observations were uploaded to the Pika Patrol server (i.e. there is a cloud icon in the top left of the card), then the observations will remain on the server but will not be pulled back onto the device.'**
  String get cachedObservationsDialogDetails;

  /// No description provided for @viewObservation.
  ///
  /// In en, this message translates to:
  /// **'View Observation'**
  String get viewObservation;

  /// No description provided for @makeObservation.
  ///
  /// In en, this message translates to:
  /// **'Make Observation'**
  String get makeObservation;

  /// No description provided for @latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// No description provided for @altitude.
  ///
  /// In en, this message translates to:
  /// **'Altitude (ft)'**
  String get altitude;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @species.
  ///
  /// In en, this message translates to:
  /// **'Species'**
  String get species;

  /// No description provided for @signs.
  ///
  /// In en, this message translates to:
  /// **'Signs'**
  String get signs;

  /// No description provided for @pikasDetected.
  ///
  /// In en, this message translates to:
  /// **'Pikas Detected'**
  String get pikasDetected;

  /// No description provided for @distanceToClosestPika.
  ///
  /// In en, this message translates to:
  /// **'Distance to Closest Pika'**
  String get distanceToClosestPika;

  /// No description provided for @searchDuration.
  ///
  /// In en, this message translates to:
  /// **'Search Duration'**
  String get searchDuration;

  /// No description provided for @talusArea.
  ///
  /// In en, this message translates to:
  /// **'Talus Area'**
  String get talusArea;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @skies.
  ///
  /// In en, this message translates to:
  /// **'Skies'**
  String get skies;

  /// No description provided for @wind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get wind;

  /// No description provided for @otherAnimalsPresent.
  ///
  /// In en, this message translates to:
  /// **'Other Animals Present'**
  String get otherAnimalsPresent;

  /// No description provided for @sharedWithProjects.
  ///
  /// In en, this message translates to:
  /// **'Shared with Projects'**
  String get sharedWithProjects;

  /// No description provided for @siteHistory.
  ///
  /// In en, this message translates to:
  /// **'Site History'**
  String get siteHistory;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @images.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get images;

  /// No description provided for @noImages.
  ///
  /// In en, this message translates to:
  /// **'No Images'**
  String get noImages;

  /// No description provided for @audioRecordings.
  ///
  /// In en, this message translates to:
  /// **'Audio Recordings'**
  String get audioRecordings;

  /// No description provided for @noAudioRecordings.
  ///
  /// In en, this message translates to:
  /// **'No Audio Recordings'**
  String get noAudioRecordings;

  /// No description provided for @appHelpAndInfo.
  ///
  /// In en, this message translates to:
  /// **'App Help and Info'**
  String get appHelpAndInfo;

  /// No description provided for @appHelpAndInfoUrl.
  ///
  /// In en, this message translates to:
  /// **'https://pikapartners.org/pika-patrol-tutorials/'**
  String get appHelpAndInfoUrl;

  /// No description provided for @identifyingPikasAndTheirSigns.
  ///
  /// In en, this message translates to:
  /// **'Identifying Pikas and Their Signs'**
  String get identifyingPikasAndTheirSigns;

  /// No description provided for @mapOfPikaObservations.
  ///
  /// In en, this message translates to:
  /// **'Map of Pika Observations'**
  String get mapOfPikaObservations;

  /// No description provided for @mapOfPikaObservationsUrl.
  ///
  /// In en, this message translates to:
  /// **'https://pikapartners.org/pikapatrolmap/'**
  String get mapOfPikaObservationsUrl;

  /// No description provided for @takeClimateAction.
  ///
  /// In en, this message translates to:
  /// **'Take Climate Action'**
  String get takeClimateAction;

  /// No description provided for @takeClimateActionUrl.
  ///
  /// In en, this message translates to:
  /// **'https://pikapartners.org/carbon/'**
  String get takeClimateActionUrl;

  /// No description provided for @sponsorsAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Sponsors and Support'**
  String get sponsorsAndSupport;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Email cannot be empty'**
  String get emailCannotBeEmpty;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Password cannot be empty'**
  String get passwordCannotBeEmpty;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Tagline'**
  String get tagline;

  /// No description provided for @pronouns.
  ///
  /// In en, this message translates to:
  /// **'Pronouns'**
  String get pronouns;

  /// No description provided for @organization.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get organization;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @zip.
  ///
  /// In en, this message translates to:
  /// **'Zip Code'**
  String get zip;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountDialogTitle;

  /// No description provided for @deleteAccountDialogDetails.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account.? This cannot be undone. Your uploaded observations will remain on the server. Local observations that have not been uploaded will be removed from your device.'**
  String get deleteAccountDialogDetails;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account Deleted'**
  String get accountDeleted;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @registered.
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get registered;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPassword;

  /// No description provided for @americanPika.
  ///
  /// In en, this message translates to:
  /// **'American Pika'**
  String get americanPika;

  /// No description provided for @americanPikaDetails.
  ///
  /// In en, this message translates to:
  /// **'The American pika, a diurnal species of pika, is found in the mountains of western North America, usually in boulder fields at or above the tree line. They are herbivorous, smaller relatives of rabbits and hares.'**
  String get americanPikaDetails;

  /// No description provided for @collaredPika.
  ///
  /// In en, this message translates to:
  /// **'Collared Pika'**
  String get collaredPika;

  /// No description provided for @collaredPikaDetails.
  ///
  /// In en, this message translates to:
  /// **'If you’re in Alaska or parts of northern Canada, you might see a different species of pika, the collared pika! Collared pikas are about the same size and shape as their American cousins, but they have a distinct greyish “collar” near their shoulders and neck. Their call is also distinct from the American pika, but their haypiles and scat piles look the same.'**
  String get collaredPikaDetails;

  /// No description provided for @iliPika.
  ///
  /// In en, this message translates to:
  /// **'Ili Pika'**
  String get iliPika;

  /// No description provided for @northernPika.
  ///
  /// In en, this message translates to:
  /// **'Northern Pika'**
  String get northernPika;

  /// No description provided for @helanShanPika.
  ///
  /// In en, this message translates to:
  /// **'Helan Shan Pika'**
  String get helanShanPika;

  /// No description provided for @steppePika.
  ///
  /// In en, this message translates to:
  /// **'Steppe Pika'**
  String get steppePika;

  /// No description provided for @plateauPika.
  ///
  /// In en, this message translates to:
  /// **'Plateau Pika'**
  String get plateauPika;

  /// No description provided for @alpinePika.
  ///
  /// In en, this message translates to:
  /// **'Alpine Pika'**
  String get alpinePika;

  /// No description provided for @koslovsPika.
  ///
  /// In en, this message translates to:
  /// **'Koslov\'s Pika'**
  String get koslovsPika;

  /// No description provided for @sawPika.
  ///
  /// In en, this message translates to:
  /// **'Saw Pika'**
  String get sawPika;

  /// No description provided for @heardPikaCalls.
  ///
  /// In en, this message translates to:
  /// **'Heard Pika Calls'**
  String get heardPikaCalls;

  /// No description provided for @haypileOld.
  ///
  /// In en, this message translates to:
  /// **'HayPile: Old'**
  String get haypileOld;

  /// No description provided for @haypileNew.
  ///
  /// In en, this message translates to:
  /// **'HayPile: New'**
  String get haypileNew;

  /// No description provided for @haypileOther.
  ///
  /// In en, this message translates to:
  /// **'HayPile: Other'**
  String get haypileOther;

  /// No description provided for @scatOld.
  ///
  /// In en, this message translates to:
  /// **'Scat: Old'**
  String get scatOld;

  /// No description provided for @scatNew.
  ///
  /// In en, this message translates to:
  /// **'Scat: New'**
  String get scatNew;

  /// No description provided for @scatOther.
  ///
  /// In en, this message translates to:
  /// **'Scat: Other'**
  String get scatOther;

  /// No description provided for @showHints.
  ///
  /// In en, this message translates to:
  /// **'Show Hints'**
  String get showHints;

  /// No description provided for @cold.
  ///
  /// In en, this message translates to:
  /// **'Cold: <45°F'**
  String get cold;

  /// No description provided for @cool.
  ///
  /// In en, this message translates to:
  /// **'Cool: 45 - 60°F'**
  String get cool;

  /// No description provided for @warm.
  ///
  /// In en, this message translates to:
  /// **'Warm: 60 - 75°F'**
  String get warm;

  /// No description provided for @hot.
  ///
  /// In en, this message translates to:
  /// **'Hot: >75°F'**
  String get hot;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @partlyCloudy.
  ///
  /// In en, this message translates to:
  /// **'Partly Cloudy'**
  String get partlyCloudy;

  /// No description provided for @overcast.
  ///
  /// In en, this message translates to:
  /// **'Overcast'**
  String get overcast;

  /// No description provided for @rainDrizzle.
  ///
  /// In en, this message translates to:
  /// **'Rain/Drizzle'**
  String get rainDrizzle;

  /// No description provided for @snow.
  ///
  /// In en, this message translates to:
  /// **'Snow'**
  String get snow;

  /// No description provided for @lowBendsGrasses.
  ///
  /// In en, this message translates to:
  /// **'Low: Bends Grasses'**
  String get lowBendsGrasses;

  /// No description provided for @mediumBendsBranches.
  ///
  /// In en, this message translates to:
  /// **'Medium: Bends Branches'**
  String get mediumBendsBranches;

  /// No description provided for @highBendsTrees.
  ///
  /// In en, this message translates to:
  /// **'High: Bends Trees'**
  String get highBendsTrees;

  /// No description provided for @marmots.
  ///
  /// In en, this message translates to:
  /// **'Marmots'**
  String get marmots;

  /// No description provided for @weasels.
  ///
  /// In en, this message translates to:
  /// **'Weasels'**
  String get weasels;

  /// No description provided for @woodrats.
  ///
  /// In en, this message translates to:
  /// **'Woodrats'**
  String get woodrats;

  /// No description provided for @mountainGoats.
  ///
  /// In en, this message translates to:
  /// **'Mountain Goats'**
  String get mountainGoats;

  /// No description provided for @cattle.
  ///
  /// In en, this message translates to:
  /// **'Cattle'**
  String get cattle;

  /// No description provided for @ptarmigans.
  ///
  /// In en, this message translates to:
  /// **'Ptarmigans'**
  String get ptarmigans;

  /// No description provided for @raptors.
  ///
  /// In en, this message translates to:
  /// **'Raptors'**
  String get raptors;

  /// No description provided for @brownCappedRosyFinch.
  ///
  /// In en, this message translates to:
  /// **'Brown Capped Rosy Finch'**
  String get brownCappedRosyFinch;

  /// No description provided for @bats.
  ///
  /// In en, this message translates to:
  /// **'Bats'**
  String get bats;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @inPartnershipWith.
  ///
  /// In en, this message translates to:
  /// **'In\nPartnership\nWith'**
  String get inPartnershipWith;

  /// No description provided for @enterRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'You must enter the required fields'**
  String get enterRequiredFields;

  /// No description provided for @emptyUserProfile.
  ///
  /// In en, this message translates to:
  /// **'Empty User Profile'**
  String get emptyUserProfile;

  /// No description provided for @coloradoPikaProject.
  ///
  /// In en, this message translates to:
  /// **'Colorado Pika Project'**
  String get coloradoPikaProject;

  /// No description provided for @coloradoPikaProjectUrl.
  ///
  /// In en, this message translates to:
  /// **'http://www.pikapartners.org/'**
  String get coloradoPikaProjectUrl;

  /// No description provided for @rockyMountainWild.
  ///
  /// In en, this message translates to:
  /// **'Rocky Mountain Wild'**
  String get rockyMountainWild;

  /// No description provided for @rockyMountainWildUrl.
  ///
  /// In en, this message translates to:
  /// **'https://rockymountainwild.org/'**
  String get rockyMountainWildUrl;

  /// No description provided for @denverZoo.
  ///
  /// In en, this message translates to:
  /// **'Denver Zoo'**
  String get denverZoo;

  /// No description provided for @denverZooUrl.
  ///
  /// In en, this message translates to:
  /// **'https://denverzoo.org/'**
  String get denverZooUrl;

  /// No description provided for @ifThen.
  ///
  /// In en, this message translates to:
  /// **'IF/THEN'**
  String get ifThen;

  /// No description provided for @ifThenUrl.
  ///
  /// In en, this message translates to:
  /// **'http://www.ifthenshecan.org/'**
  String get ifThenUrl;

  /// No description provided for @canadianPikaProject.
  ///
  /// In en, this message translates to:
  /// **'Canadian Pika Project'**
  String get canadianPikaProject;

  /// No description provided for @canadianPikaProjectUrl.
  ///
  /// In en, this message translates to:
  /// **'https://blogs.ubc.ca/russellolab/canadian-pika-project/'**
  String get canadianPikaProjectUrl;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @couldNotSignInWithThoseCredentials.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in with those credentials'**
  String get couldNotSignInWithThoseCredentials;

  /// No description provided for @cannotSignInNoConnection.
  ///
  /// In en, this message translates to:
  /// **'Can not sign in. Not connected to internet.'**
  String get cannotSignInNoConnection;

  /// No description provided for @successfullyLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Successfully Logged In'**
  String get successfullyLoggedIn;

  /// No description provided for @invalidEmailCannotSendPasswordResetEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email; cannot send password reset email'**
  String get invalidEmailCannotSendPasswordResetEmail;

  /// No description provided for @passwordResetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent'**
  String get passwordResetEmailSent;

  /// No description provided for @passwordResetEmailCouldNotBeSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email could not be sent'**
  String get passwordResetEmailCouldNotBeSent;

  /// No description provided for @initialized.
  ///
  /// In en, this message translates to:
  /// **'Initialized'**
  String get initialized;

  /// No description provided for @locationTrackingDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Location Tracking'**
  String get locationTrackingDialogTitle;

  /// No description provided for @locationTrackingDialogDescription.
  ///
  /// In en, this message translates to:
  /// **'Pika Patrol records the current location when an observation is recorded in order to determine where the observation occurred. The observation, including the saved location, is sent in the background to our servers when WiFi is available.'**
  String get locationTrackingDialogDescription;

  /// No description provided for @noConnectionFoundObservationSavedLocally.
  ///
  /// In en, this message translates to:
  /// **'No connection found.\nObservation saved locally.'**
  String get noConnectionFoundObservationSavedLocally;

  /// No description provided for @youMustLoginToUploadAnObservationObservationSavedLocally.
  ///
  /// In en, this message translates to:
  /// **'You must login to upload an observation.\nObservation saved locally.'**
  String get youMustLoginToUploadAnObservationObservationSavedLocally;

  /// No description provided for @noRecordingsToPlay.
  ///
  /// In en, this message translates to:
  /// **'No recordings to play'**
  String get noRecordingsToPlay;

  /// No description provided for @fetchingLocation.
  ///
  /// In en, this message translates to:
  /// **'Fetching location ...'**
  String get fetchingLocation;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @indigenousTerritories.
  ///
  /// In en, this message translates to:
  /// **'Indigenous Territories'**
  String get indigenousTerritories;

  /// No description provided for @indigenousLanguages.
  ///
  /// In en, this message translates to:
  /// **'Indigenous Languages'**
  String get indigenousLanguages;

  /// No description provided for @lookingUpIndigenousTerritories.
  ///
  /// In en, this message translates to:
  /// **'Looking up Indigenous territories...'**
  String get lookingUpIndigenousTerritories;

  /// No description provided for @noIndigenousTerritoryFound.
  ///
  /// In en, this message translates to:
  /// **'No Indigenous territory found for this location'**
  String get noIndigenousTerritoryFound;

  /// No description provided for @failedToFetchTerritoryData.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch territory data'**
  String get failedToFetchTerritoryData;

  /// No description provided for @cannotRequestIndigenousTerritoriesOffline.
  ///
  /// In en, this message translates to:
  /// **'Cannot request Indigenous territories when offline'**
  String get cannotRequestIndigenousTerritoriesOffline;

  /// No description provided for @associateLocalObservationsDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Observations Not Associated With Your Account'**
  String get associateLocalObservationsDialogTitle;

  /// No description provided for @associateLocalObservationsDialogDescription.
  ///
  /// In en, this message translates to:
  /// **'You have observations on this device that were made while not logged in. Would you like to associate them with your account?'**
  String get associateLocalObservationsDialogDescription;

  /// No description provided for @associateLocalObservations.
  ///
  /// In en, this message translates to:
  /// **'Associate'**
  String get associateLocalObservations;

  /// No description provided for @doNotAssociateLocalObservations.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get doNotAssociateLocalObservations;

  /// No description provided for @siteName.
  ///
  /// In en, this message translates to:
  /// **'Site Name'**
  String get siteName;

  /// No description provided for @january.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get january;

  /// No description provided for @february.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get february;

  /// No description provided for @march.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// No description provided for @july.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get july;

  /// No description provided for @august.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get august;

  /// No description provided for @september.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get september;

  /// No description provided for @october.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get october;

  /// No description provided for @november.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get november;

  /// No description provided for @december.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get december;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @couldNotOpenRecorder.
  ///
  /// In en, this message translates to:
  /// **'Could not open recorder.\nYou must accept audio permissions.'**
  String get couldNotOpenRecorder;

  /// No description provided for @didNotAddImage.
  ///
  /// In en, this message translates to:
  /// **'Did not add image. It is already in list.'**
  String get didNotAddImage;

  /// No description provided for @didNotAddAudio.
  ///
  /// In en, this message translates to:
  /// **'Did not add audio. It is already in list.'**
  String get didNotAddAudio;

  /// No description provided for @couldNotOpenFilePickerAcceptCameraPermissions.
  ///
  /// In en, this message translates to:
  /// **'Could not open file picker.\nYou must accept camera permissions.'**
  String get couldNotOpenFilePickerAcceptCameraPermissions;

  /// No description provided for @couldNotOpenFilePickerAcceptPhotosPermissions.
  ///
  /// In en, this message translates to:
  /// **'Could not open file picker.\nYou must accept photos permissions.'**
  String get couldNotOpenFilePickerAcceptPhotosPermissions;

  /// No description provided for @couldNotOpenFilePickerAcceptStoragePermissions.
  ///
  /// In en, this message translates to:
  /// **'Could not open file picker.\nYou must accept storage permissions.'**
  String get couldNotOpenFilePickerAcceptStoragePermissions;

  /// No description provided for @couldNotOpenFilePickerAcceptMediaPermissions.
  ///
  /// In en, this message translates to:
  /// **'Could not open file picker.\nYou must accept media location permissions.'**
  String get couldNotOpenFilePickerAcceptMediaPermissions;

  /// No description provided for @couldNotOpenFilePickerAcceptExternalStoragePermissions.
  ///
  /// In en, this message translates to:
  /// **'Could not open file picker.\nYou must accept external storage permissions.'**
  String get couldNotOpenFilePickerAcceptExternalStoragePermissions;

  /// No description provided for @couldNotOpenFilePickerAcceptVideosPermissions.
  ///
  /// In en, this message translates to:
  /// **'Could not open file picker.\nYou must accept videos permissions.'**
  String get couldNotOpenFilePickerAcceptVideosPermissions;

  /// No description provided for @couldNotOpenFilePickerAcceptMediaLibraryPermissions.
  ///
  /// In en, this message translates to:
  /// **'Could not open file picker.\nYou must accept media library permissions.'**
  String get couldNotOpenFilePickerAcceptMediaLibraryPermissions;

  /// No description provided for @unsupportedOperation.
  ///
  /// In en, this message translates to:
  /// **'Unsupported operation'**
  String get unsupportedOperation;

  /// No description provided for @errorWhenTryingToCropImage.
  ///
  /// In en, this message translates to:
  /// **'Error when trying to crop image'**
  String get errorWhenTryingToCropImage;

  /// No description provided for @couldNotOpenCameraAcceptCameraPermissions.
  ///
  /// In en, this message translates to:
  /// **'Could not open camera.\nYou must accept camera permissions.'**
  String get couldNotOpenCameraAcceptCameraPermissions;

  /// No description provided for @errorWhenTryingToTakePicture.
  ///
  /// In en, this message translates to:
  /// **'Error when trying to take picture'**
  String get errorWhenTryingToTakePicture;

  /// No description provided for @searchArea.
  ///
  /// In en, this message translates to:
  /// **'Search Area'**
  String get searchArea;

  /// No description provided for @addAnotherAnimalDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add animal(s)'**
  String get addAnotherAnimalDialogTitle;

  /// No description provided for @addAnotherAnimalDialogDescription.
  ///
  /// In en, this message translates to:
  /// **'(separate with commas)'**
  String get addAnotherAnimalDialogDescription;

  /// No description provided for @addAnotherProjectDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add project(s)'**
  String get addAnotherProjectDialogTitle;

  /// No description provided for @addAnotherProjectDialogDescription.
  ///
  /// In en, this message translates to:
  /// **'(separate with commas)'**
  String get addAnotherProjectDialogDescription;

  /// No description provided for @siteHistoryHint.
  ///
  /// In en, this message translates to:
  /// **'Note any history you\'ve had with this site'**
  String get siteHistoryHint;

  /// No description provided for @anyAdditionalObservations.
  ///
  /// In en, this message translates to:
  /// **'Any additional observations'**
  String get anyAdditionalObservations;

  /// No description provided for @addAnotherSpeciesDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add species'**
  String get addAnotherSpeciesDialogTitle;

  /// No description provided for @addAnotherSpeciesDialogDescription.
  ///
  /// In en, this message translates to:
  /// **'(separate with commas)'**
  String get addAnotherSpeciesDialogDescription;

  /// No description provided for @noObservationsFound.
  ///
  /// In en, this message translates to:
  /// **'No Observations Found'**
  String get noObservationsFound;

  /// No description provided for @uploadingObservations.
  ///
  /// In en, this message translates to:
  /// **'Uploading observations'**
  String get uploadingObservations;

  /// No description provided for @couldNotUploadObservationsNoDataConnection.
  ///
  /// In en, this message translates to:
  /// **'Could not upload observations. No data connection.'**
  String get couldNotUploadObservationsNoDataConnection;

  /// No description provided for @identifyingPikasAndTheirSignsOnboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Identifying Pikas\n&\nTheir Sign'**
  String get identifyingPikasAndTheirSignsOnboardingTitle;

  /// No description provided for @identifyingPikasAndTheirSignsOnboardingDetails.
  ///
  /// In en, this message translates to:
  /// **'If pikas are present in a rockslide, they are easy to detect using many types of unique sign. Here\'s a short guide to help you identify pikas.'**
  String get identifyingPikasAndTheirSignsOnboardingDetails;

  /// No description provided for @sightOnboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Sight'**
  String get sightOnboardingTitle;

  /// No description provided for @sightOnboardingDetails.
  ///
  /// In en, this message translates to:
  /// **'Pikas are about the size and shape of a potato. They have grayish to cinnamon-brown fur, and large “Mickey Mouse” ears with a white rim around the outside. They do not have a visible tail. They travel across the rock-slide above and below the rocks.'**
  String get sightOnboardingDetails;

  /// No description provided for @juvenileOnboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Juveniles'**
  String get juvenileOnboardingTitle;

  /// No description provided for @juvenileOnboardingDetails.
  ///
  /// In en, this message translates to:
  /// **'Juvenile pikas tend to be smaller and a more uniform gray color. This is because they are on their first coat of fur, so they have not yet molted. Their calls are also softer and higher-pitched than adults.'**
  String get juvenileOnboardingDetails;

  /// No description provided for @soundOnboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Hear them roar!'**
  String get soundOnboardingTitle;

  /// No description provided for @soundOnboardingDetails.
  ///
  /// In en, this message translates to:
  /// **'Pikas make squeaky alarm calls for several reasons: to warn other pikas about predators like hawks and to keep others out of their territory. Adult males may also make long calls, which have a slightly higher pitch than short calls and may last up to one minute! Calls are regionally variable – so the call you hear in one part of the state may not sound quite the same as calls you hear in other parts.'**
  String get soundOnboardingDetails;

  /// No description provided for @haypilesOnboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Haypiles'**
  String get haypilesOnboardingTitle;

  /// No description provided for @haypilesOnboardingDetails.
  ///
  /// In en, this message translates to:
  /// **'Pikas construct large food caches to survive the winter, beginning in the summer and continuing until vegetation dies in the fall. Active haypiles usually consist of fresh green clippings of grass and wildflowers, packed under or between rocks. Usually, pikas build a fresh haypile on top of leftover twigs or leaves from previous years, which appear brown.'**
  String get haypilesOnboardingDetails;

  /// No description provided for @scatPileOnboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Scat Pile'**
  String get scatPileOnboardingTitle;

  /// No description provided for @scatPileOnboardingDetails.
  ///
  /// In en, this message translates to:
  /// **'Pikas deposit two types of scat. The most common is a hard, round, brown pellet that is about the size and shape of a peppercorn. These “fecal pellets” are usually found below a large boulder in latrine sites, which may also have large white smears on the rock from urine. It is notoriously difficult to tell the age of fecal pellets, but more-recent deposits tend to still have green plant material in them and tend to be perched in a pile on a rock, with the newest pellets on top. Older pellets typically turn gray with time, fall apart easily, and do not have any green plant material in them.'**
  String get scatPileOnboardingDetails;

  /// No description provided for @scatOnboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Scat'**
  String get scatOnboardingTitle;

  /// No description provided for @scatOnboardingDetails.
  ///
  /// In en, this message translates to:
  /// **'The second type of scat is a soft black shiny string of material called a caecal pellet. Caecal pellets are re-ingested because they are actually more nutritious than plants stored in haypiles! These pellets are sometimes found stored in haypiles (usually smeared on a rock or a cached plant), but are rarely found in latrine sites.'**
  String get scatOnboardingDetails;

  /// No description provided for @unsureMoreThanOne.
  ///
  /// In en, this message translates to:
  /// **'Unsure. More than 1'**
  String get unsureMoreThanOne;

  /// No description provided for @smallerThanTennisCourt.
  ///
  /// In en, this message translates to:
  /// **'Smaller than Tennis Court'**
  String get smallerThanTennisCourt;

  /// No description provided for @tennisCourtToBaseballInfield.
  ///
  /// In en, this message translates to:
  /// **'Tennis Court to Baseball Infield'**
  String get tennisCourtToBaseballInfield;

  /// No description provided for @baseballInfieldToFootballField.
  ///
  /// In en, this message translates to:
  /// **'Baseball Infield to Football Field'**
  String get baseballInfieldToFootballField;

  /// No description provided for @largerThanFootballField.
  ///
  /// In en, this message translates to:
  /// **'Larger than Football Field'**
  String get largerThanFootballField;

  /// No description provided for @lessThan3000Feet.
  ///
  /// In en, this message translates to:
  /// **'<3,000 ft²'**
  String get lessThan3000Feet;

  /// No description provided for @threeThousandToTenThousandFeet.
  ///
  /// In en, this message translates to:
  /// **'3,000 - 10,000 ft²'**
  String get threeThousandToTenThousandFeet;

  /// No description provided for @tenThousandToFiftyThousandFeet.
  ///
  /// In en, this message translates to:
  /// **'10,000 - 50,000 ft²'**
  String get tenThousandToFiftyThousandFeet;

  /// No description provided for @greaterThanOneAcre.
  ///
  /// In en, this message translates to:
  /// **'> 1 acre'**
  String get greaterThanOneAcre;

  /// No description provided for @lessThan10Feet.
  ///
  /// In en, this message translates to:
  /// **'<10ft'**
  String get lessThan10Feet;

  /// No description provided for @tenTo30Feet.
  ///
  /// In en, this message translates to:
  /// **'10 - 30 ft'**
  String get tenTo30Feet;

  /// No description provided for @thirtyToOneHundredFeet.
  ///
  /// In en, this message translates to:
  /// **'30 - 100 ft'**
  String get thirtyToOneHundredFeet;

  /// No description provided for @moreThanOneHundredFeet.
  ///
  /// In en, this message translates to:
  /// **'>100 ft'**
  String get moreThanOneHundredFeet;

  /// No description provided for @lessThanFiveMin.
  ///
  /// In en, this message translates to:
  /// **'<5 min'**
  String get lessThanFiveMin;

  /// No description provided for @fiveToTenMin.
  ///
  /// In en, this message translates to:
  /// **'5 - 10 min'**
  String get fiveToTenMin;

  /// No description provided for @tenToTwentyMin.
  ///
  /// In en, this message translates to:
  /// **'10 - 20 min'**
  String get tenToTwentyMin;

  /// No description provided for @twentyToThirtyMin.
  ///
  /// In en, this message translates to:
  /// **'20 - 30 min'**
  String get twentyToThirtyMin;

  /// No description provided for @moreThanThirtyMin.
  ///
  /// In en, this message translates to:
  /// **'>30 min'**
  String get moreThanThirtyMin;

  /// No description provided for @adminSettings.
  ///
  /// In en, this message translates to:
  /// **'Admin Settings'**
  String get adminSettings;

  /// No description provided for @userProfiles.
  ///
  /// In en, this message translates to:
  /// **'User Profiles'**
  String get userProfiles;

  /// No description provided for @exportFirebaseUserProfilesToGoogleSheets.
  ///
  /// In en, this message translates to:
  /// **'Export Firebase User Profiles to Google Sheets'**
  String get exportFirebaseUserProfilesToGoogleSheets;

  /// No description provided for @exportFirebaseUserProfilesToGoogleSheetsDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Firebase User Profiles to Google Sheets?'**
  String get exportFirebaseUserProfilesToGoogleSheetsDialogTitle;

  /// No description provided for @exportFirebaseUserProfilesToGoogleSheetsDialogDescription.
  ///
  /// In en, this message translates to:
  /// **'This will sync all user profile data from Firebase to Google sheets, which will count against the quota for both the Firebase API and Google Cloud API.'**
  String get exportFirebaseUserProfilesToGoogleSheetsDialogDescription;

  /// No description provided for @exportFirebaseObservationsToGoogleSheets.
  ///
  /// In en, this message translates to:
  /// **'Export Firebase Observations to Google Sheets'**
  String get exportFirebaseObservationsToGoogleSheets;

  /// No description provided for @exportFirebaseObservationsToGoogleSheetsDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Firebase Observations to Google Sheets?'**
  String get exportFirebaseObservationsToGoogleSheetsDialogTitle;

  /// No description provided for @exportFirebaseObservationsToGoogleSheetsDialogDescription.
  ///
  /// In en, this message translates to:
  /// **'This will sync all observations data from Firebase to Google sheets, which will count against the quota for both the Firebase API and Google Cloud API.'**
  String get exportFirebaseObservationsToGoogleSheetsDialogDescription;

  /// No description provided for @profileIsAlreadyUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Profile is already up-to-date'**
  String get profileIsAlreadyUpToDate;

  /// No description provided for @couldNotRetrieveLocationEnableGps.
  ///
  /// In en, this message translates to:
  /// **'Could not retrieve location.\nEnable GPS and try to save again.'**
  String get couldNotRetrieveLocationEnableGps;

  /// No description provided for @locationServicesAreDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled.'**
  String get locationServicesAreDisabled;

  /// No description provided for @youMustGrantLocationPermissions.
  ///
  /// In en, this message translates to:
  /// **'You must grant location permissions.'**
  String get youMustGrantLocationPermissions;

  /// No description provided for @locationPermissionsAreDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permissions are denied'**
  String get locationPermissionsAreDenied;

  /// No description provided for @locationPermissionsArePermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permissions are permanently denied, we cannot request permissions.'**
  String get locationPermissionsArePermanentlyDenied;

  /// No description provided for @couldNotRetrieveLocationFromGps.
  ///
  /// In en, this message translates to:
  /// **'Could not retrieve location from GPS.'**
  String get couldNotRetrieveLocationFromGps;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get invalidEmail;

  /// No description provided for @invalidPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter a password 6+ chars long'**
  String get invalidPassword;

  /// No description provided for @invalidFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name is required'**
  String get invalidFirstName;

  /// No description provided for @invalidLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name is required'**
  String get invalidLastName;

  /// No description provided for @invalidZip.
  ///
  /// In en, this message translates to:
  /// **'Zip is required'**
  String get invalidZip;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @deleteObservationDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete observation?'**
  String get deleteObservationDialogTitle;

  /// No description provided for @deleteObservationDialogDescription.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this observation and all associated data, including images and audio files?'**
  String get deleteObservationDialogDescription;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @observationDeleted.
  ///
  /// In en, this message translates to:
  /// **'Observation deleted'**
  String get observationDeleted;

  /// No description provided for @observationNotDeleted.
  ///
  /// In en, this message translates to:
  /// **'Observation not deleted'**
  String get observationNotDeleted;

  /// No description provided for @initializeGoogleSheets.
  ///
  /// In en, this message translates to:
  /// **'Initialize Google Sheets'**
  String get initializeGoogleSheets;

  /// No description provided for @localObservationsNeedUploadedDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline observations need uploaded'**
  String get localObservationsNeedUploadedDialogTitle;

  /// No description provided for @localObservationsNeedUploadedDialogDescription.
  ///
  /// In en, this message translates to:
  /// **'Observations that were made offline have not been uploaded yet. Upload now?'**
  String get localObservationsNeedUploadedDialogDescription;

  /// No description provided for @observationSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Observation saved successfully'**
  String get observationSavedSuccessfully;

  /// No description provided for @unknownErrorUploadingToServerObservationSavedLocally.
  ///
  /// In en, this message translates to:
  /// **'Unknown error uploading to server. Observation saved locally'**
  String get unknownErrorUploadingToServerObservationSavedLocally;

  /// No description provided for @fillInAllFormFields.
  ///
  /// In en, this message translates to:
  /// **'Fill in all form fields'**
  String get fillInAllFormFields;

  /// No description provided for @userSettings.
  ///
  /// In en, this message translates to:
  /// **'User Settings'**
  String get userSettings;

  /// No description provided for @indigenousMap.
  ///
  /// In en, this message translates to:
  /// **'Indigenous map'**
  String get indigenousMap;

  /// No description provided for @indigenousMapDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatically open the Native Land map after Get GPS'**
  String get indigenousMapDescription;

  /// No description provided for @splashScreen.
  ///
  /// In en, this message translates to:
  /// **'Splash screen'**
  String get splashScreen;

  /// No description provided for @splashScreenDescription.
  ///
  /// In en, this message translates to:
  /// **'Show the sponsor intro screens when the app opens'**
  String get splashScreenDescription;

  /// No description provided for @units.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get units;

  /// No description provided for @imperial.
  ///
  /// In en, this message translates to:
  /// **'Imperial'**
  String get imperial;

  /// No description provided for @metric.
  ///
  /// In en, this message translates to:
  /// **'Metric'**
  String get metric;

  /// No description provided for @feet.
  ///
  /// In en, this message translates to:
  /// **'feet'**
  String get feet;

  /// No description provided for @meters.
  ///
  /// In en, this message translates to:
  /// **'meters'**
  String get meters;

  /// No description provided for @altitudeMetric.
  ///
  /// In en, this message translates to:
  /// **'Altitude (m)'**
  String get altitudeMetric;

  /// No description provided for @defaultObservation.
  ///
  /// In en, this message translates to:
  /// **'Default observation'**
  String get defaultObservation;

  /// No description provided for @defaultObservationDescription.
  ///
  /// In en, this message translates to:
  /// **'Edit the default values for new observations'**
  String get defaultObservationDescription;

  /// No description provided for @defaultObservationSaved.
  ///
  /// In en, this message translates to:
  /// **'Default observation saved'**
  String get defaultObservationSaved;

  /// No description provided for @coldMetric.
  ///
  /// In en, this message translates to:
  /// **'Cold: <7°C'**
  String get coldMetric;

  /// No description provided for @coolMetric.
  ///
  /// In en, this message translates to:
  /// **'Cool: 7 - 16°C'**
  String get coolMetric;

  /// No description provided for @warmMetric.
  ///
  /// In en, this message translates to:
  /// **'Warm: 16 - 24°C'**
  String get warmMetric;

  /// No description provided for @hotMetric.
  ///
  /// In en, this message translates to:
  /// **'Hot: >24°C'**
  String get hotMetric;

  /// No description provided for @lessThan3000FeetMetric.
  ///
  /// In en, this message translates to:
  /// **'<280 m²'**
  String get lessThan3000FeetMetric;

  /// No description provided for @threeThousandToTenThousandFeetMetric.
  ///
  /// In en, this message translates to:
  /// **'280 - 930 m²'**
  String get threeThousandToTenThousandFeetMetric;

  /// No description provided for @tenThousandToFiftyThousandFeetMetric.
  ///
  /// In en, this message translates to:
  /// **'930 - 4,600 m²'**
  String get tenThousandToFiftyThousandFeetMetric;

  /// No description provided for @greaterThanOneAcreMetric.
  ///
  /// In en, this message translates to:
  /// **'> 0.4 ha'**
  String get greaterThanOneAcreMetric;

  /// No description provided for @lessThan10FeetMetric.
  ///
  /// In en, this message translates to:
  /// **'<3 m'**
  String get lessThan10FeetMetric;

  /// No description provided for @tenTo30FeetMetric.
  ///
  /// In en, this message translates to:
  /// **'3 - 9 m'**
  String get tenTo30FeetMetric;

  /// No description provided for @thirtyToOneHundredFeetMetric.
  ///
  /// In en, this message translates to:
  /// **'9 - 30 m'**
  String get thirtyToOneHundredFeetMetric;

  /// No description provided for @moreThanOneHundredFeetMetric.
  ///
  /// In en, this message translates to:
  /// **'>30 m'**
  String get moreThanOneHundredFeetMetric;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
