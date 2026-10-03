import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_he.dart';

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
    Locale('he')
  ];

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navQuests.
  ///
  /// In en, this message translates to:
  /// **'Quests'**
  String get navQuests;

  /// No description provided for @navRankings.
  ///
  /// In en, this message translates to:
  /// **'Rankings'**
  String get navRankings;

  /// No description provided for @navAchievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get navAchievements;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get navExplore;

  /// No description provided for @navLog.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get navLog;

  /// No description provided for @activityLog.
  ///
  /// In en, this message translates to:
  /// **'Activity Log'**
  String get activityLog;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back,'**
  String get welcomeBack;

  /// No description provided for @levelN.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String levelN(int level);

  /// No description provided for @xpAmount.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP'**
  String xpAmount(int xp);

  /// No description provided for @xpToNextLevel.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP to next level'**
  String xpToNextLevel(int xp);

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @quests.
  ///
  /// In en, this message translates to:
  /// **'Quests'**
  String get quests;

  /// No description provided for @streak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streak;

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{days}d'**
  String streakDays(int days);

  /// No description provided for @nearbyAdventures.
  ///
  /// In en, this message translates to:
  /// **'Nearby Adventures'**
  String get nearbyAdventures;

  /// No description provided for @exploreYourCity.
  ///
  /// In en, this message translates to:
  /// **'Explore your city'**
  String get exploreYourCity;

  /// No description provided for @achievementsToUnlock.
  ///
  /// In en, this message translates to:
  /// **'{count} achievements to unlock'**
  String achievementsToUnlock(int count);

  /// No description provided for @dailyQuestAvailable.
  ///
  /// In en, this message translates to:
  /// **'Daily Quest Available'**
  String get dailyQuestAvailable;

  /// No description provided for @takePhotoAtLandmark.
  ///
  /// In en, this message translates to:
  /// **'Take a photo at a landmark'**
  String get takePhotoAtLandmark;

  /// No description provided for @yourCollections.
  ///
  /// In en, this message translates to:
  /// **'Your Collections'**
  String get yourCollections;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'COMPLETE'**
  String get complete;

  /// No description provided for @collectionBeaches.
  ///
  /// In en, this message translates to:
  /// **'Beaches'**
  String get collectionBeaches;

  /// No description provided for @collectionLandmarks.
  ///
  /// In en, this message translates to:
  /// **'Landmarks'**
  String get collectionLandmarks;

  /// No description provided for @collectionParks.
  ///
  /// In en, this message translates to:
  /// **'Parks'**
  String get collectionParks;

  /// No description provided for @collectionCulture.
  ///
  /// In en, this message translates to:
  /// **'Culture'**
  String get collectionCulture;

  /// No description provided for @collectionEurope.
  ///
  /// In en, this message translates to:
  /// **'Europe'**
  String get collectionEurope;

  /// No description provided for @collectionAmericas.
  ///
  /// In en, this message translates to:
  /// **'Americas'**
  String get collectionAmericas;

  /// No description provided for @collectionNationalParks.
  ///
  /// In en, this message translates to:
  /// **'National Parks'**
  String get collectionNationalParks;

  /// No description provided for @collectionSkiResorts.
  ///
  /// In en, this message translates to:
  /// **'Ski Resorts'**
  String get collectionSkiResorts;

  /// No description provided for @collectionCapitals.
  ///
  /// In en, this message translates to:
  /// **'Capitals'**
  String get collectionCapitals;

  /// No description provided for @collectionAncientSites.
  ///
  /// In en, this message translates to:
  /// **'Ancient Sites'**
  String get collectionAncientSites;

  /// No description provided for @collectionTouristDestinations.
  ///
  /// In en, this message translates to:
  /// **'Top Destinations'**
  String get collectionTouristDestinations;

  /// No description provided for @exploreCity.
  ///
  /// In en, this message translates to:
  /// **'Explore {city}'**
  String exploreCity(String city);

  /// No description provided for @totalXp.
  ///
  /// In en, this message translates to:
  /// **'Total XP'**
  String get totalXp;

  /// No description provided for @totalSkillLevel.
  ///
  /// In en, this message translates to:
  /// **'Skill Level'**
  String get totalSkillLevel;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// No description provided for @trophies.
  ///
  /// In en, this message translates to:
  /// **'Trophies'**
  String get trophies;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @privacySettings.
  ///
  /// In en, this message translates to:
  /// **'Privacy Settings'**
  String get privacySettings;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @locationSettings.
  ///
  /// In en, this message translates to:
  /// **'Location Settings'**
  String get locationSettings;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @helpAndFaq.
  ///
  /// In en, this message translates to:
  /// **'Help & FAQ'**
  String get helpAndFaq;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @sideQuests.
  ///
  /// In en, this message translates to:
  /// **'Side Quests'**
  String get sideQuests;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @completedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} completed'**
  String completedCount(int count);

  /// No description provided for @dayStreak.
  ///
  /// In en, this message translates to:
  /// **'{count} day streak'**
  String dayStreak(int count);

  /// No description provided for @skills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get skills;

  /// No description provided for @lvN.
  ///
  /// In en, this message translates to:
  /// **'Lv {level}'**
  String lvN(int level);

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// No description provided for @categoryHiking.
  ///
  /// In en, this message translates to:
  /// **'Hiking'**
  String get categoryHiking;

  /// No description provided for @categoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get categoryFood;

  /// No description provided for @categoryPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get categoryPhoto;

  /// No description provided for @categoryCulture.
  ///
  /// In en, this message translates to:
  /// **'Culture'**
  String get categoryCulture;

  /// No description provided for @categoryWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get categoryWater;

  /// No description provided for @categoryFishing.
  ///
  /// In en, this message translates to:
  /// **'Fishing'**
  String get categoryFishing;

  /// No description provided for @categoryCamping.
  ///
  /// In en, this message translates to:
  /// **'Camping'**
  String get categoryCamping;

  /// No description provided for @categoryExtreme.
  ///
  /// In en, this message translates to:
  /// **'Extreme'**
  String get categoryExtreme;

  /// No description provided for @difficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get difficultyEasy;

  /// No description provided for @difficultyMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get difficultyMedium;

  /// No description provided for @difficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get difficultyHard;

  /// No description provided for @difficultyLegendary.
  ///
  /// In en, this message translates to:
  /// **'Legendary'**
  String get difficultyLegendary;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @completeQuest.
  ///
  /// In en, this message translates to:
  /// **'Complete Quest'**
  String get completeQuest;

  /// No description provided for @completeAgain.
  ///
  /// In en, this message translates to:
  /// **'Complete Again'**
  String get completeAgain;

  /// No description provided for @verificationPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo proof'**
  String get verificationPhoto;

  /// No description provided for @verificationLocation.
  ///
  /// In en, this message translates to:
  /// **'Location check'**
  String get verificationLocation;

  /// No description provided for @verificationTime.
  ///
  /// In en, this message translates to:
  /// **'Time based'**
  String get verificationTime;

  /// No description provided for @verificationManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get verificationManual;

  /// No description provided for @unlockedOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{unlocked} of {total} unlocked'**
  String unlockedOfTotal(int unlocked, int total);

  /// No description provided for @tierAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tierAll;

  /// No description provided for @tierBronze.
  ///
  /// In en, this message translates to:
  /// **'Bronze'**
  String get tierBronze;

  /// No description provided for @tierSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get tierSilver;

  /// No description provided for @tierGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get tierGold;

  /// No description provided for @tierPlatinum.
  ///
  /// In en, this message translates to:
  /// **'Platinum'**
  String get tierPlatinum;

  /// No description provided for @searchAchievements.
  ///
  /// In en, this message translates to:
  /// **'Search achievements...'**
  String get searchAchievements;

  /// No description provided for @regularAchievements.
  ///
  /// In en, this message translates to:
  /// **'Regular Achievements'**
  String get regularAchievements;

  /// No description provided for @claim.
  ///
  /// In en, this message translates to:
  /// **'Claim'**
  String get claim;

  /// No description provided for @masterAchievements.
  ///
  /// In en, this message translates to:
  /// **'Master Achievements'**
  String get masterAchievements;

  /// No description provided for @masteredOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{unlocked} of {total} mastered'**
  String masteredOfTotal(int unlocked, int total);

  /// No description provided for @tierElite.
  ///
  /// In en, this message translates to:
  /// **'ELITE'**
  String get tierElite;

  /// No description provided for @tierLegendary.
  ///
  /// In en, this message translates to:
  /// **'LEGENDARY'**
  String get tierLegendary;

  /// No description provided for @tierMythic.
  ///
  /// In en, this message translates to:
  /// **'MYTHIC'**
  String get tierMythic;

  /// No description provided for @percentComplete.
  ///
  /// In en, this message translates to:
  /// **'{percent}% complete'**
  String percentComplete(int percent);

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// No description provided for @participants.
  ///
  /// In en, this message translates to:
  /// **'{count} participants'**
  String participants(int count);

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get allTime;

  /// No description provided for @travelBuddy.
  ///
  /// In en, this message translates to:
  /// **'TravelBuddy'**
  String get travelBuddy;

  /// No description provided for @gamifiedTravelCompanion.
  ///
  /// In en, this message translates to:
  /// **'Your gamified travel companion'**
  String get gamifiedTravelCompanion;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get continueAsGuest;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @yourDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Your display name'**
  String get yourDisplayName;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @tellUsAboutYourself.
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourself...'**
  String get tellUsAboutYourself;

  /// No description provided for @publicProfile.
  ///
  /// In en, this message translates to:
  /// **'Public Profile'**
  String get publicProfile;

  /// No description provided for @allowOthersToSeeProfile.
  ///
  /// In en, this message translates to:
  /// **'Allow others to see your profile'**
  String get allowOthersToSeeProfile;

  /// No description provided for @showOnLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Show on Leaderboard'**
  String get showOnLeaderboard;

  /// No description provided for @appearInPublicRankings.
  ///
  /// In en, this message translates to:
  /// **'Appear in public rankings'**
  String get appearInPublicRankings;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @gpsPermission.
  ///
  /// In en, this message translates to:
  /// **'GPS permission for location-based achievements'**
  String get gpsPermission;

  /// No description provided for @collectionComplete.
  ///
  /// In en, this message translates to:
  /// **'Collection Complete!'**
  String get collectionComplete;

  /// No description provided for @bonusXpAmount.
  ///
  /// In en, this message translates to:
  /// **'+{xp} Bonus XP'**
  String bonusXpAmount(int xp);

  /// No description provided for @awesome.
  ///
  /// In en, this message translates to:
  /// **'Awesome!'**
  String get awesome;

  /// No description provided for @claimNowXp.
  ///
  /// In en, this message translates to:
  /// **'Claim Now (+{xp} XP)'**
  String claimNowXp(int xp);

  /// No description provided for @orClaimRetroactively.
  ///
  /// In en, this message translates to:
  /// **'or claim retroactively'**
  String get orClaimRetroactively;

  /// No description provided for @whenDidYouAccomplish.
  ///
  /// In en, this message translates to:
  /// **'When did you accomplish this?'**
  String get whenDidYouAccomplish;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// No description provided for @addDetailsAboutExperience.
  ///
  /// In en, this message translates to:
  /// **'Add details about your experience...'**
  String get addDetailsAboutExperience;

  /// No description provided for @photosOptional.
  ///
  /// In en, this message translates to:
  /// **'Photos (optional)'**
  String get photosOptional;

  /// No description provided for @retroactiveXpNotice.
  ///
  /// In en, this message translates to:
  /// **'Retroactive claims earn 80% XP (+{xp} XP)'**
  String retroactiveXpNotice(int xp);

  /// No description provided for @claimRetroactively.
  ///
  /// In en, this message translates to:
  /// **'Claim Retroactively'**
  String get claimRetroactively;

  /// No description provided for @mapView.
  ///
  /// In en, this message translates to:
  /// **'Map View'**
  String get mapView;

  /// No description provided for @configureMapTiler.
  ///
  /// In en, this message translates to:
  /// **'Configure MAPTILER_KEY to enable MapLibre GL'**
  String get configureMapTiler;

  /// No description provided for @locating.
  ///
  /// In en, this message translates to:
  /// **'Locating...'**
  String get locating;

  /// No description provided for @centerOnMe.
  ///
  /// In en, this message translates to:
  /// **'Center on Me'**
  String get centerOnMe;

  /// No description provided for @nearbyAchievements.
  ///
  /// In en, this message translates to:
  /// **'Nearby Achievements'**
  String get nearbyAchievements;

  /// No description provided for @locationOn.
  ///
  /// In en, this message translates to:
  /// **'Location on'**
  String get locationOn;

  /// No description provided for @locationOff.
  ///
  /// In en, this message translates to:
  /// **'Location off'**
  String get locationOff;

  /// No description provided for @enableLocationToSee.
  ///
  /// In en, this message translates to:
  /// **'Enable location to see nearby achievements.'**
  String get enableLocationToSee;

  /// No description provided for @noAchievementsInRange.
  ///
  /// In en, this message translates to:
  /// **'No achievements within range.'**
  String get noAchievementsInRange;

  /// No description provided for @unlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get unlocked;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @liveTracking.
  ///
  /// In en, this message translates to:
  /// **'Live Tracking'**
  String get liveTracking;

  /// No description provided for @liveTrackingDescription.
  ///
  /// In en, this message translates to:
  /// **'Continuous GPS tracking for proximity alerts'**
  String get liveTrackingDescription;

  /// No description provided for @achievementNearby.
  ///
  /// In en, this message translates to:
  /// **'ACHIEVEMENT NEARBY'**
  String get achievementNearby;

  /// No description provided for @distanceAway.
  ///
  /// In en, this message translates to:
  /// **'away'**
  String get distanceAway;

  /// No description provided for @getCloser.
  ///
  /// In en, this message translates to:
  /// **'Get Closer'**
  String get getCloser;

  /// No description provided for @inRange.
  ///
  /// In en, this message translates to:
  /// **'In Range'**
  String get inRange;

  /// No description provided for @startTracking.
  ///
  /// In en, this message translates to:
  /// **'Start Tracking'**
  String get startTracking;

  /// No description provided for @stopTracking.
  ///
  /// In en, this message translates to:
  /// **'Stop Tracking'**
  String get stopTracking;

  /// No description provided for @trackingActive.
  ///
  /// In en, this message translates to:
  /// **'Tracking Active'**
  String get trackingActive;

  /// No description provided for @trackingOff.
  ///
  /// In en, this message translates to:
  /// **'Tracking Off'**
  String get trackingOff;

  /// No description provided for @achievementsNearYou.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 achievement near you} other{{count} achievements near you}}'**
  String achievementsNearYou(int count);

  /// No description provided for @tapToClaim.
  ///
  /// In en, this message translates to:
  /// **'Tap to claim'**
  String get tapToClaim;

  /// No description provided for @visitToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Visit to unlock'**
  String get visitToUnlock;

  /// No description provided for @unlockedOn.
  ///
  /// In en, this message translates to:
  /// **'Unlocked on {date}'**
  String unlockedOn(String date);

  /// No description provided for @kmAway.
  ///
  /// In en, this message translates to:
  /// **'{distance}km away'**
  String kmAway(String distance);

  /// No description provided for @mAway.
  ///
  /// In en, this message translates to:
  /// **'{distance}m away'**
  String mAway(String distance);

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since {date}'**
  String memberSince(String date);

  /// No description provided for @topSkills.
  ///
  /// In en, this message translates to:
  /// **'Top Skills'**
  String get topSkills;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @recentAchievements.
  ///
  /// In en, this message translates to:
  /// **'Recent Achievements'**
  String get recentAchievements;

  /// No description provided for @collections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get collections;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get changePhoto;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @displayNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Display name is required'**
  String get displayNameRequired;

  /// No description provided for @displayNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Display name must be 30 characters or less'**
  String get displayNameTooLong;

  /// No description provided for @usernameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters'**
  String get usernameTooShort;

  /// No description provided for @usernameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Username must be 20 characters or less'**
  String get usernameTooLong;

  /// No description provided for @usernameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Username can only contain letters, numbers, and underscores'**
  String get usernameInvalid;

  /// No description provided for @bioTooLong.
  ///
  /// In en, this message translates to:
  /// **'Bio must be 200 characters or less'**
  String get bioTooLong;

  /// No description provided for @noSkillsYet.
  ///
  /// In en, this message translates to:
  /// **'Complete quests to develop your skills!'**
  String get noSkillsYet;

  /// No description provided for @noAchievementsYet.
  ///
  /// In en, this message translates to:
  /// **'Start exploring to unlock achievements!'**
  String get noAchievementsYet;

  /// No description provided for @yourRank.
  ///
  /// In en, this message translates to:
  /// **'Your Rank'**
  String get yourRank;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @rankN.
  ///
  /// In en, this message translates to:
  /// **'Rank #{rank}'**
  String rankN(int rank);

  /// No description provided for @navSkills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get navSkills;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// No description provided for @requires.
  ///
  /// In en, this message translates to:
  /// **'Requires: {requirement}'**
  String requires(String requirement);

  /// No description provided for @relatedQuests.
  ///
  /// In en, this message translates to:
  /// **'Related Quests'**
  String get relatedQuests;

  /// No description provided for @viewQuests.
  ///
  /// In en, this message translates to:
  /// **'View Quests'**
  String get viewQuests;

  /// No description provided for @completedOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} completed'**
  String completedOfTotal(int completed, int total);

  /// No description provided for @xpNeeded.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP needed'**
  String xpNeeded(int xp);

  /// No description provided for @nSkills.
  ///
  /// In en, this message translates to:
  /// **'{count} skills'**
  String nSkills(int count);

  /// No description provided for @searchCountries.
  ///
  /// In en, this message translates to:
  /// **'Search countries...'**
  String get searchCountries;

  /// No description provided for @allCountries.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allCountries;

  /// No description provided for @nUnlocked.
  ///
  /// In en, this message translates to:
  /// **'unlocked'**
  String get nUnlocked;

  /// No description provided for @visited.
  ///
  /// In en, this message translates to:
  /// **'Visited'**
  String get visited;

  /// No description provided for @tabCities.
  ///
  /// In en, this message translates to:
  /// **'Cities'**
  String get tabCities;

  /// No description provided for @tabLandmarks.
  ///
  /// In en, this message translates to:
  /// **'Landmarks'**
  String get tabLandmarks;

  /// No description provided for @tabFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get tabFood;

  /// No description provided for @tabActivities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get tabActivities;

  /// No description provided for @nCities.
  ///
  /// In en, this message translates to:
  /// **'{count} cities'**
  String nCities(int count);

  /// No description provided for @nLandmarks.
  ///
  /// In en, this message translates to:
  /// **'{count} landmarks'**
  String nLandmarks(int count);

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hebrew.
  ///
  /// In en, this message translates to:
  /// **'עברית'**
  String get hebrew;

  /// No description provided for @pleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterName;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterEmail;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterValidEmail;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @proximityNotifications.
  ///
  /// In en, this message translates to:
  /// **'Proximity Notifications'**
  String get proximityNotifications;

  /// No description provided for @nativeAlertsNearAchievements.
  ///
  /// In en, this message translates to:
  /// **'Native alerts when near achievements'**
  String get nativeAlertsNearAchievements;

  /// No description provided for @tabCountries.
  ///
  /// In en, this message translates to:
  /// **'Countries'**
  String get tabCountries;

  /// No description provided for @tabCapitals.
  ///
  /// In en, this message translates to:
  /// **'Capitals'**
  String get tabCapitals;

  /// No description provided for @tabNationalParks.
  ///
  /// In en, this message translates to:
  /// **'National Parks'**
  String get tabNationalParks;

  /// No description provided for @tabSkiResorts.
  ///
  /// In en, this message translates to:
  /// **'Ski Resorts'**
  String get tabSkiResorts;

  /// No description provided for @tabAncientSites.
  ///
  /// In en, this message translates to:
  /// **'Ancient Sites'**
  String get tabAncientSites;

  /// No description provided for @tabTopDestinations.
  ///
  /// In en, this message translates to:
  /// **'Top Destinations'**
  String get tabTopDestinations;

  /// No description provided for @exploreNationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Explore nations across the globe'**
  String get exploreNationsSubtitle;

  /// No description provided for @capitalCitiesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Visit the world\'s great capital cities'**
  String get capitalCitiesSubtitle;

  /// No description provided for @nationalParksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Discover protected natural wonders'**
  String get nationalParksSubtitle;

  /// No description provided for @skiResortsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hit the slopes at legendary mountains'**
  String get skiResortsSubtitle;

  /// No description provided for @ancientSitesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sacred places of ancient faith'**
  String get ancientSitesSubtitle;

  /// No description provided for @topDestinationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The world\'s most popular places'**
  String get topDestinationsSubtitle;

  /// No description provided for @tierBronzeLabel.
  ///
  /// In en, this message translates to:
  /// **'BRONZE'**
  String get tierBronzeLabel;

  /// No description provided for @tierSilverLabel.
  ///
  /// In en, this message translates to:
  /// **'SILVER'**
  String get tierSilverLabel;

  /// No description provided for @tierGoldLabel.
  ///
  /// In en, this message translates to:
  /// **'GOLD'**
  String get tierGoldLabel;

  /// No description provided for @tierPlatinumLabel.
  ///
  /// In en, this message translates to:
  /// **'PLATINUM'**
  String get tierPlatinumLabel;

  /// No description provided for @continentEurope.
  ///
  /// In en, this message translates to:
  /// **'Europe'**
  String get continentEurope;

  /// No description provided for @continentAmericas.
  ///
  /// In en, this message translates to:
  /// **'Americas'**
  String get continentAmericas;

  /// No description provided for @continentAsia.
  ///
  /// In en, this message translates to:
  /// **'Asia'**
  String get continentAsia;

  /// No description provided for @continentAfrica.
  ///
  /// In en, this message translates to:
  /// **'Africa'**
  String get continentAfrica;

  /// No description provided for @continentOceania.
  ///
  /// In en, this message translates to:
  /// **'Oceania'**
  String get continentOceania;

  /// No description provided for @exploreTheWorld.
  ///
  /// In en, this message translates to:
  /// **'Explore the World'**
  String get exploreTheWorld;

  /// No description provided for @trackTravelsAcrossContinents.
  ///
  /// In en, this message translates to:
  /// **'Track your travels across continents'**
  String get trackTravelsAcrossContinents;

  /// No description provided for @tabCountriesHome.
  ///
  /// In en, this message translates to:
  /// **'Countries'**
  String get tabCountriesHome;

  /// No description provided for @tabCollectionsHome.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get tabCollectionsHome;

  /// No description provided for @trophyCommandCenter.
  ///
  /// In en, this message translates to:
  /// **'Trophy Command Center'**
  String get trophyCommandCenter;

  /// No description provided for @shownCountOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{shown} / {total} shown'**
  String shownCountOfTotal(int shown, int total);

  /// No description provided for @quickFilterUnlockedCount.
  ///
  /// In en, this message translates to:
  /// **'Unlocked ({count})'**
  String quickFilterUnlockedCount(int count);

  /// No description provided for @quickFilterLockedCount.
  ///
  /// In en, this message translates to:
  /// **'Locked ({count})'**
  String quickFilterLockedCount(int count);

  /// No description provided for @quickFilterNearbyCount.
  ///
  /// In en, this message translates to:
  /// **'Nearby ({count})'**
  String quickFilterNearbyCount(int count);

  /// No description provided for @quickFilterHighXpCount.
  ///
  /// In en, this message translates to:
  /// **'High XP ({count})'**
  String quickFilterHighXpCount(int count);

  /// No description provided for @nextTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Next target: {title}'**
  String nextTargetLabel(String title);

  /// No description provided for @allTrophiesInCategoryUnlocked.
  ///
  /// In en, this message translates to:
  /// **'All trophies in this category unlocked.'**
  String get allTrophiesInCategoryUnlocked;

  /// No description provided for @collectionHeatmap.
  ///
  /// In en, this message translates to:
  /// **'Collection Heatmap'**
  String get collectionHeatmap;

  /// No description provided for @noHeatmapData.
  ///
  /// In en, this message translates to:
  /// **'No heatmap data.'**
  String get noHeatmapData;

  /// No description provided for @heatmapUnlockedOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{unlocked}/{total} unlocked'**
  String heatmapUnlockedOfTotal(int unlocked, int total);

  /// No description provided for @heatmapOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get heatmapOther;

  /// No description provided for @achievementUnlocked.
  ///
  /// In en, this message translates to:
  /// **'ACHIEVEMENT UNLOCKED!'**
  String get achievementUnlocked;

  /// No description provided for @unlockTimeline.
  ///
  /// In en, this message translates to:
  /// **'Unlock Timeline'**
  String get unlockTimeline;

  /// No description provided for @noUnlockedTrophiesYet.
  ///
  /// In en, this message translates to:
  /// **'No unlocked trophies yet.'**
  String get noUnlockedTrophiesYet;

  /// No description provided for @mapFilterAchievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get mapFilterAchievements;

  /// No description provided for @mapFilterQuests.
  ///
  /// In en, this message translates to:
  /// **'Quests'**
  String get mapFilterQuests;

  /// No description provided for @mapFilterSkills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get mapFilterSkills;

  /// No description provided for @mapCloseMap.
  ///
  /// In en, this message translates to:
  /// **'Close map'**
  String get mapCloseMap;

  /// No description provided for @mapZoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get mapZoomIn;

  /// No description provided for @mapZoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get mapZoomOut;

  /// No description provided for @mapResetCompass.
  ///
  /// In en, this message translates to:
  /// **'Reset compass'**
  String get mapResetCompass;

  /// No description provided for @mapMyLocation.
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get mapMyLocation;

  /// No description provided for @mapFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get mapFilters;

  /// No description provided for @mapNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get mapNearby;

  /// No description provided for @mapActiveQuests.
  ///
  /// In en, this message translates to:
  /// **'Active Quests'**
  String get mapActiveQuests;

  /// No description provided for @mapCompletedFilter.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get mapCompletedFilter;

  /// No description provided for @mapStartQuestHere.
  ///
  /// In en, this message translates to:
  /// **'Start quest here?'**
  String get mapStartQuestHere;

  /// No description provided for @mapLogVisit.
  ///
  /// In en, this message translates to:
  /// **'Log visit'**
  String get mapLogVisit;

  /// No description provided for @mapViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get mapViewDetails;

  /// No description provided for @mapFilterByType.
  ///
  /// In en, this message translates to:
  /// **'Filter by type'**
  String get mapFilterByType;

  /// No description provided for @mapFilterByStatus.
  ///
  /// In en, this message translates to:
  /// **'Filter by status'**
  String get mapFilterByStatus;
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
      <String>['en', 'he'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'he':
      return AppLocalizationsHe();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
