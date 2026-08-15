/// Models mirror the shape returned by the irl-backend API. Keeping them
/// as plain, explicit fromJson factories (no codegen) keeps the project
/// dependency-light and easy to read for a small MVP.
library;

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

/// Tells the client how to render a node beyond the default chat bubble.
/// [type] picks the widget (e.g. "document"); [data] is type-specific and
/// deliberately left as a raw map so new types don't need a model change
/// here - only a new case in the widget that renders them. [modal] flags
/// beats dramatic enough to interrupt the screen rather than sit inline.
class ScenarioPresentation {
  final String type;
  final bool modal;
  final Map<String, dynamic> data;

  const ScenarioPresentation({
    required this.type,
    required this.modal,
    required this.data,
  });

  factory ScenarioPresentation.fromJson(Map<String, dynamic> json) {
    return ScenarioPresentation(
      type: json['type'] as String,
      modal: json['modal'] as bool? ?? false,
      data: (json['data'] as Map<String, dynamic>?) ?? const {},
    );
  }
}

/// One entry in a "messages" thread. Either a bubble ([from] + [text]) or
/// a line of prose narration ([narration]). Never both — presence of
/// [from] is what makes it a bubble.
class ThreadSegment {
  final String? from;
  final String? text;
  final String? narration;

  const ThreadSegment({this.from, this.text, this.narration});

  bool get isBubble => from != null;

  factory ThreadSegment.fromJson(Map<String, dynamic> json) {
    return ThreadSegment(
      from: json['from'] as String?,
      text: json['text'] as String?,
      narration: json['narration'] as String?,
    );
  }
}

class ScenarioInterstitial {
  final String label;
  final Duration duration;

  const ScenarioInterstitial({
    required this.label,
    required this.duration,
  });

  factory ScenarioInterstitial.fromJson(Map<String, dynamic> json) {
    return ScenarioInterstitial(
      label: json['label'] as String? ?? '',
      duration:
          Duration(milliseconds: (json['durationMs'] as num?)?.toInt() ?? 2000),
    );
  }
}

/// A single point in the conversation: the persona's message plus the
/// choices available in response to it. Both /today and mid-conversation
/// /respond calls return one of these, so the client always renders the
/// same shape regardless of how deep into a scenario it is. [presentation]
/// is null for an ordinary chat beat.
class ScenarioNode {
  final String nodeId;
  final String? message;
  final List<ThreadSegment>? thread;
  final ScenarioPresentation? presentation;
  final List<ScenarioChoice> choices;
  final String? reactionDelay;
  final ScenarioInterstitial? interstitial;

  const ScenarioNode({
    required this.nodeId,
    required this.choices,
    this.message,
    this.thread,
    this.presentation,
    this.reactionDelay,
    this.interstitial,
  });

