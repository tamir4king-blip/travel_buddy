import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_buddy_mobile/features/profile/presentation/widgets/israel_explorer_section.dart';
import 'package:travel_buddy_mobile/shared/data/israel/israel_catalog.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';

List<Achievement> withUnlocked(Set<String> ids) => [
      for (final a in israelAchievementRegistry)
        ids.contains(a.id) ? a.copyWith(isUnlocked: true, visitCount: 2) : a,
    ];

Future<void> pump(WidgetTester tester, List<Achievement> all, Locale locale) {
  // A phone-sized surface so wrapping and ellipsis paths are exercised.
  tester.view.physicalSize = const Size(390 * 3, 2400 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  return tester.pumpWidget(MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('en'), Locale('he')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: IsraelExplorerView(achievements: all),
      ),
    ),
  ));
}

void main() {
  testWidgets('empty profile renders the newcomer state', (tester) async {
    await pump(tester, israelAchievementRegistry, const Locale('en'));
    await tester.pumpAndSettle();

    expect(find.text('Newcomer'), findsOneWidget);
    expect(find.text('Visit places to discover your traveler type'),
        findsOneWidget);
    expect(find.text('Traveler DNA'), findsNothing);
    expect(find.text('Golan Heights'), findsOneWidget); // region chip
    expect(tester.takeException(), isNull);
  });

  testWidgets('a traveled profile shows archetype, DNA and signatures',
      (tester) async {
    await pump(
      tester,
      withUnlocked({
        'il-metula', 'il-masada', 'il-makhtesh-ramon', 'il-avdat',
        'il-timna', 'il-coral-beach', 'il-tel-aviv',
      }),
      const Locale('en'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Wanderer'), findsOneWidget);
    expect(find.textContaining('Desert Wanderer'), findsOneWidget);
    expect(find.text('Traveler DNA'), findsOneWidget);
    expect(find.text('Northernmost'), findsOneWidget);
    expect(find.text('Metula'), findsOneWidget);
    expect(find.text('Coral Beach Reserve'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders in Hebrew without layout errors', (tester) async {
    await pump(
      tester,
      withUnlocked({'il-jerusalem', 'il-haifa', 'il-eilat'}),
      const Locale('he'),
    );
    await tester.pumpAndSettle();

    expect(find.text('אזורים — 3/17'), findsOneWidget);
    expect(find.text('ירושלים'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
