import 'package:travel_buddy_mobile/shared/models/quest.dart';

/// Story quest registry — narrative chains of activities & achievements.
/// Each quest has ordered steps that reference activity IDs (from quest_registry)
/// or achievement IDs (from achievement_registry). Steps auto-complete when
/// the underlying activity/achievement is fulfilled.
///
/// Add new quests here over time. The system auto-detects step completion.

const storyQuestRegistry = <Quest>[
  // ── Netanya Explorer ──────────────────────────────────────────────────────
  Quest(
    id: 'netanya-explorer',
    title: 'Netanya Explorer',
    description: 'Discover the highlights of Netanya — from the beach to the market to the cliffs.',
    icon: '🏖️',
    rarity: QuestRarity.common,
    xpReward: 200,
    steps: [
      QuestStep(
        id: 'ne-step-1',
        title: 'Walk the Promenade',
        description: 'Complete the full promenade walk along the Netanya cliffs.',
        type: QuestStepType.activity,
        targetId: 'netanya-promenade',
        order: 0,
      ),
      QuestStep(
        id: 'ne-step-2',
        title: 'Taste the Market',
        description: 'Try local dishes at the Netanya market.',
        type: QuestStepType.activity,
        targetId: 'netanya-market-tasting',
        order: 1,
      ),
      QuestStep(
        id: 'ne-step-3',
        title: 'Catch a Sunset',
        description: 'Photograph the sunset from the Netanya promenade.',
        type: QuestStepType.activity,
        targetId: 'netanya-promenade-sunset',
        order: 2,
      ),
    ],
  ),

  // ── Beach Day ─────────────────────────────────────────────────────────────
  Quest(
    id: 'beach-day',
    title: 'Perfect Beach Day',
    description: 'Experience the ultimate beach day — surf, swim, and unwind.',
    icon: '🌊',
    rarity: QuestRarity.common,
    xpReward: 150,
    steps: [
      QuestStep(
        id: 'bd-step-1',
        title: 'Ride the Waves',
        description: 'Go surfing at the beach.',
        type: QuestStepType.activity,
        targetId: 'netanya-surf',
        order: 0,
      ),
      QuestStep(
        id: 'bd-step-2',
        title: 'Open Water Swim',
        description: 'Take an open water swim.',
        type: QuestStepType.activity,
        targetId: 'netanya-open-swim',
        order: 1,
      ),
      QuestStep(
        id: 'bd-step-3',
        title: 'Beach Yoga',
        description: 'Relax with yoga on the beach.',
        type: QuestStepType.activity,
        targetId: 'netanya-beach-yoga',
        order: 2,
      ),
    ],
  ),

  // ── Angler's Journey ──────────────────────────────────────────────────────
  Quest(
    id: 'anglers-journey',
    title: "Angler's Journey",
    description: 'Master the art of fishing — from your first catch to night fishing under the stars.',
    icon: '🎣',
    rarity: QuestRarity.rare,
    xpReward: 300,
    steps: [
      QuestStep(
        id: 'aj-step-1',
        title: 'First Catch',
        description: 'Catch your very first fish.',
        type: QuestStepType.activity,
        targetId: 'first-catch',
        order: 0,
      ),
      QuestStep(
        id: 'aj-step-2',
        title: 'Shore Fishing',
        description: 'Fish from the Netanya shoreline.',
        type: QuestStepType.activity,
        targetId: 'netanya-shore-fishing',
        order: 1,
      ),
      QuestStep(
        id: 'aj-step-3',
        title: 'Lake Fishing',
        description: 'Fish at a lake or reservoir.',
        type: QuestStepType.activity,
        targetId: 'lake-fishing',
        order: 2,
      ),
      QuestStep(
        id: 'aj-step-4',
        title: 'Night Fishing',
        description: 'Go fishing after sunset.',
        type: QuestStepType.activity,
        targetId: 'night-fishing',
        order: 3,
      ),
    ],
  ),

  // ── Culture Seeker ────────────────────────────────────────────────────────
  Quest(
    id: 'culture-seeker',
    title: 'Culture Seeker',
    description: 'Immerse yourself in local culture — from museums to historic sites.',
    icon: '🏛️',
    rarity: QuestRarity.rare,
    xpReward: 250,
    steps: [
      QuestStep(
        id: 'cs-step-1',
        title: 'Visit a Museum',
        description: 'Explore a local museum.',
        type: QuestStepType.activity,
        targetId: 'netanya-museum',
        order: 0,
      ),
      QuestStep(
        id: 'cs-step-2',
        title: 'Historic Fortress',
        description: 'Visit the Crusader fortress ruins.',
        type: QuestStepType.activity,
        targetId: 'netanya-crusader-fort',
        order: 1,
      ),
      QuestStep(
        id: 'cs-step-3',
        title: 'Local Festival',
        description: 'Attend a local cultural festival.',
        type: QuestStepType.activity,
        targetId: 'cultural-festival',
        order: 2,
      ),
    ],
  ),

  // ── Adrenaline Rush ───────────────────────────────────────────────────────
  Quest(
    id: 'adrenaline-rush',
    title: 'Adrenaline Rush',
    description: 'Push your limits with the most extreme activities available.',
    icon: '⚡',
    rarity: QuestRarity.epic,
    xpReward: 500,
    steps: [
      QuestStep(
        id: 'ar-step-1',
        title: 'Rock Climbing',
        description: 'Scale a rock wall or natural cliff face.',
        type: QuestStepType.activity,
        targetId: 'rock-climbing',
        order: 0,
      ),
      QuestStep(
        id: 'ar-step-2',
        title: 'Skydiving',
        description: 'Jump from a plane — tandem or solo.',
        type: QuestStepType.activity,
        targetId: 'tandem-skydive',
        order: 1,
      ),
      QuestStep(
        id: 'ar-step-3',
        title: 'Paragliding',
        description: 'Soar above the landscape.',
        type: QuestStepType.activity,
        targetId: 'paragliding-flight',
        order: 2,
      ),
    ],
  ),
];
