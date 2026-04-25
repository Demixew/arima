class GamificationBadge {
  const GamificationBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
  });

  final String id;
  final String title;
  final String description;
  final String icon;
  final String accentColor;

  factory GamificationBadge.fromJson(Map<String, dynamic> json) {
    return GamificationBadge(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? 'stars',
      accentColor: json['accent_color'] as String? ?? '#F59E0B',
    );
  }
}

class DailyChallenge {
  const DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.current,
    required this.target,
    required this.rewardXp,
    required this.completed,
  });

  final String id;
  final String title;
  final String description;
  final int current;
  final int target;
  final int rewardXp;
  final bool completed;

  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    return DailyChallenge(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      current: json['current'] as int? ?? 0,
      target: json['target'] as int? ?? 0,
      rewardXp: json['reward_xp'] as int? ?? 0,
      completed: json['completed'] as bool? ?? false,
    );
  }
}

class GamificationProfile {
  const GamificationProfile({
    required this.totalXp,
    required this.level,
    required this.rankTitle,
    required this.currentLevelXp,
    required this.nextLevelXp,
    required this.progressPercent,
    required this.energy,
    required this.unlockedBadges,
    required this.dailyChallenges,
    this.nextUnlockHint,
  });

  final int totalXp;
  final int level;
  final String rankTitle;
  final int currentLevelXp;
  final int nextLevelXp;
  final int progressPercent;
  final int energy;
  final String? nextUnlockHint;
  final List<GamificationBadge> unlockedBadges;
  final List<DailyChallenge> dailyChallenges;

  factory GamificationProfile.fromJson(Map<String, dynamic> json) {
    return GamificationProfile(
      totalXp: json['total_xp'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      rankTitle: json['rank_title'] as String? ?? '',
      currentLevelXp: json['current_level_xp'] as int? ?? 0,
      nextLevelXp: json['next_level_xp'] as int? ?? 1,
      progressPercent: json['progress_percent'] as int? ?? 0,
      energy: json['energy'] as int? ?? 0,
      nextUnlockHint: json['next_unlock_hint'] as String?,
      unlockedBadges: (json['unlocked_badges'] as List<dynamic>? ?? [])
          .map((dynamic item) => GamificationBadge.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(),
      dailyChallenges: (json['daily_challenges'] as List<dynamic>? ?? [])
          .map((dynamic item) => DailyChallenge.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(),
    );
  }
}
