import 'package:flutter_test/flutter_test.dart';
import 'package:travel_buddy_mobile/shared/utils/xp_rules.dart';

/// These formulas are mirrored by the SQL functions in
/// supabase/migrations/20260610000002_server_authoritative_xp.sql.
/// If a test here changes, the SQL must change with it.
void main() {
  group('XpRules.levelForXp', () {
    test('level boundaries match the curve', () {
      expect(XpRules.levelForXp(0), 1);
      expect(XpRules.levelForXp(99), 1);
      expect(XpRules.levelForXp(100), 2);
      expect(XpRules.levelForXp(249), 2);
      expect(XpRules.levelForXp(250), 3);
      expect(XpRules.levelForXp(849), 4);
      expect(XpRules.levelForXp(850), 5);
      expect(XpRules.levelForXp(4250), 10);
      expect(XpRules.levelForXp(5399), 10);
    });

    test('beyond level 10 every 1500 XP is a level', () {
      expect(XpRules.levelForXp(5400), 10);
      expect(XpRules.levelForXp(6899), 10);
      expect(XpRules.levelForXp(6900), 11);
      expect(XpRules.levelForXp(8399), 11);
      expect(XpRules.levelForXp(8400), 12);
    });

    test('xpForLevel returns the threshold table entry (legacy semantics)', () {
      // Note: xpForLevel(L) is thresholds[L] — the XP where level L+1
      // begins, not where L begins. Kept as-is for parity with the
      // original UserProfileNotifier implementation the UI was built on.
      expect(XpRules.xpForLevel(1), 100);
      expect(XpRules.xpForLevel(2), 250);
      expect(XpRules.xpForLevel(10), 5400);
      expect(XpRules.xpForLevel(11), 6900);
      expect(XpRules.xpForLevel(12), 8400);
    });

    test('xpToNextLevel counts down to the next table entry', () {
      expect(XpRules.xpToNextLevel(0, 1), 250);
      expect(XpRules.xpToNextLevel(120, 2), 380);
      expect(XpRules.xpToNextLevel(5400, 10), 1500);
    });
  });

  group('XpRules.questXp', () {
    test('diminishing returns: 100/75/50/25 percent', () {
      expect(XpRules.questXp(100, 1), 100);
      expect(XpRules.questXp(100, 2), 75);
      expect(XpRules.questXp(100, 3), 50);
      expect(XpRules.questXp(100, 4), 25);
    });

    test('every repeat after the third stays at 25 percent', () {
      expect(XpRules.questXp(100, 5), 25);
      expect(XpRules.questXp(100, 99), 25);
    });

    test('rounds half away from zero like the SQL round()', () {
      expect(XpRules.questXp(15, 2), 11); // 11.25
      expect(XpRules.questXp(10, 3), 5);
      expect(XpRules.questXp(5, 4), 1); // 1.25
      expect(XpRules.questXp(2, 2), 2); // 1.5 -> 2
    });

    test('zeroth/first completion both award full XP', () {
      expect(XpRules.questXp(40, 0), 40);
      expect(XpRules.questXp(40, 1), 40);
    });
  });

  group('XpRules.achievementXp', () {
    test('normal claims award full XP', () {
      expect(XpRules.achievementXp(50), 50);
      expect(XpRules.achievementXp(35, isRetroactive: false), 35);
    });

    test('retroactive claims award 80 percent, rounded', () {
      expect(XpRules.achievementXp(50, isRetroactive: true), 40);
      expect(XpRules.achievementXp(35, isRetroactive: true), 28);
      expect(XpRules.achievementXp(10, isRetroactive: true), 8);
      expect(XpRules.achievementXp(33, isRetroactive: true), 26); // 26.4
    });
  });

  group('XpRules.withPhotoBonus', () {
    test('adds 15 percent, rounded', () {
      expect(XpRules.withPhotoBonus(100), 115);
      expect(XpRules.withPhotoBonus(40), 46);
      expect(XpRules.withPhotoBonus(10), 12); // 11.5 -> 12
    });
  });
}
