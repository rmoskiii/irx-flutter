/// Player-facing framing shown before a scenario begins.
///
/// Deliberately authored client-side for now (see scenario_intros.dart) —
/// the backend's publicNode/getRootView contract strips `premise`,
/// `estimatedMinutes` and `cast`, and intro copy is a different register
/// from a spec-doc premise line anyway.
///
/// [fromJson] exists so that moving this server-side later is a change of
/// data source, not a rewrite: add the fields to getRootView, parse them
/// in Scenario.fromJson, and delete the content map.
library;

class ScenarioIntro {
  /// Small caps label above the title, e.g. "DIGITAL DISTRICT".
  final String eyebrow;

  final String title;

  /// Two or three sentences. Situation only — where you are, who's
  /// involved, what just happened. NEVER the skill under test. If this
  /// text hints at the correct behaviour, the scenario is dead.
  final String situation;

  /// One line placing the player in the world.
  final String youAre;

  /// Display string, e.g. "~11 minutes".
  final String duration;

  /// Rules of play, not hints. Feedback timing, span of time, whether a
  /// correct answer exists. Things a player is entitled to know before
  /// they start and currently has no way to learn.
  final List<String> rules;

  const ScenarioIntro({
    required this.eyebrow,
    required this.title,
    required this.situation,
    required this.youAre,
    required this.duration,
    this.rules = const [],
  });

  factory ScenarioIntro.fromJson(Map<String, dynamic> json) {
    return ScenarioIntro(
      eyebrow: json['eyebrow'] as String? ?? '',
      title: json['title'] as String? ?? '',
      situation: json['situation'] as String? ?? '',
      youAre: json['youAre'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      rules: (json['rules'] as List?)?.map((r) => r as String).toList() ??
          const [],
    );
  }
}