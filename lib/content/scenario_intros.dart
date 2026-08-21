import '../models/scenario_intro.dart';

/// Client-side intro copy, keyed by scenario id.
///
/// AUTHORING RULE: situation, never skill. The Prince must not mention
/// verification. The Instruction must not mention documentation. The
/// Secret must not mention loyalty. Each of those is the thing being
/// measured, and naming it in the intro hands the player the answer
/// before the first node renders.
///
/// A missing entry is not an error — forScenario returns null and the
/// intro is skipped entirely, so the dev scenario picker can load
/// anything on disk without needing copy written for it first.
class ScenarioIntros {
  ScenarioIntros._();

  static const _intros = <String, ScenarioIntro>{
    'the_prince': ScenarioIntro(
      eyebrow: 'DIGITAL DISTRICT',
      title: 'The Prince',
      situation:
          'An email arrives from a probate research firm in Liverpool. They '
          'say they trace entitled next of kin in unclaimed estate cases, '
          'that their research points through your maternal line, and that '
          'the estate is valued at around £312,000.\n\n'
          'They would like you to confirm the address is yours.',
      youAre: 'You are the person the email was sent to. Nothing more than that.',
      duration: '~11 minutes',
      rules: [
        'This plays out over about three weeks. What you do early decides '
            'what is available to you later.',
        'Not every approach like this one is a con.',
        'Your score is hidden until the end.',
      ],
    ),
    'the_secret': ScenarioIntro(
      eyebrow: 'NEIGHBOURHOOD DISTRICT',
      title: 'The Secret',
      situation:
          'Jessica has been your closest friend since your first week at '
          'university. Alex, her partner of four years, was your friend '
          'first — you introduced them.\n\n'
          'It is late on a Saturday. Everyone else has drifted home. Jessica '
          'has been quieter than usual, and she has been waiting for the '
          'room to empty.',
      youAre: 'You are the friend both of them trust.',
      duration: '~9 minutes',
      rules: [
        'There is no correct answer. Every option is defensible.',
        'The story runs on for months. People remember what you did.',
        'Your score is hidden until the end.',
      ],
    ),
    'the_instruction': ScenarioIntro(
      eyebrow: 'CAREER DISTRICT',
      title: 'The Instruction',
      situation:
          'You are an analyst at a consultancy. Six weeks ago your manager, '
          'Ray, quietly fixed a mistake of yours late one evening and never '
          'mentioned it again.\n\n'
          'Tonight the Northstar readiness report is finished. The findings '
          'are good. It is two days later than the date it was due, and Ray '
          'is standing at the end of your desk with their coat already on.',
      youAre:
          'You are the junior on the file. Ray decides what work you are '
          'offered next.',
      duration: '~10 minutes',
      rules: [
        'This runs from April to September. Some things only matter later.',
        'Your score is hidden until the end.',
      ],
    ),
  };

  /// Null when no intro has been authored for [scenarioId] — callers skip
  /// the modal rather than showing an empty one.
  static ScenarioIntro? forScenario(String scenarioId) => _intros[scenarioId];
}