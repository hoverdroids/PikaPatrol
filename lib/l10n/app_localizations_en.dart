// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Pika Patrol';

  @override
  String get sharedObservationsLine1 => 'Shared';

  @override
  String get sharedObservationsLine2 => 'Observations';

  @override
  String get sharedObservationsDialogTitle => 'Shared Observations';

  @override
  String get sharedObservationsDialogDetails =>
      'The five most recent observations uploaded to Pika Patrol\'s server by any user';

  @override
  String get cachedObservationsLine1 => 'My';

  @override
  String get cachedObservationsLine2 => 'Observations';

  @override
  String get cachedObservationsDialogTitle => 'My Observations';

  @override
  String get cachedObservationsDialogDetails =>
      'My observations shows every observation you\'ve made, on this device and on any other device where you\'re signed in. A cloud with a check mark (top left of the card) means it\'s uploaded and safe on the server. A clock means it\'s saved only on this phone and will upload the next time you\'re online. Deleting the app before then removes observations that haven\'t uploaded.';

  @override
  String get viewObservation => 'View Observation';

  @override
  String get makeObservation => 'Make Observation';

  @override
  String get latitude => 'Latitude';

  @override
  String get longitude => 'Longitude';

  @override
  String get altitude => 'Altitude (ft)';

  @override
  String get month => 'Month';

  @override
  String get day => 'Day';

  @override
  String get year => 'Year';

  @override
  String get species => 'Species';

  @override
  String get signs => 'Signs';

  @override
  String get pikasDetected => 'Pikas Detected';

  @override
  String get distanceToClosestPika => 'Distance to Closest Pika';

  @override
  String get searchDuration => 'Search Duration';

  @override
  String get talusArea => 'Talus Area';

  @override
  String get temperature => 'Temperature';

  @override
  String get skies => 'Skies';

  @override
  String get wind => 'Wind';

  @override
  String get otherAnimalsPresent => 'Other Animals Present';

  @override
  String get sharedWithProjects => 'Shared with Projects';

  @override
  String get siteHistory => 'Site History';

  @override
  String get comments => 'Comments';

  @override
  String get images => 'Images';

  @override
  String get noImages => 'No Images';

  @override
  String get audioRecordings => 'Audio Recordings';

  @override
  String get noAudioRecordings => 'No Audio Recordings';

  @override
  String get appHelpAndInfo => 'App Help and Info';

  @override
  String get appHelpAndInfoUrl =>
      'https://pikapartners.org/pika-patrol-tutorials/';

  @override
  String get identifyingPikasAndTheirSigns =>
      'Identifying Pikas and Their Signs';

  @override
  String get mapOfPikaObservations => 'Map of Pika Observations';

  @override
  String get mapOfPikaObservationsUrl =>
      'https://pikapartners.org/pikapatrolmap/';

  @override
  String get takeClimateAction => 'Take Climate Action';

  @override
  String get takeClimateActionUrl => 'https://pikapartners.org/carbon/';

  @override
  String get sponsorsAndSupport => 'Sponsors and Support';

  @override
  String get email => 'Email';

  @override
  String get emailCannotBeEmpty => 'Email cannot be empty';

  @override
  String get password => 'Password';

  @override
  String get passwordCannotBeEmpty => 'Password cannot be empty';

  @override
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get tagline => 'Tagline';

  @override
  String get pronouns => 'Pronouns';

  @override
  String get organization => 'Organization';

  @override
  String get address => 'Address';

  @override
  String get city => 'City';

  @override
  String get state => 'State';

  @override
  String get zip => 'Zip Code';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountDialogTitle => 'Delete Account';

  @override
  String get deleteAccountDialogDetails =>
      'Are you sure you want to delete your account.? This cannot be undone. Your uploaded observations will remain on the server. Local observations that have not been uploaded will be removed from your device.';

  @override
  String get accountDeleted => 'Account Deleted';

  @override
  String get edit => 'Edit';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get register => 'Register';

  @override
  String get registered => 'Registered';

  @override
  String get forgotPassword => 'Forgot Password';

  @override
  String get americanPika => 'American Pika';

  @override
  String get americanPikaDetails =>
      'The American pika, a diurnal species of pika, is found in the mountains of western North America, usually in boulder fields at or above the tree line. They are herbivorous, smaller relatives of rabbits and hares.';

  @override
  String get collaredPika => 'Collared Pika';

  @override
  String get collaredPikaDetails =>
      'If you’re in Alaska or parts of northern Canada, you might see a different species of pika, the collared pika! Collared pikas are about the same size and shape as their American cousins, but they have a distinct greyish “collar” near their shoulders and neck. Their call is also distinct from the American pika, but their haypiles and scat piles look the same.';

  @override
  String get iliPika => 'Ili Pika';

  @override
  String get northernPika => 'Northern Pika';

  @override
  String get helanShanPika => 'Helan Shan Pika';

  @override
  String get steppePika => 'Steppe Pika';

  @override
  String get plateauPika => 'Plateau Pika';

  @override
  String get alpinePika => 'Alpine Pika';

  @override
  String get koslovsPika => 'Koslov\'s Pika';

  @override
  String get sawPika => 'Saw Pika';

  @override
  String get heardPikaCalls => 'Heard Pika Calls';

  @override
  String get haypileOld => 'HayPile: Old';

  @override
  String get haypileNew => 'HayPile: New';

  @override
  String get haypileOther => 'HayPile: Other';

  @override
  String get scatOld => 'Scat: Old';

  @override
  String get scatNew => 'Scat: New';

  @override
  String get scatOther => 'Scat: Other';

  @override
  String get showHints => 'Show Hints';

  @override
  String get cold => 'Cold: <45°F';

  @override
  String get cool => 'Cool: 45 - 60°F';

  @override
  String get warm => 'Warm: 60 - 75°F';

  @override
  String get hot => 'Hot: >75°F';

  @override
  String get clear => 'Clear';

  @override
  String get partlyCloudy => 'Partly Cloudy';

  @override
  String get overcast => 'Overcast';

  @override
  String get rainDrizzle => 'Rain/Drizzle';

  @override
  String get snow => 'Snow';

  @override
  String get lowBendsGrasses => 'Low: Bends Grasses';

  @override
  String get mediumBendsBranches => 'Medium: Bends Branches';

  @override
  String get highBendsTrees => 'High: Bends Trees';

  @override
  String get marmots => 'Marmots';

  @override
  String get weasels => 'Weasels';

  @override
  String get woodrats => 'Woodrats';

  @override
  String get mountainGoats => 'Mountain Goats';

  @override
  String get cattle => 'Cattle';

  @override
  String get ptarmigans => 'Ptarmigans';

  @override
  String get raptors => 'Raptors';

  @override
  String get brownCappedRosyFinch => 'Brown Capped Rosy Finch';

  @override
  String get bats => 'Bats';

  @override
  String get other => 'Other';

  @override
  String get inPartnershipWith => 'In\nPartnership\nWith';

  @override
  String get enterRequiredFields => 'You must enter the required fields';

  @override
  String get emptyUserProfile => 'Empty User Profile';

  @override
  String get coloradoPikaProject => 'Colorado Pika Project';

  @override
  String get coloradoPikaProjectUrl => 'http://www.pikapartners.org/';

  @override
  String get rockyMountainWild => 'Rocky Mountain Wild';

  @override
  String get rockyMountainWildUrl => 'https://rockymountainwild.org/';

  @override
  String get denverZoo => 'Denver Zoo';

  @override
  String get denverZooUrl => 'https://denverzoo.org/';

  @override
  String get ifThen => 'IF/THEN';

  @override
  String get ifThenUrl => 'https://www.ifthenshecan.org/';

  @override
  String get canadianPikaProject => 'Canadian Pika Project';

  @override
  String get canadianPikaProjectUrl =>
      'https://blogs.ubc.ca/russellolab/canadian-pika-project/';

  @override
  String get appVersion => 'App Version';

  @override
  String get ok => 'OK';

  @override
  String get couldNotSignInWithThoseCredentials =>
      'Could not sign in with those credentials';

  @override
  String get cannotSignInNoConnection =>
      'Can not sign in. Not connected to internet.';

  @override
  String get successfullyLoggedIn => 'Successfully Logged In';

  @override
  String get invalidEmailCannotSendPasswordResetEmail =>
      'Invalid email; cannot send password reset email';

  @override
  String get passwordResetEmailSent => 'Password reset email sent';

  @override
  String get passwordResetEmailCouldNotBeSent =>
      'Password reset email could not be sent';

  @override
  String get initialized => 'Initialized';

  @override
  String get locationTrackingDialogTitle => 'Location Tracking';

  @override
  String get locationTrackingDialogDescription =>
      'Pika Patrol records the current location when an observation is recorded in order to determine where the observation occurred. The observation, including the saved location, is sent in the background to our servers when WiFi is available.';

  @override
  String get noConnectionFoundObservationSavedLocally =>
      'No connection found.\nObservation saved locally.';

  @override
  String get youMustLoginToUploadAnObservationObservationSavedLocally =>
      'You must login to upload an observation.\nObservation saved locally.';

  @override
  String get noRecordingsToPlay => 'No recordings to play';

  @override
  String get fetchingLocation => 'Fetching location ...';

  @override
  String get location => 'Location';

  @override
  String get indigenousTerritories => 'Indigenous Territories';

  @override
  String get indigenousLanguages => 'Indigenous Languages';

  @override
  String get lookingUpIndigenousTerritories =>
      'Looking up Indigenous territories...';

  @override
  String get noIndigenousTerritoryFound =>
      'No Indigenous territory found for this location';

  @override
  String get failedToFetchTerritoryData => 'Failed to fetch territory data';

  @override
  String get cannotRequestIndigenousTerritoriesOffline =>
      'Cannot request Indigenous territories when offline';

  @override
  String get associateLocalObservationsDialogTitle =>
      'Observations Not Associated With Your Account';

  @override
  String get associateLocalObservationsDialogDescription =>
      'You have observations on this device that were made while not logged in. Would you like to associate them with your account?';

  @override
  String get associateLocalObservations => 'Associate';

  @override
  String get doNotAssociateLocalObservations => 'Not Now';

  @override
  String get siteName => 'Site Name';

  @override
  String get january => 'January';

  @override
  String get february => 'February';

  @override
  String get march => 'March';

  @override
  String get april => 'April';

  @override
  String get may => 'May';

  @override
  String get june => 'June';

  @override
  String get july => 'July';

  @override
  String get august => 'August';

  @override
  String get september => 'September';

  @override
  String get october => 'October';

  @override
  String get november => 'November';

  @override
  String get december => 'December';

  @override
  String get delete => 'Delete';

  @override
  String get couldNotOpenRecorder =>
      'Could not open recorder.\nYou must accept audio permissions.';

  @override
  String get didNotAddImage => 'Did not add image. It is already in list.';

  @override
  String get didNotAddAudio => 'Did not add audio. It is already in list.';

  @override
  String get couldNotOpenFilePickerAcceptCameraPermissions =>
      'Could not open file picker.\nYou must accept camera permissions.';

  @override
  String get couldNotOpenFilePickerAcceptPhotosPermissions =>
      'Could not open file picker.\nYou must accept photos permissions.';

  @override
  String get couldNotOpenFilePickerAcceptStoragePermissions =>
      'Could not open file picker.\nYou must accept storage permissions.';

  @override
  String get couldNotOpenFilePickerAcceptMediaPermissions =>
      'Could not open file picker.\nYou must accept media location permissions.';

  @override
  String get couldNotOpenFilePickerAcceptExternalStoragePermissions =>
      'Could not open file picker.\nYou must accept external storage permissions.';

  @override
  String get couldNotOpenFilePickerAcceptVideosPermissions =>
      'Could not open file picker.\nYou must accept videos permissions.';

  @override
  String get couldNotOpenFilePickerAcceptMediaLibraryPermissions =>
      'Could not open file picker.\nYou must accept media library permissions.';

  @override
  String get unsupportedOperation => 'Unsupported operation';

  @override
  String get errorWhenTryingToCropImage => 'Error when trying to crop image';

  @override
  String get couldNotOpenCameraAcceptCameraPermissions =>
      'Could not open camera.\nYou must accept camera permissions.';

  @override
  String get errorWhenTryingToTakePicture =>
      'Error when trying to take picture';

  @override
  String get searchArea => 'Search Area';

  @override
  String get addAnotherAnimalDialogTitle => 'Add animal(s)';

  @override
  String get addAnotherAnimalDialogDescription => '(separate with commas)';

  @override
  String get addAnotherProjectDialogTitle => 'Add project(s)';

  @override
  String get addAnotherProjectDialogDescription => '(separate with commas)';

  @override
  String get siteHistoryHint => 'Note any history you\'ve had with this site';

  @override
  String get anyAdditionalObservations => 'Any additional observations';

  @override
  String get addAnotherSpeciesDialogTitle => 'Add species';

  @override
  String get addAnotherSpeciesDialogDescription => '(separate with commas)';

  @override
  String get noObservationsFound => 'No Observations Found';

  @override
  String get uploadingObservations => 'Uploading observations';

  @override
  String get couldNotUploadObservationsNoDataConnection =>
      'Could not upload observations. No data connection.';

  @override
  String get identifyingPikasAndTheirSignsOnboardingTitle =>
      'Identifying Pikas\n&\nTheir Sign';

  @override
  String get identifyingPikasAndTheirSignsOnboardingDetails =>
      'If pikas are present in a rockslide, they are easy to detect using many types of unique sign. Here\'s a short guide to help you identify pikas.';

  @override
  String get sightOnboardingTitle => 'Sight';

  @override
  String get sightOnboardingDetails =>
      'Pikas are about the size and shape of a potato. They have grayish to cinnamon-brown fur, and large “Mickey Mouse” ears with a white rim around the outside. They do not have a visible tail. They travel across the rock-slide above and below the rocks.';

  @override
  String get juvenileOnboardingTitle => 'Juveniles';

  @override
  String get juvenileOnboardingDetails =>
      'Juvenile pikas tend to be smaller and a more uniform gray color. This is because they are on their first coat of fur, so they have not yet molted. Their calls are also softer and higher-pitched than adults.';

  @override
  String get soundOnboardingTitle => 'Hear them roar!';

  @override
  String get soundOnboardingDetails =>
      'Pikas make squeaky alarm calls for several reasons: to warn other pikas about predators like hawks and to keep others out of their territory. Adult males may also make long calls, which have a slightly higher pitch than short calls and may last up to one minute! Calls are regionally variable – so the call you hear in one part of the state may not sound quite the same as calls you hear in other parts. Pro-tip: pikas often respond to recorded calls, so if you don\'t see any, try playing this call with your speaker sound up!';

  @override
  String get haypilesOnboardingTitle => 'Haypiles';

  @override
  String get haypilesOnboardingDetails =>
      'Pikas construct large food caches to survive the winter, beginning in the summer and continuing until vegetation dies in the fall. Active haypiles usually consist of fresh green clippings of grass and wildflowers, packed under or between rocks. Usually, pikas build a fresh haypile on top of leftover twigs or leaves from previous years, which appear brown.';

  @override
  String get scatPileOnboardingTitle => 'Scat Pile';

  @override
  String get scatPileOnboardingDetails =>
      'Pikas deposit two types of scat. The most common is a hard, round, brown pellet that is about the size and shape of a peppercorn. These “fecal pellets” are usually found below a large boulder in latrine sites, which may also have large white smears on the rock from urine. It is notoriously difficult to tell the age of fecal pellets, but more-recent deposits tend to still have green plant material in them and tend to be perched in a pile on a rock, with the newest pellets on top. Older pellets typically turn gray with time, fall apart easily, and do not have any green plant material in them.';

  @override
  String get scatOnboardingTitle => 'Scat';

  @override
  String get scatOnboardingDetails =>
      'The second type of scat is a soft black shiny string of material called a caecal pellet. Caecal pellets are re-ingested because they are actually more nutritious than plants stored in haypiles! These pellets are sometimes found stored in haypiles (usually smeared on a rock or a cached plant), but are rarely found in latrine sites.';

  @override
  String get unsureMoreThanOne => 'Unsure. More than 1';

  @override
  String get smallerThanTennisCourt => 'Smaller than Tennis Court';

  @override
  String get tennisCourtToBaseballInfield => 'Tennis Court to Baseball Infield';

  @override
  String get baseballInfieldToFootballField =>
      'Baseball Infield to Football Field';

  @override
  String get largerThanFootballField => 'Larger than Football Field';

  @override
  String get lessThan3000Feet => '<3,000 ft²';

  @override
  String get threeThousandToTenThousandFeet => '3,000 - 10,000 ft²';

  @override
  String get tenThousandToFiftyThousandFeet => '10,000 - 50,000 ft²';

  @override
  String get greaterThanOneAcre => '> 1 acre';

  @override
  String get lessThan10Feet => '<10ft';

  @override
  String get tenTo30Feet => '10 - 30 ft';

  @override
  String get thirtyToOneHundredFeet => '30 - 100 ft';

  @override
  String get moreThanOneHundredFeet => '>100 ft';

  @override
  String get lessThanFiveMin => '<5 min';

  @override
  String get fiveToTenMin => '5 - 10 min';

  @override
  String get tenToTwentyMin => '10 - 20 min';

  @override
  String get twentyToThirtyMin => '20 - 30 min';

  @override
  String get moreThanThirtyMin => '>30 min';

  @override
  String get adminSettings => 'Admin Settings';

  @override
  String get userProfiles => 'User Profiles';

  @override
  String get exportFirebaseUserProfilesToGoogleSheets =>
      'Export Firebase User Profiles to Google Sheets';

  @override
  String get exportFirebaseUserProfilesToGoogleSheetsDialogTitle =>
      'Export Firebase User Profiles to Google Sheets?';

  @override
  String get exportFirebaseUserProfilesToGoogleSheetsDialogDescription =>
      'This will sync all user profile data from Firebase to Google sheets, which will count against the quota for both the Firebase API and Google Cloud API.';

  @override
  String get exportFirebaseObservationsToGoogleSheets =>
      'Export Firebase Observations to Google Sheets';

  @override
  String get exportFirebaseObservationsToGoogleSheetsDialogTitle =>
      'Export Firebase Observations to Google Sheets?';

  @override
  String get exportFirebaseObservationsToGoogleSheetsDialogDescription =>
      'This will sync all observations data from Firebase to Google sheets, which will count against the quota for both the Firebase API and Google Cloud API.';

  @override
  String get profileIsAlreadyUpToDate => 'Profile is already up-to-date';

  @override
  String get couldNotRetrieveLocationEnableGps =>
      'Could not retrieve location.\nEnable GPS and try to save again.';

  @override
  String get locationServicesAreDisabled => 'Location services are disabled.';

  @override
  String get youMustGrantLocationPermissions =>
      'You must grant location permissions.';

  @override
  String get locationPermissionsAreDenied => 'Location permissions are denied';

  @override
  String get locationPermissionsArePermanentlyDenied =>
      'Location permissions are permanently denied, we cannot request permissions.';

  @override
  String get couldNotRetrieveLocationFromGps =>
      'Could not retrieve location from GPS.';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get profile => 'Profile';

  @override
  String get invalidEmail => 'Email is required';

  @override
  String get invalidPassword => 'Enter a password 6+ chars long';

  @override
  String get invalidFirstName => 'First name is required';

  @override
  String get invalidLastName => 'Last name is required';

  @override
  String get invalidZip => 'Zip is required';

  @override
  String get save => 'Save';

  @override
  String get deleteObservationDialogTitle => 'Delete observation?';

  @override
  String get deleteObservationDialogDescription =>
      'Are you sure you want to delete this observation and all associated data, including images and audio files?';

  @override
  String get cancel => 'Cancel';

  @override
  String get observationDeleted => 'Observation deleted';

  @override
  String get observationNotDeleted => 'Observation not deleted';

  @override
  String get initializeGoogleSheets => 'Initialize Google Sheets';

  @override
  String get localObservationsNeedUploadedDialogTitle =>
      'Offline observations need uploaded';

  @override
  String get localObservationsNeedUploadedDialogDescription =>
      'Observations that were made offline have not been uploaded yet. Upload now?';

  @override
  String get observationSavedSuccessfully =>
      'Thank you! Your observation was uploaded.';

  @override
  String get unknownErrorUploadingToServerObservationSavedLocally =>
      'Unknown error uploading to server. Observation saved locally';

  @override
  String get fillInAllFormFields => 'Fill in all form fields';

  @override
  String get userSettings => 'User Settings';

  @override
  String get indigenousMap => 'Indigenous map';

  @override
  String get indigenousMapDescription =>
      'Automatically open the Native Land map after Get GPS';

  @override
  String get splashScreen => 'Splash screen';

  @override
  String get splashScreenDescription =>
      'Show the sponsor intro screens when the app opens';

  @override
  String get units => 'Units';

  @override
  String get imperial => 'Imperial';

  @override
  String get metric => 'Metric';

  @override
  String get feet => 'feet';

  @override
  String get meters => 'meters';

  @override
  String get altitudeMetric => 'Altitude (m)';

  @override
  String get defaultObservation => 'Default observation';

  @override
  String get defaultObservationDescription =>
      'Edit the default values for new observations';

  @override
  String get defaultObservationSaved => 'Default observation saved';

  @override
  String get coldMetric => 'Cold: <7°C';

  @override
  String get coolMetric => 'Cool: 7 - 16°C';

  @override
  String get warmMetric => 'Warm: 16 - 24°C';

  @override
  String get hotMetric => 'Hot: >24°C';

  @override
  String get lessThan3000FeetMetric => '<280 m²';

  @override
  String get threeThousandToTenThousandFeetMetric => '280 - 930 m²';

  @override
  String get tenThousandToFiftyThousandFeetMetric => '930 - 4,600 m²';

  @override
  String get greaterThanOneAcreMetric => '> 0.4 ha';

  @override
  String get lessThan10FeetMetric => '<3 m';

  @override
  String get tenTo30FeetMetric => '3 - 9 m';

  @override
  String get thirtyToOneHundredFeetMetric => '9 - 30 m';

  @override
  String get moreThanOneHundredFeetMetric => '>30 m';

  @override
  String get deleteAccountEnterPassword => 'Enter your password to confirm.';

  @override
  String get deleteAccountWrongPassword =>
      'That password didn\'t work, so your account was not deleted.';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get signInWithApple => 'Sign in with Apple';

  @override
  String get couldNotSignIn => 'Could not sign in. Please try again.';

  @override
  String get traditionalTerritoryOf => 'Traditional territory of the %s people';

  @override
  String get nativeLandSource => 'Source: Native Land Digital';

  @override
  String get incidental => 'Incidental';

  @override
  String get deleteImageDialogTitle => 'Delete this photo?';

  @override
  String get deleteAudioDialogTitle => 'Delete this recording?';

  @override
  String get deleteMediaDialogDescription =>
      'This can\'t be undone. It is removed from the server when you save the observation.';

  @override
  String get unusedFiles => 'Unused files';

  @override
  String get unusedFilesDescription =>
      'Photos and recordings in storage that no observation uses and that match no observation by 20% or more. Files from the last day are left out in case an upload is still finishing. Checked %observations% observations and %files% files.';

  @override
  String get unusedFilesSelected => '%count% selected, %size%';

  @override
  String get noUnusedFiles => 'No unused files found.';

  @override
  String get selectAll => 'Select all';

  @override
  String get deleteSelected => 'Delete selected';

  @override
  String get deleteUnusedFilesDialogTitle => 'Delete %count% files?';

  @override
  String get deleteUnusedFilesDialogDescription =>
      'They are deleted from storage for good. This can\'t be undone.';

  @override
  String get couldNotFindUnusedFiles =>
      'Could not check the files. Check your connection and try again.';

  @override
  String get someFilesNotDeleted =>
      'Some files could not be deleted. Try again later.';

  @override
  String get correlateFiles => 'Correlate files';

  @override
  String get correlateFilesDescription =>
      'Stored files that no observation uses, or whose link broke, each with the observation it most likely belongs to and how sure the match is. Tap an observation to choose another. Check the ones that look right, then fix them together. Checked %observations% observations and %files% files.';

  @override
  String get checkingFiles => 'Checking files: %done% of %total%';

  @override
  String get fixReasonRefreshLink => 'Same file; its link expired';

  @override
  String get fixReasonSameName => 'Same file name as the broken link';

  @override
  String get fixSelectedLinks => 'Fix selected links';

  @override
  String get fixLinksDialogTitle => 'Fix %count% links?';

  @override
  String get fixLinksDialogDescription =>
      'Each selected file takes the place of its observation\'s broken link. Nothing else on the observations changes, and no files are deleted.';

  @override
  String get noBrokenLinksFound => 'No broken links found.';

  @override
  String get linksFixed => 'Fixed links on %count% observations.';

  @override
  String get someLinksNotFixed =>
      '%count% observations could not be updated. Try again later.';

  @override
  String get matchUploadedWithLinkedFile =>
      'Uploaded %time% from a file already on this observation';

  @override
  String get matchMadeNearObservationStart =>
      'Its file name shows it was made %time% from when this observation was started';

  @override
  String get matchUploadedNearSave =>
      'Uploaded %time% from when this observation was last saved';

  @override
  String get matchUploadedAfterObservationDate =>
      'Uploaded %time% from this observation\'s date';

  @override
  String get matchObservationHasBrokenLink =>
      'This observation has a broken link of the same kind';

  @override
  String get matchCloseRunnerUp => 'Another observation matches almost as well';

  @override
  String get selectAbove90 => 'Select 90% and up';

  @override
  String get clearSelection => 'Clear';

  @override
  String get otherPossibleObservations => 'Choose the observation';

  @override
  String get scannedAgo => 'Scanned %time% ago. Pull down to scan again.';
}
