enum QuestStepType { activity, achievement }

enum QuestRarity { common, rare, epic, legendary }

class QuestStep {
  final String id;
  final String title;
  final String description;
  final QuestStepType type;

  /// References a SideQuest id (activity) or Achievement id.
  final String targetId;

  /// Order within the quest (0-based).
  final int order;

  /// Whether this step is done.
  final bool isCompleted;

  const QuestStep({
    required this.id,
    required this.title,
    this.description = '',
    required this.type,
    required this.targetId,
    required this.order,
    this.isCompleted = false,
  });

  QuestStep copyWith({bool? isCompleted}) {
    return QuestStep(
      id: id,
      title: title,
      description: description,
      type: type,
      targetId: targetId,
      order: order,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'targetId': targetId,
        'order': order,
        'isCompleted': isCompleted,
      };

  static QuestStep fromJson(Map<String, dynamic> json, QuestStep base) {
    return base.copyWith(
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}

class Quest {
  final String id;
  final String title;
  final String description;
  final String icon; // emoji
  final QuestRarity rarity;
  final int xpReward;
  final List<QuestStep> steps;

  /// Whether all steps are completed.
  final bool isCompleted;
  final DateTime? completedAt;

  /// Whether the user has claimed the completion reward.
  final bool isClaimed;

  /// Whether the user has started (at least one step done).
  final bool isStarted;

  const Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.rarity,
    required this.xpReward,
    required this.steps,
    this.isCompleted = false,
    this.completedAt,
    this.isClaimed = false,
    this.isStarted = false,
  });

  int get completedStepCount => steps.where((s) => s.isCompleted).length;
  int get totalSteps => steps.length;
  double get progress => totalSteps > 0 ? completedStepCount / totalSteps : 0;

  /// The next uncompleted step (null if all done).
  QuestStep? get currentStep =>
      steps.where((s) => !s.isCompleted).firstOrNull;

  /// Whether the quest is completed but not yet claimed.
  bool get isClaimable => isCompleted && !isClaimed;

  Quest copyWith({
    List<QuestStep>? steps,
    bool? isCompleted,
    DateTime? completedAt,
    bool? isClaimed,
    bool? isStarted,
  }) {
    return Quest(
      id: id,
      title: title,
      description: description,
      icon: icon,
      rarity: rarity,
      xpReward: xpReward,
      steps: steps ?? this.steps,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      isClaimed: isClaimed ?? this.isClaimed,
      isStarted: isStarted ?? this.isStarted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'isCompleted': isCompleted,
        'completedAt': completedAt?.toIso8601String(),
        'isClaimed': isClaimed,
        'isStarted': isStarted,
        'steps': {for (final s in steps) s.id: s.toJson()},
      };
}
