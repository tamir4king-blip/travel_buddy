// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get navHome => 'בית';

  @override
  String get navMap => 'מפה';

  @override
  String get navQuests => 'משימות';

  @override
  String get navRankings => 'דירוגים';

  @override
  String get navAchievements => 'הישגים';

  @override
  String get navProfile => 'פרופיל';

  @override
  String get navExplore => 'גלה';

  @override
  String get navLog => 'יומן';

  @override
  String get activityLog => 'יומן פעילות';

  @override
  String get welcomeBack => 'ברוך שובך,';

  @override
  String levelN(int level) {
    return 'רמה $level';
  }

  @override
  String xpAmount(int xp) {
    return '$xp XP';
  }

  @override
  String xpToNextLevel(int xp) {
    return '$xp XP לרמה הבאה';
  }

  @override
  String get achievements => 'הישגים';

  @override
  String get quests => 'משימות';

  @override
  String get streak => 'רצף';

  @override
  String streakDays(int days) {
    return '$daysי׳';
  }

  @override
  String get nearbyAdventures => 'הרפתקאות קרובות';

  @override
  String get exploreYourCity => 'חקור את העיר שלך';

  @override
  String achievementsToUnlock(int count) {
    return '$count הישגים לפתיחה';
  }

  @override
  String get dailyQuestAvailable => 'משימה יומית זמינה';

  @override
  String get takePhotoAtLandmark => 'צלם תמונה באתר ציון דרך';

  @override
  String get yourCollections => 'האוספים שלך';

  @override
  String get complete => 'הושלם';

  @override
  String get collectionBeaches => 'חופים';

  @override
  String get collectionLandmarks => 'ציוני דרך';

  @override
  String get collectionParks => 'פארקים';

  @override
  String get collectionCulture => 'תרבות';

  @override
  String get collectionEurope => 'אירופה';

  @override
  String get collectionAmericas => 'אמריקה';

  @override
  String get collectionNationalParks => 'פארקים לאומיים';

  @override
  String get collectionSkiResorts => 'אתרי סקי';

  @override
  String get collectionCapitals => 'בירות';

  @override
  String get collectionAncientSites => 'אתרים עתיקים';

  @override
  String get collectionTouristDestinations => 'יעדים פופולריים';

  @override
  String exploreCity(String city) {
    return 'חקור את $city';
  }

  @override
  String get totalXp => 'סה\"כ XP';

  @override
  String get totalSkillLevel => 'רמת מיומנות';

  @override
  String get level => 'רמה';

  @override
  String get trophies => 'גביעים';

  @override
  String get account => 'חשבון';

  @override
  String get editProfile => 'ערוך פרופיל';

  @override
  String get privacySettings => 'הגדרות פרטיות';

  @override
  String get notifications => 'התראות';

  @override
  String get preferences => 'העדפות';

  @override
  String get language => 'שפה';

  @override
  String get theme => 'ערכת נושא';

  @override
  String get locationSettings => 'הגדרות מיקום';

  @override
  String get support => 'תמיכה';

  @override
  String get helpAndFaq => 'עזרה ושאלות נפוצות';

  @override
  String get feedback => 'משוב';

  @override
  String get logOut => 'התנתק';

  @override
  String get sideQuests => 'משימות צד';

  @override
  String get clear => 'נקה';

  @override
  String completedCount(int count) {
    return '$count הושלמו';
  }

  @override
  String dayStreak(int count) {
    return 'רצף של $count ימים';
  }

  @override
  String get skills => 'כישורים';

  @override
  String lvN(int level) {
    return 'רמה $level';
  }

  @override
  String get categoryAll => 'הכל';

  @override
  String get categoryHiking => 'טיולים';

  @override
  String get categoryFood => 'אוכל';

  @override
  String get categoryPhoto => 'צילום';

  @override
  String get categoryCulture => 'תרבות';

  @override
  String get categoryWater => 'מים';

  @override
  String get categoryFishing => 'דיג';

  @override
  String get categoryCamping => 'קמפינג';

  @override
  String get categoryExtreme => 'אקסטרים';

  @override
  String get difficultyEasy => 'קל';

  @override
  String get difficultyMedium => 'בינוני';

  @override
  String get difficultyHard => 'קשה';

  @override
  String get difficultyLegendary => 'אגדי';

  @override
  String get start => 'התחל';

  @override
  String get repeat => 'חזור';

  @override
  String get completeQuest => 'השלם משימה';

  @override
  String get completeAgain => 'השלם שוב';

  @override
  String get verificationPhoto => 'הוכחת צילום';

  @override
  String get verificationLocation => 'בדיקת מיקום';

  @override
  String get verificationTime => 'מבוסס זמן';

  @override
  String get verificationManual => 'ידני';

  @override
  String unlockedOfTotal(int unlocked, int total) {
    return '$unlocked מתוך $total נפתחו';
  }

  @override
  String get tierAll => 'הכל';

  @override
  String get tierBronze => 'ארד';

  @override
  String get tierSilver => 'כסף';

  @override
  String get tierGold => 'זהב';

  @override
  String get tierPlatinum => 'פלטינה';

  @override
  String get searchAchievements => 'חפש הישגים...';

  @override
  String get regularAchievements => 'הישגים רגילים';

  @override
  String get claim => 'תבע';

  @override
  String get masterAchievements => 'הישגי מאסטר';

  @override
  String masteredOfTotal(int unlocked, int total) {
    return '$unlocked מתוך $total הושלמו';
  }

  @override
  String get tierElite => 'עילית';

  @override
  String get tierLegendary => 'אגדי';

  @override
  String get tierMythic => 'מיתי';

  @override
  String percentComplete(int percent) {
    return '$percent% הושלם';
  }

  @override
  String get leaderboard => 'טבלת מובילים';

  @override
  String participants(int count) {
    return '$count משתתפים';
  }

  @override
  String get weekly => 'שבועי';

  @override
  String get monthly => 'חודשי';

  @override
  String get allTime => 'כל הזמנים';

  @override
  String get travelBuddy => 'TravelBuddy';

  @override
  String get gamifiedTravelCompanion => 'חבר הטיולים המשחקי שלך';

  @override
  String get login => 'התחבר';

  @override
  String get signUp => 'הרשם';

  @override
  String get displayName => 'שם תצוגה';

  @override
  String get email => 'אימייל';

  @override
  String get password => 'סיסמה';

  @override
  String get createAccount => 'צור חשבון';

  @override
  String get continueAsGuest => 'המשך כאורח';

  @override
  String get save => 'שמור';

  @override
  String get yourDisplayName => 'שם התצוגה שלך';

  @override
  String get username => 'שם משתמש';

  @override
  String get bio => 'אודות';

  @override
  String get tellUsAboutYourself => 'ספר לנו על עצמך...';

  @override
  String get publicProfile => 'פרופיל ציבורי';

  @override
  String get allowOthersToSeeProfile => 'אפשר לאחרים לראות את הפרופיל שלך';

  @override
  String get showOnLeaderboard => 'הצג בטבלת מובילים';

  @override
  String get appearInPublicRankings => 'הופע בדירוגים הציבוריים';

  @override
  String get appSettings => 'הגדרות אפליקציה';

  @override
  String get comingSoon => 'בקרוב';

  @override
  String get gpsPermission => 'הרשאת GPS להישגים מבוססי מיקום';

  @override
  String get collectionComplete => 'האוסף הושלם!';

  @override
  String bonusXpAmount(int xp) {
    return '+$xp XP בונוס';
  }

  @override
  String get awesome => 'מדהים!';

  @override
  String claimNowXp(int xp) {
    return 'תבע עכשיו (+$xp XP)';
  }

  @override
  String get orClaimRetroactively => 'או תבע רטרואקטיבית';

  @override
  String get whenDidYouAccomplish => 'מתי השגת את זה?';

  @override
  String get notesOptional => 'הערות (אופציונלי)';

  @override
  String get addDetailsAboutExperience => 'הוסף פרטים על החוויה שלך...';

  @override
  String get photosOptional => 'תמונות (אופציונלי)';

  @override
  String retroactiveXpNotice(int xp) {
    return 'תביעות רטרואקטיביות מזכות ב-80% XP (+$xp XP)';
  }

  @override
  String get claimRetroactively => 'תבע רטרואקטיבית';

  @override
  String get mapView => 'תצוגת מפה';

  @override
  String get configureMapTiler => 'הגדר MAPTILER_KEY כדי לאפשר MapLibre GL';

  @override
  String get locating => 'מאתר...';

  @override
  String get centerOnMe => 'מרכז עליי';

  @override
  String get nearbyAchievements => 'הישגים קרובים';

  @override
  String get locationOn => 'מיקום פעיל';

  @override
  String get locationOff => 'מיקום כבוי';

  @override
  String get enableLocationToSee => 'הפעל מיקום כדי לראות הישגים קרובים.';

  @override
  String get noAchievementsInRange => 'אין הישגים בטווח.';

  @override
  String get unlocked => 'נפתח';

  @override
  String get add => 'הוסף';

  @override
  String get liveTracking => 'מעקב חי';

  @override
  String get liveTrackingDescription => 'מעקב GPS רציף להתראות קרבה';

  @override
  String get achievementNearby => 'הישג בקרבת מקום';

  @override
  String get distanceAway => 'משם';

  @override
  String get getCloser => 'התקרב';

  @override
  String get inRange => 'בטווח';

  @override
  String get startTracking => 'התחל מעקב';

  @override
  String get stopTracking => 'עצור מעקב';

  @override
  String get trackingActive => 'מעקב פעיל';

  @override
  String get trackingOff => 'מעקב כבוי';

  @override
  String achievementsNearYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count הישגים בקרבתך',
      one: 'הישג אחד בקרבתך',
    );
    return '$_temp0';
  }

  @override
  String get tapToClaim => 'הקש לתביעה';

  @override
  String get visitToUnlock => 'בקר כדי לפתוח';

  @override
  String unlockedOn(String date) {
    return 'נפתח ב-$date';
  }

  @override
  String kmAway(String distance) {
    return '$distance ק\"מ משם';
  }

  @override
  String mAway(String distance) {
    return '$distance מ׳ משם';
  }

  @override
  String memberSince(String date) {
    return 'חבר מאז $date';
  }

  @override
  String get topSkills => 'כישורים מובילים';

  @override
  String get seeAll => 'הצג הכל';

  @override
  String get recentAchievements => 'הישגים אחרונים';

  @override
  String get collections => 'אוספים';

  @override
  String get changePhoto => 'שנה תמונה';

  @override
  String get profileUpdated => 'הפרופיל עודכן';

  @override
  String get displayNameRequired => 'שם תצוגה הוא שדה חובה';

  @override
  String get displayNameTooLong => 'שם תצוגה חייב להיות 30 תווים או פחות';

  @override
  String get usernameTooShort => 'שם משתמש חייב להיות לפחות 3 תווים';

  @override
  String get usernameTooLong => 'שם משתמש חייב להיות 20 תווים או פחות';

  @override
  String get usernameInvalid =>
      'שם משתמש יכול להכיל רק אותיות, מספרים וקו תחתון';

  @override
  String get bioTooLong => 'אודות חייב להיות 200 תווים או פחות';

  @override
  String get noSkillsYet => 'השלם משימות כדי לפתח את הכישורים שלך!';

  @override
  String get noAchievementsYet => 'התחל לחקור כדי לפתוח הישגים!';

  @override
  String get yourRank => 'הדירוג שלך';

  @override
  String get retry => 'נסה שוב';

  @override
  String rankN(int rank) {
    return 'דירוג #$rank';
  }

  @override
  String get navSkills => 'כישורים';

  @override
  String get locked => 'נעול';

  @override
  String requires(String requirement) {
    return 'דורש: $requirement';
  }

  @override
  String get relatedQuests => 'משימות קשורות';

  @override
  String get viewQuests => 'צפה במשימות';

  @override
  String completedOfTotal(int completed, int total) {
    return '$completed מתוך $total הושלמו';
  }

  @override
  String xpNeeded(int xp) {
    return '$xp נק׳ ניסיון נדרשות';
  }

  @override
  String nSkills(int count) {
    return '$count כישורים';
  }

  @override
  String get searchCountries => 'חפש מדינות...';

  @override
  String get allCountries => 'הכל';

  @override
  String get nUnlocked => 'נפתחו';

  @override
  String get visited => 'ביקרת';

  @override
  String get tabCities => 'ערים';

  @override
  String get tabLandmarks => 'אתרים';

  @override
  String get tabFood => 'אוכל';

  @override
  String get tabActivities => 'פעילויות';

  @override
  String nCities(int count) {
    return '$count ערים';
  }

  @override
  String nLandmarks(int count) {
    return '$count אתרים';
  }

  @override
  String get english => 'English';

  @override
  String get hebrew => 'עברית';

  @override
  String get pleaseEnterName => 'נא להזין את שמך';

  @override
  String get pleaseEnterEmail => 'נא להזין את האימייל שלך';

  @override
  String get pleaseEnterValidEmail => 'נא להזין אימייל תקין';

  @override
  String get pleaseEnterPassword => 'נא להזין סיסמה';

  @override
  String get passwordMinLength => 'הסיסמה חייבת להכיל לפחות 6 תווים';

  @override
  String get proximityNotifications => 'התראות קרבה';

  @override
  String get nativeAlertsNearAchievements => 'התראות כשאתה קרוב להישגים';

  @override
  String get tabCountries => 'מדינות';

  @override
  String get tabCapitals => 'בירות';

  @override
  String get tabNationalParks => 'פארקים לאומיים';

  @override
  String get tabSkiResorts => 'אתרי סקי';

  @override
  String get tabAncientSites => 'אתרים עתיקים';

  @override
  String get tabTopDestinations => 'יעדים מובילים';

  @override
  String get exploreNationsSubtitle => 'חקור מדינות ברחבי העולם';

  @override
  String get capitalCitiesSubtitle => 'בקר בבירות הגדולות של העולם';

  @override
  String get nationalParksSubtitle => 'גלה פלאי טבע מוגנים';

  @override
  String get skiResortsSubtitle => 'גלוש במדרונות הרים אגדיים';

  @override
  String get ancientSitesSubtitle => 'מקומות קדושים של אמונה עתיקה';

  @override
  String get topDestinationsSubtitle => 'המקומות הפופולריים בעולם';

  @override
  String get tierBronzeLabel => 'ארד';

  @override
  String get tierSilverLabel => 'כסף';

  @override
  String get tierGoldLabel => 'זהב';

  @override
  String get tierPlatinumLabel => 'פלטינה';

  @override
  String get continentEurope => 'אירופה';

  @override
  String get continentAmericas => 'אמריקה';

  @override
  String get continentAsia => 'אסיה';

  @override
  String get continentAfrica => 'אפריקה';

  @override
  String get continentOceania => 'אוקיאניה';

  @override
  String get exploreTheWorld => 'חקור את העולם';

  @override
  String get trackTravelsAcrossContinents => 'עקוב אחרי הטיולים שלך בין יבשות';

  @override
  String get tabCountriesHome => 'מדינות';

  @override
  String get tabCollectionsHome => 'אוספים';

  @override
  String get trophyCommandCenter => 'מרכז הגביעים';

  @override
  String shownCountOfTotal(int shown, int total) {
    return '$shown מתוך $total מוצגים';
  }

  @override
  String quickFilterUnlockedCount(int count) {
    return 'נפתחו ($count)';
  }

  @override
  String quickFilterLockedCount(int count) {
    return 'נעולים ($count)';
  }

  @override
  String quickFilterNearbyCount(int count) {
    return 'קרובים ($count)';
  }

  @override
  String quickFilterHighXpCount(int count) {
    return 'XP גבוה ($count)';
  }

  @override
  String nextTargetLabel(String title) {
    return 'יעד הבא: $title';
  }

  @override
  String get allTrophiesInCategoryUnlocked =>
      'כל הגביעים בקטגוריה הזאת כבר נפתחו.';

  @override
  String get collectionHeatmap => 'מפת חום של אוספים';

  @override
  String get noHeatmapData => 'אין נתוני מפת חום.';

  @override
  String heatmapUnlockedOfTotal(int unlocked, int total) {
    return '$unlocked/$total נפתחו';
  }

  @override
  String get heatmapOther => 'אחר';

  @override
  String get achievementUnlocked => '!הישג נפתח';

  @override
  String get unlockTimeline => 'ציר זמן פתיחות';

  @override
  String get noUnlockedTrophiesYet => 'עדיין לא נפתחו גביעים.';

  @override
  String get mapFilterAchievements => 'הישגים';

  @override
  String get mapFilterQuests => 'משימות';

  @override
  String get mapFilterSkills => 'כישורים';

  @override
  String get mapCloseMap => 'סגור מפה';

  @override
  String get mapZoomIn => 'הגדל';

  @override
  String get mapZoomOut => 'הקטן';

  @override
  String get mapResetCompass => 'אפס מצפן';

  @override
  String get mapMyLocation => 'המיקום שלי';

  @override
  String get mapFilters => 'מסננים';

  @override
  String get mapNearby => 'בקרבת מקום';

  @override
  String get mapActiveQuests => 'משימות פעילות';

  @override
  String get mapCompletedFilter => 'הושלמו';

  @override
  String get mapStartQuestHere => 'להתחיל משימה כאן?';

  @override
  String get mapLogVisit => 'רשום ביקור';

  @override
  String get mapViewDetails => 'הצג פרטים';

  @override
  String get mapFilterByType => 'סנן לפי סוג';

  @override
  String get mapFilterByStatus => 'סנן לפי סטטוס';
}
