class WeeklyNarrative {
  const WeeklyNarrative({
    required this.headline,
    required this.summary,
    this.nextFocus,
  });

  final String headline;
  final String summary;
  final String? nextFocus;

  factory WeeklyNarrative.fromJson(Map<String, dynamic> json) {
    return WeeklyNarrative(
      headline: json['headline'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      nextFocus: json['next_focus'] as String?,
    );
  }
}
