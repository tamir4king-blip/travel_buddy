// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navMap => 'Map';

  @override
  String get navQuests => 'Quests';

  @override
  String get navRankings => 'Rankings';

  @override
  String get navAchievements => 'Achievements';

  @override
  String get navProfile => 'Profile';

  @override
  String get navExplore => 'Explore';

  @override
  String get navLog => 'Log';

  @override
  String get activityLog => 'Activity Log';

  @override
  String get welcomeBack => 'Welcome back,';

  @override
  String levelN(int level) {
    return 'Level $level';
  }

  @override
  String xpAmount(int xp) {
    return '$xp XP';
  }

  @override
  String xpToNextLevel(int xp) {
    return '$xp XP to next level';
  }

  @override
  String get achievements => 'Achievements';

  @override
  String get quests => 'Quests';

  @override
  String get streak => 'Streak';

  @override
  String streakDays(int days) {
    return '${days}d';
  }

  @override
  String get nearbyAdventures => 'Nearby Adventures';

  @override
  String get exploreYourCity => 'Explore your city';

  @override
  String achievementsToUnlock(int count) {
    return '$count achievements to unlock';
  }

  @override
  String get dailyQuestAvailable => 'Daily Quest Available';

  @override
  String get takePhotoAtLandmark => 'Take a photo at a landmark';

  @override
  String get yourCollections => 'Your Collections';

  @override
  String get complete => 'COMPLETE';

  @override
  String get collectionBeaches => 'Beaches';

  @override
  String get collectionLandmarks => 'Landmarks';

  @override
  String get collectionParks => 'Parks';

  @override
  String get collectionCulture => 'Culture';

  @override
  String get collectionEurope => 'Europe';

  @override
  String get collectionAmericas => 'Americas';

  @override
  String get collectionNationalParks => 'National Parks';

  @override
  String get collectionSkiResorts => 'Ski Resorts';

  @override
  String get collectionCapitals => 'Capitals';

  @override
  String get collectionAncientSites => 'Ancient Sites';

  @override
  String get collectionTouristDestinations => 'Top Destinations';

  @override
  String exploreCity(String city) {
    return 'Explore $city';
  }

  @override
  String get totalXp => 'Total XP';

  @override
  String get totalSkillLevel => 'Skill Level';

  @override
  String get level => 'Level';

  @override
  String get trophies => 'Trophies';

  @override
  String get account => 'Account';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get privacySettings => 'Privacy Settings';

  @override
  String get notifications => 'Notifications';

  @override
  String get preferences => 'Preferences';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get locationSettings => 'Location Settings';

  @override
  String get support => 'Support';

  @override
  String get helpAndFaq => 'Help & FAQ';

  @override
  String get feedback => 'Feedback';

  @override
  String get logOut => 'Log Out';

  @override
  String get sideQuests => 'Side Quests';

  @override
  String get clear => 'Clear';

  @override
  String completedCount(int count) {
    return '$count completed';
  }

  @override
  String dayStreak(int count) {
    return '$count day streak';
  }

  @override
  String get skills => 'Skills';

  @override
  String lvN(int level) {
    return 'Lv $level';
  }

  @override
  String get categoryAll => 'All';

  @override
  String get categoryHiking => 'Hiking';

  @override
  String get categoryFood => 'Food';

  @override
  String get categoryPhoto => 'Photo';

  @override
  String get categoryCulture => 'Culture';

  @override
  String get categoryWater => 'Water';

  @override
  String get categoryFishing => 'Fishing';

  @override
  String get categoryCamping => 'Camping';

  @override
  String get categoryExtreme => 'Extreme';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyMedium => 'Medium';

  @override
  String get difficultyHard => 'Hard';

  @override
  String get difficultyLegendary => 'Legendary';

  @override
  String get start => 'Start';

  @override
  String get repeat => 'Repeat';

  @override
  String get completeQuest => 'Complete Quest';

  @override
  String get completeAgain => 'Complete Again';

  @override
  String get verificationPhoto => 'Photo proof';

  @override
  String get verificationLocation => 'Location check';

  @override
  String get verificationTime => 'Time based';

  @override
  String get verificationManual => 'Manual';

  @override
  String unlockedOfTotal(int unlocked, int total) {
    return '$unlocked of $total unlocked';
  }

  @override
  String get tierAll => 'All';

  @override
  String get tierBronze => 'Bronze';

  @override
  String get tierSilver => 'Silver';

  @override
  String get tierGold => 'Gold';

  @override
  String get tierPlatinum => 'Platinum';

  @override
  String get searchAchievements => 'Search achievements...';

  @override
  String get regularAchievements => 'Regular Achievements';

  @override
  String get claim => 'Claim';

  @override
  String get masterAchievements => 'Master Achievements';

  @override
  String masteredOfTotal(int unlocked, int total) {
    return '$unlocked of $total mastered';
  }

  @override
  String get tierElite => 'ELITE';

  @override
  String get tierLegendary => 'LEGENDARY';

  @override
  String get tierMythic => 'MYTHIC';

  @override
  String percentComplete(int percent) {
    return '$percent% complete';
  }

  @override
  String get leaderboard => 'Leaderboard';

  @override
  String participants(int count) {
    return '$count participants';
  }

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get allTime => 'All Time';

  @override
  String get travelBuddy => 'TravelBuddy';

  @override
  String get gamifiedTravelCompanion => 'Your gamified travel companion';

  @override
  String get login => 'Login';

  @override
  String get signUp => 'Sign Up';

  @override
  String get displayName => 'Display Name';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get createAccount => 'Create Account';

  @override
  String get continueAsGuest => 'Continue as Guest';

  @override
  String get save => 'Save';

  @override
  String get yourDisplayName => 'Your display name';

  @override
  String get username => 'Username';

  @override
  String get bio => 'Bio';

  @override
  String get tellUsAboutYourself => 'Tell us about yourself...';

  @override
  String get publicProfile => 'Public Profile';

  @override
  String get allowOthersToSeeProfile => 'Allow others to see your profile';

  @override
  String get showOnLeaderboard => 'Show on Leaderboard';

  @override
  String get appearInPublicRankings => 'Appear in public rankings';

  @override
  String get appSettings => 'App Settings';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get gpsPermission => 'GPS permission for location-based achievements';

  @override
  String get collectionComplete => 'Collection Complete!';

  @override
  String bonusXpAmount(int xp) {
    return '+$xp Bonus XP';
  }

  @override
  String get awesome => 'Awesome!';

  @override
  String claimNowXp(int xp) {
    return 'Claim Now (+$xp XP)';
  }

  @override
  String get orClaimRetroactively => 'or claim retroactively';

  @override
  String get whenDidYouAccomplish => 'When did you accomplish this?';

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String get addDetailsAboutExperience =>
      'Add details about your experience...';

  @override
  String get photosOptional => 'Photos (optional)';

  @override
  String retroactiveXpNotice(int xp) {
    return 'Retroactive claims earn 80% XP (+$xp XP)';
  }

  @override
  String get claimRetroactively => 'Claim Retroactively';

  @override
  String get mapView => 'Map View';

  @override
  String get configureMapTiler =>
      'Configure MAPTILER_KEY to enable MapLibre GL';

  @override
  String get locating => 'Locating...';

  @override
  String get centerOnMe => 'Center on Me';

  @override
  String get nearbyAchievements => 'Nearby Achievements';

  @override
  String get locationOn => 'Location on';

  @override
  String get locationOff => 'Location off';

  @override
  String get enableLocationToSee =>
      'Enable location to see nearby achievements.';

  @override
  String get noAchievementsInRange => 'No achievements within range.';

  @override
  String get unlocked => 'Unlocked';

  @override
  String get add => 'Add';

  @override
  String get liveTracking => 'Live Tracking';

  @override
  String get liveTrackingDescription =>
      'Continuous GPS tracking for proximity alerts';

  @override
  String get achievementNearby => 'ACHIEVEMENT NEARBY';

  @override
  String get distanceAway => 'away';

  @override
  String get getCloser => 'Get Closer';

  @override
  String get inRange => 'In Range';

  @override
  String get startTracking => 'Start Tracking';

  @override
  String get stopTracking => 'Stop Tracking';

  @override
  String get trackingActive => 'Tracking Active';

  @override
  String get trackingOff => 'Tracking Off';

  @override
  String achievementsNearYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count achievements near you',
      one: '1 achievement near you',
    );
    return '$_temp0';
  }

  @override
  String get tapToClaim => 'Tap to claim';

  @override
  String get visitToUnlock => 'Visit to unlock';

  @override
  String unlockedOn(String date) {
    return 'Unlocked on $date';
  }

  @override
  String kmAway(String distance) {
    return '${distance}km away';
  }

  @override
  String mAway(String distance) {
    return '${distance}m away';
  }

  @override
  String memberSince(String date) {
    return 'Member since $date';
  }

  @override
  String get topSkills => 'Top Skills';

  @override
  String get seeAll => 'See All';

  @override
  String get recentAchievements => 'Recent Achievements';

  @override
  String get collections => 'Collections';

  @override
  String get changePhoto => 'Change Photo';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get displayNameRequired => 'Display name is required';

  @override
  String get displayNameTooLong => 'Display name must be 30 characters or less';

  @override
  String get usernameTooShort => 'Username must be at least 3 characters';

  @override
  String get usernameTooLong => 'Username must be 20 characters or less';

  @override
  String get usernameInvalid =>
      'Username can only contain letters, numbers, and underscores';

  @override
  String get bioTooLong => 'Bio must be 200 characters or less';

  @override
  String get noSkillsYet => 'Complete quests to develop your skills!';

  @override
  String get noAchievementsYet => 'Start exploring to unlock achievements!';

  @override
  String get yourRank => 'Your Rank';

  @override
  String get retry => 'Retry';

  @override
  String rankN(int rank) {
    return 'Rank #$rank';
  }

  @override
  String get navSkills => 'Skills';

  @override
  String get locked => 'Locked';

  @override
  String requires(String requirement) {
    return 'Requires: $requirement';
  }

  @override
  String get relatedQuests => 'Related Quests';

  @override
  String get viewQuests => 'View Quests';

  @override
  String completedOfTotal(int completed, int total) {
    return '$completed of $total completed';
  }

  @override
  String xpNeeded(int xp) {
    return '$xp XP needed';
  }

  @override
  String nSkills(int count) {
    return '$count skills';
  }

  @override
  String get searchCountries => 'Search countries...';

  @override
  String get allCountries => 'All';

  @override
  String get nUnlocked => 'unlocked';

  @override
  String get visited => 'Visited';

  @override
  String get tabCities => 'Cities';

  @override
  String get tabLandmarks => 'Landmarks';

  @override
  String get tabFood => 'Food';

  @override
  String get tabActivities => 'Activities';

  @override
  String nCities(int count) {
    return '$count cities';
  }

  @override
  String nLandmarks(int count) {
    return '$count landmarks';
  }

  @override
  String get english => 'English';

  @override
  String get hebrew => 'עברית';

  @override
  String get pleaseEnterName => 'Please enter your name';

  @override
  String get pleaseEnterEmail => 'Please enter your email';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get proximityNotifications => 'Proximity Notifications';

  @override
  String get nativeAlertsNearAchievements =>
      'Native alerts when near achievements';

  @override
  String get tabCountries => 'Countries';

  @override
  String get tabCapitals => 'Capitals';

  @override
  String get tabNationalParks => 'National Parks';

  @override
  String get tabSkiResorts => 'Ski Resorts';

  @override
  String get tabAncientSites => 'Ancient Sites';

  @override
  String get tabTopDestinations => 'Top Destinations';

  @override
  String get exploreNationsSubtitle => 'Explore nations across the globe';

  @override
  String get capitalCitiesSubtitle => 'Visit the world\'s great capital cities';

  @override
  String get nationalParksSubtitle => 'Discover protected natural wonders';

  @override
  String get skiResortsSubtitle => 'Hit the slopes at legendary mountains';

  @override
  String get ancientSitesSubtitle => 'Sacred places of ancient faith';

  @override
  String get topDestinationsSubtitle => 'The world\'s most popular places';

  @override
  String get tierBronzeLabel => 'BRONZE';

  @override
  String get tierSilverLabel => 'SILVER';

  @override
  String get tierGoldLabel => 'GOLD';

  @override
  String get tierPlatinumLabel => 'PLATINUM';

  @override
  String get continentEurope => 'Europe';

  @override
  String get continentAmericas => 'Americas';

  @override
  String get continentAsia => 'Asia';

  @override
  String get continentAfrica => 'Africa';

  @override
  String get continentOceania => 'Oceania';

  @override
  String get exploreTheWorld => 'Explore the World';

  @override
  String get trackTravelsAcrossContinents =>
      'Track your travels across continents';

  @override
  String get tabCountriesHome => 'Countries';

  @override
  String get tabCollectionsHome => 'Collections';

  @override
  String get trophyCommandCenter => 'Trophy Command Center';

  @override
  String shownCountOfTotal(int shown, int total) {
    return '$shown / $total shown';
  }

  @override
  String quickFilterUnlockedCount(int count) {
    return 'Unlocked ($count)';
  }

  @override
  String quickFilterLockedCount(int count) {
    return 'Locked ($count)';
  }

  @override
  String quickFilterNearbyCount(int count) {
    return 'Nearby ($count)';
  }

  @override
  String quickFilterHighXpCount(int count) {
    return 'High XP ($count)';
  }

  @override
  String nextTargetLabel(String title) {
    return 'Next target: $title';
  }

  @override
  String get allTrophiesInCategoryUnlocked =>
      'All trophies in this category unlocked.';

  @override
  String get collectionHeatmap => 'Collection Heatmap';

  @override
  String get noHeatmapData => 'No heatmap data.';

  @override
  String heatmapUnlockedOfTotal(int unlocked, int total) {
    return '$unlocked/$total unlocked';
  }

  @override
  String get heatmapOther => 'Other';

  @override
  String get achievementUnlocked => 'ACHIEVEMENT UNLOCKED!';

  @override
  String get unlockTimeline => 'Unlock Timeline';

  @override
  String get noUnlockedTrophiesYet => 'No unlocked trophies yet.';

  @override
  String get mapFilterAchievements => 'Achievements';

  @override
  String get mapFilterQuests => 'Quests';

  @override
  String get mapFilterSkills => 'Skills';

  @override
  String get mapCloseMap => 'Close map';

  @override
  String get mapZoomIn => 'Zoom in';

  @override
  String get mapZoomOut => 'Zoom out';

  @override
  String get mapResetCompass => 'Reset compass';

  @override
  String get mapMyLocation => 'My location';

  @override
  String get mapFilters => 'Filters';

  @override
  String get mapNearby => 'Nearby';

  @override
  String get mapActiveQuests => 'Active Quests';

  @override
  String get mapCompletedFilter => 'Completed';

  @override
  String get mapStartQuestHere => 'Start quest here?';

  @override
  String get mapLogVisit => 'Log visit';

  @override
  String get mapViewDetails => 'View Details';

  @override
  String get mapFilterByType => 'Filter by type';

  @override
  String get mapFilterByStatus => 'Filter by status';
}