  factory ScenarioNode.fromJson(Map<String, dynamic> json) {
    return ScenarioNode(
      nodeId: json['nodeId'] as String,
      message: json['message'] as String?,
      thread: (json['thread'] as List?)
          ?.map((s) => ThreadSegment.fromJson(s as Map<String, dynamic>))
          .toList(),
      reactionDelay: json['reactionDelay'] as String?,
      interstitial: json['interstitial'] != null
          ? ScenarioInterstitial.fromJson(
              json['interstitial'] as Map<String, dynamic>)
          : null,
      presentation: json['presentation'] != null
          ? ScenarioPresentation.fromJson(
              json['presentation'] as Map<String, dynamic>)
          : null,
      choices: (json['choices'] as List)
          .map((c) => ScenarioChoice.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Root response from GET /api/scenarios/today - scenario metadata plus
/// the starting node.
class Scenario {
  final String scenarioId;
  final String title;
  final String district;
  final int difficulty;
  final Persona persona;
  final Map<String, dynamic> state;
  final ScenarioNode node;

  const Scenario({
    required this.scenarioId,
    required this.title,
    required this.district,
    required this.difficulty,
    required this.persona,
    required this.state,
    required this.node,
  });

  factory Scenario.fromJson(Map<String, dynamic> json) {
    return Scenario(
      scenarioId: json['scenarioId'] as String,
      title: json['title'] as String,
      district: json['district'] as String,
      difficulty: json['difficulty'] as int,
      persona: Persona.fromJson(json['persona'] as Map<String, dynamic>),
      state: Map<String, dynamic>.from((json['state'] as Map?) ?? const {}),
      node: ScenarioNode.fromJson(json['node'] as Map<String, dynamic>),
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
    this.savvy = 0,
    this.streetSmarts = 0,
    this.integrity = 0,
  });

  factory StatDelta.fromJson(Map<String, dynamic> json) {
    return StatDelta(
      savvy: json['savvy'] as int,
      streetSmarts: json['streetSmarts'] as int,
      integrity: json['integrity'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'savvy': savvy,
        'streetSmarts': streetSmarts,
        'integrity': integrity,
      };

  StatDelta operator +(StatDelta other) {
    return StatDelta(
      savvy: savvy + other.savvy,
      streetSmarts: streetSmarts + other.streetSmarts,
      integrity: integrity + other.integrity,
    );
  }

  int get total => savvy + streetSmarts + integrity;
}

/// Response from POST /api/scenarios/respond for a single turn. Either
/// [node] is set (conversation continues) or [terminal] is true and
/// [consequence]/[outcomeExplanation] are set (scenario is over).
/// [reasons] is keyed by stat name and only contains entries for stats
/// that actually moved on this turn - the "why" behind [scores].
class TurnResult {
  final StatDelta scores;
  final Map<String, String> reasons;
  final bool terminal;
  final String? beat;
  final Map<String, dynamic>? state;
  final ScenarioNode? node;
  final String? consequence;
  final String? outcomeExplanation;
  final String? landing;

  /// Present on reflection-mode scenarios (The Secret) instead of
  /// [outcomeExplanation]. Pattern-matched prose describing the shape of
  /// what the player did — not a graded score. When these are non-null,
  /// the outcome screen must not render a ring or a numeric headline.
  final String? reflectionTitle;
  final String? reflectionText;

  const TurnResult({
    required this.scores,
    required this.reasons,
    required this.terminal,
    this.beat,
    this.state,
    this.node,
    this.consequence,
    this.outcomeExplanation,
    this.landing,
    this.reflectionTitle,
    this.reflectionText,
  });

  factory TurnResult.fromJson(Map<String, dynamic> json) {
    return TurnResult(
      scores: StatDelta.fromJson(json['scores'] as Map<String, dynamic>),
      reasons: (json['reasons'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as String),
          ) ??
          const {},
      terminal: json['terminal'] as bool,
      beat: json['beat'] as String?,
      state: json['state'] != null
          ? Map<String, dynamic>.from(json['state'] as Map)
          : null,
      node: json['node'] != null
          ? ScenarioNode.fromJson(json['node'] as Map<String, dynamic>)
          : null,
      consequence: json['consequence'] as String?,
      outcomeExplanation: json['outcomeExplanation'] as String?,
      landing: json['landing'] as String?,
      reflectionTitle: json['reflectionTitle'] as String?,
      reflectionText: json['reflectionText'] as String?,
    );
  }
}

/// A completed turn, kept client-side across a playthrough so the outcome
/// screen can show a full "how we got here" ledger, not just final totals.
class TurnBreakdown {
  final String choiceLabel;
  final StatDelta scores;
  final Map<String, String> reasons;

  const TurnBreakdown({
    required this.choiceLabel,
    required this.scores,
    required this.reasons,
  });
}

/// Summary of a scenario, as returned by GET /api/scenarios/list. Powers
/// the dev-only scenario picker - deliberately minimal, just enough to
/// show a list and let you pick one.
class ScenarioSummary {
  final String id;
  final String title;
  final String district;
  final int difficulty;

  const ScenarioSummary({
    required this.id,
    required this.title,
    required this.district,
    required this.difficulty,
  });

  factory ScenarioSummary.fromJson(Map<String, dynamic> json) {
    return ScenarioSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      district: json['district'] as String,
      difficulty: json['difficulty'] as int,
    );
  }
}
