/// Player-facing identity for the people in The Streets.
///
/// Separate from the scenario's own `cast` block on purpose. Those role strings
/// are authorial shorthand — Kai's is "Friction", Dee's is "Older, generous,
/// genuinely good company" — and putting them in front of a player would tell
/// them how to read a man whose entire function is that you like him and he
/// needs something. The scenario trains the judgment of who to trust; the
/// chrome must not pre-empt it.
///
/// So the rule for every line here: it may establish a name, a relationship and
/// shared history that the authored prose already states. It may not say
/// whether someone is trustworthy, good, bad, or what the player should make of
/// them. Each line below is traceable to a passage, noted beside it.
///
/// Lives client-side because it is presentation, needs no server round trip and
/// no redeploy to change. If it ever needs to vary per run it belongs in the
/// scenario's cast block instead, which is a backend change.
class CastMember {
  const CastMember({
    required this.name,
    required this.tag,
    required this.intro,
  });

  /// Exactly as the node reports it in presentation.data.character.name.
  final String name;

  /// The persistent line under the name in the panel header. Short enough to
  /// sit on one line at 390pt.
  final String tag;

  /// The one-off lower-third, shown the first time this person carries a beat.
  final String intro;
}

class CastCopy {
  const CastCopy._();

  static const Map<String, CastMember> _theStreets = {
    'Bola': CastMember(
      name: 'Bola',
      tag: 'Your mum',
      // s1d1_open: "doing the thing she does before a shift", "doing sums in
      // her head while talking about something else"
      intro: 'Your mum. You live with her. She works shifts, and she does the '
          'sums in her head.',
    ),
    'Jay': CastMember(
      name: 'Jay',
      tag: 'Your oldest friend',
      // s1d1_walkway: "Jay's flat is where you ate for a stretch when things
      // were bad, and neither of you has ever said a word about it."
      intro: "Your oldest friend. You ate at his flat for a stretch when "
          "things were bad, and neither of you mentions it.",
    ),
    'Tunde': CastMember(
      name: 'Tunde',
      tag: 'A friend',
      // s1d1_cage: "training for something specific and doesn't make a thing
      // of it", "asks you a direct question about what you're actually doing"
      intro: "A friend. He's training for something specific, and he asks you "
          "straight questions about yourself.",
    ),
    'Kai': CastMember(
      name: 'Kai',
      tag: 'From the estate',
      // Deliberately the neutral version: the authored history (s1d3_stop)
      // includes the player laughing at a previous stop, which is a judgment
      // about the player and is left for the scene itself to deliver.
      intro: "From the estate. You've known each other for years.",
    ),
    'Dee': CastMember(
      name: 'Dee',
      tag: 'Older, from around here',
      // s1d3_dee: "Two summers ago Dee got you a fortnight's work when you
      // needed it, paid you on the Friday like he said he would, and drove you
      // home the night the buses stopped."
      intro: 'Older, from around here. Two summers ago he found you a '
          "fortnight's work and drove you home when the buses stopped.",
    ),
    'Amara': CastMember(
      name: 'Amara',
      tag: 'Your girlfriend... kinda',
      // Placeholder, and knowingly so: the authored material establishes only
      // that she texts when you go quiet and that you have not answered. The
      // relationship itself has not been written yet, and this line stands in
      // until it is.
      intro: 'Amara. Your girlfriend... kinda',
    ),
  };

  /// The copy for a character, or null — which is the normal answer for a
  /// scenario with no cast copy, for a node with no character, and for a name
  /// nobody has written a line for yet. Null always means "show nothing":
  /// there is deliberately no fallback to the internal role string.
  static CastMember? lookup(String? scenarioId, String? name) {
    if (scenarioId != 'the_streets') return null;
    final key = name?.trim();
    if (key == null || key.isEmpty) return null;
    return _theStreets[key];
  }
}