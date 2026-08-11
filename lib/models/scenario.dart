/// Models mirror the shape returned by the irl-backend API. Keeping them
/// as plain, explicit fromJson factories (no codegen) keeps the project
/// dependency-light and easy to read for a small MVP.

class Persona {
  final String name;
  final String role;

  const Persona({required this.name, required this.role});

  factory Persona.fromJson(Map<String, dynamic> json) {
    return Persona(
      name: json['name'] as String,
      role: json['role'] as String,
    );
  }
}

class ScenarioChoice {
  final String id;
  final String label;

  const ScenarioChoice({required this.id, required this.label});

  factory ScenarioChoice.fromJson(Map<String, dynamic> json) {
    return ScenarioChoice(
      id: json['id'] as String,
      label: json['label'] as String,
    );
  }
}

class Scenario {
  final String id;
  final String title;
  final String district;
  final int difficulty;
  final Persona persona;
  final String opening;
  final List<ScenarioChoice> choices;

  const Scenario({
    required this.id,
    required this.title,
    required this.district,
    required this.difficulty,
    required this.persona,
    required this.opening,
    required this.choices,
  });

  factory Scenario.fromJson(Map<String, dynamic> json) {
    return Scenario(
      id: json['id'] as String,
      title: json['title'] as String,
      district: json['district'] as String,
      difficulty: json['difficulty'] as int,
      persona: Persona.fromJson(json['persona'] as Map<String, dynamic>),
      opening: json['opening'] as String,
      choices: (json['choices'] as List)
          .map((c) => ScenarioChoice.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// The three core judgment stats. Kept as a small typed class rather than
/// a raw map so call sites get autocomplete instead of magic strings.
class StatDelta {
  final int savvy;
  final int streetSmarts;
  final int integrity;

  const StatDelta({
    required this.savvy,
    required this.streetSmarts,
    required this.integrity,
  });

  factory StatDelta.fromJson(Map<String, dynamic> json) {
    return StatDelta(
      savvy: json['savvy'] as int,
      streetSmarts: json['streetSmarts'] as int,
      integrity: json['integrity'] as int,
    );
  }

  int get total => savvy + streetSmarts + integrity;
}

class ScenarioResult {
  final String reaction;
  final StatDelta scores;
  final String outcomeExplanation;

  const ScenarioResult({
    required this.reaction,
    required this.scores,
    required this.outcomeExplanation,
  });

  factory ScenarioResult.fromJson(Map<String, dynamic> json) {
    return ScenarioResult(
      reaction: json['reaction'] as String,
      scores: StatDelta.fromJson(json['scores'] as Map<String, dynamic>),
      outcomeExplanation: json['outcomeExplanation'] as String,
    );
  }
}
