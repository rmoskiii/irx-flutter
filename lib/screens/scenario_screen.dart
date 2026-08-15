import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/scenario.dart';
import '../services/api_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/district_theme.dart';
import '../widgets/call_modal.dart';
import '../widgets/choice_tile.dart';
import '../widgets/document_modal.dart';
import '../widgets/email_card.dart';
import '../widgets/interstitial_overlay.dart';
import '../widgets/messages_card.dart';
import '../widgets/payment_request_modal.dart';
import '../widgets/persona_bubble.dart';
import '../widgets/player_bubble.dart';
import '../widgets/scene_card.dart';
import '../widgets/scene_modal.dart';
import '../widgets/score_feedback.dart';
import '../widgets/sms_card.dart';
import '../widgets/typing_indicator.dart';
import 'outcome_screen.dart';

/// Reaction delay durations keyed by the string value in the scenario
/// JSON. Absent or unrecognised = instant (no delay).
const _reactionDelays = {
  'short': Duration(milliseconds: 800),
  'medium': Duration(milliseconds: 1500),
  'long': Duration(milliseconds: 2500),
};

const _choiceStaggerDelay = Duration(milliseconds: 95);
const _choiceCommitDelay = Duration(milliseconds: 140);
const _defaultInlineRevealDuration = Duration(milliseconds: 280);

/// How long a `beat` lingers on screen before the next persona message
/// arrives. Short enough not to stall; long enough to read as a distinct
/// narrative beat and not as a caption on what follows.
const _beatHoldDuration = Duration(milliseconds: 900);

/// One entry in the on-screen transcript. A persona entry carries either
/// [text] (chat/scene/email/sms) OR [thread] (messages) — never both.
class _TranscriptEntry {
  final _EntryKind kind;
  final String text;
  final List<ThreadSegment>? thread;
  final bool showHeader;
  final ScenarioPresentation? presentation;
  final StatDelta? scores;
  final Map<String, String>? reasons;

  const _TranscriptEntry.persona(
    this.text, {
    this.showHeader = false,
    this.presentation,
    this.thread,
  })  : kind = _EntryKind.persona,
        scores = null,
        reasons = null;

  const _TranscriptEntry.player(this.text)
      : kind = _EntryKind.player,
        thread = null,
        showHeader = false,
        presentation = null,
        scores = null,
        reasons = null;

  const _TranscriptEntry.feedback(this.scores, this.reasons)
      : kind = _EntryKind.feedback,
        text = '',
        thread = null,
        showHeader = false,
        presentation = null;

  const _TranscriptEntry.beat(this.text)
      : kind = _EntryKind.beat,
        thread = null,
        showHeader = false,
        presentation = null,
        scores = null,
        reasons = null;
}

enum _EntryKind { persona, player, feedback, beat }

enum _NodePresentationState {
  revealing,
  waitingForChoice,
  submitting,
  transitioning
}

class ScenarioScreen extends StatefulWidget {
  final DistrictTheme district;
  final String? scenarioIdOverride;

  const ScenarioScreen(
      {super.key, required this.district, this.scenarioIdOverride});

  @override
  State<ScenarioScreen> createState() => _ScenarioScreenState();
}

class _ScenarioScreenState extends State<ScenarioScreen> {
  final ApiService _api = ApiService();
  final ScrollController _scrollController = ScrollController();

  late Future<Scenario> _scenarioFuture;
  Scenario? _scenario;

  final List<_TranscriptEntry> _transcript = [];
  final List<TurnBreakdown> _breakdown = [];
  final List<String> _visitedLocations = [];
  List<ScenarioChoice> _currentChoices = [];
  String _currentNodeId = '';
  StatDelta _runningTotal = const StatDelta();

  /// Opaque scenario state — initialised by the backend from stateSchema,
  /// updated on every /respond, sent back verbatim on the next turn. The
  /// client NEVER reads a key out of this map, so variant/routing logic
  /// on the backend can't desync from the renderer.
  Map<String, dynamic> _scenarioState = const {};

  _NodePresentationState _presentationState = _NodePresentationState.revealing;
  bool _showTyping = false;
  String? _selectedChoiceId;
  int _revealToken = 0;

  bool get _isNeighborhood => widget.district.id == 'neighborhood';
  bool get _choiceInputLocked =>
      _presentationState != _NodePresentationState.waitingForChoice;

  @override
  void initState() {
    super.initState();
    _scenarioFuture = _api
        .fetchTodayScenario(scenarioId: widget.scenarioIdOverride)
        .then((scenario) {
      setState(() {
        _scenario = scenario;
        _currentNodeId = scenario.node.nodeId;
        _scenarioState = scenario.state;
        _presentationState = _NodePresentationState.revealing;
        if (!_isModalNode(scenario.node)) {
          _transcript.add(_TranscriptEntry.persona(
            scenario.node.message ?? '',
            showHeader: true,
            presentation: scenario.node.presentation,
            thread: scenario.node.thread,
          ));
        }
        _trackLocation(scenario.node);
      });
      _revealNode(scenario.node);
      return scenario;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _trackLocation(ScenarioNode node) {
    final location = node.presentation?.data['location'] as String?;
    if (location != null && location.isNotEmpty) {
      if (_visitedLocations.isEmpty || _visitedLocations.last != location) {
        _visitedLocations.add(location);
      }
    }
  }

  bool _isModalNode(ScenarioNode node) => node.presentation?.modal ?? false;

  Duration _inlineRevealDurationFor(ScenarioNode node) {
    if (node.presentation?.type == 'scene') return SceneCard.revealDuration;
    return _defaultInlineRevealDuration;
  }

  Future<void> _revealChoices(List<ScenarioChoice> choices, int token) async {
    if (!mounted || token != _revealToken) return;
    setState(() {
      _currentChoices = [];
      _selectedChoiceId = null;
      _presentationState = _NodePresentationState.waitingForChoice;
    });

    for (final choice in choices) {
      await Future.delayed(_choiceStaggerDelay);
      if (!mounted ||
          token != _revealToken ||
          _presentationState != _NodePresentationState.waitingForChoice) {
        return;
      }
      setState(() => _currentChoices = [..._currentChoices, choice]);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }

  /// Waits for the node's reaction delay (if any) while showing a typing
  /// indicator. Only fires for Neighbourhood-style scenarios — Digital
  /// scenarios skip this entirely since their pacing is meant to feel
  /// immediate/functional, not conversational.
  Future<void> _waitForReaction(ScenarioNode node) async {
    if (!_isNeighborhood) return;
    // An interstitial is already a pause. Running both back-to-back gives
    // 4.5s of blank screen on exactly the beats that matter most.
    if (node.interstitial != null) return;
    final delay = _reactionDelays[node.reactionDelay];
    if (delay == null) return;
    setState(() => _showTyping = true);
    _scrollToBottom();
    await Future.delayed(delay);
    if (mounted) setState(() => _showTyping = false);
  }

  Future<void> _revealNode(ScenarioNode node, {int? token}) async {
    final revealToken = token ?? ++_revealToken;
    if (revealToken != _revealToken) return;
    final presentation = node.presentation;
    setState(() {
      _presentationState = _NodePresentationState.revealing;
      _currentChoices = [];
      _selectedChoiceId = null;
    });

    if (presentation != null && presentation.modal) {
      switch (presentation.type) {
        case 'document':
          await showDocumentModal(context,
              district: widget.district, data: presentation.data);
          break;
        case 'payment_request':
          final selected = await showPaymentRequestModal(
            context,
            district: widget.district,
            data: presentation.data,
            choices: node.choices,
          );
          if (!mounted || selected == null) return;
          await _selectChoice(selected, fromModal: true);
          return;
        case 'call':
          final selectedCall = await showCallModal(
            context,
            district: widget.district,
            data: presentation.data,
            message: node.message ?? '',
            choices: node.choices,
          );
          if (!mounted || selectedCall == null) return;
          await _selectChoice(selectedCall, fromModal: true);
          return;
        case 'scene':
          final selectedScene = await showSceneModal(
            context,
            district: widget.district,
            data: presentation.data,
            message: node.message ?? '',
            choices: node.choices,
          );
          if (!mounted || selectedScene == null) return;
          await _selectChoice(selectedScene, fromModal: true);
          return;
        case 'messages':
          final selectedThread = await showMessagesModal(
            context,
            district: widget.district,
            data: presentation.data,
            thread: node.thread ?? const [],
            choices: node.choices,
          );
          if (!mounted || selectedThread == null) return;
          await _selectChoice(selectedThread, fromModal: true);
          return;
      }
    }

    if (!mounted) return;
    await Future.delayed(_inlineRevealDurationFor(node));
    await _revealChoices(node.choices, revealToken);
  }

  Future<void> _selectChoice(ScenarioChoice choice,
      {bool fromModal = false}) async {
    if (_scenario == null ||
        _presentationState == _NodePresentationState.submitting ||
        _presentationState == _NodePresentationState.transitioning ||
        (!fromModal &&
            _presentationState != _NodePresentationState.waitingForChoice)) {
      return;
    }
    final choicesAtSelection = List<ScenarioChoice>.from(_currentChoices);
    setState(() {
      _presentationState = _NodePresentationState.submitting;
      _selectedChoiceId = choice.id;
    });
    await Future.delayed(_choiceCommitDelay);
    if (!mounted) return;
    setState(() {
      _transcript.add(_TranscriptEntry.player(choice.label));
      _currentChoices = [];
      _selectedChoiceId = null;
    });
    _scrollToBottom();

    try {
      final result = await _api.submitChoice(
        scenarioId: _scenario!.scenarioId,
        nodeId: _currentNodeId,
        choiceId: choice.id,
        runningTotal: _runningTotal,
        state: _scenarioState,
      );

      if (!mounted) return;

      // Opaque courier — whatever the backend hands back is what we send
      // next turn. The client never inspects this map.
      _scenarioState = result.state ?? _scenarioState;

      context.read<AppState>().applyResult(result.scores);
      _runningTotal = _runningTotal + result.scores;
      _breakdown.add(TurnBreakdown(
        choiceLabel: choice.label,
        scores: result.scores,
        reasons: result.reasons,
      ));

      // Digital shows reasoning immediately; Neighbourhood hides it.
      if (!_isNeighborhood) {
        setState(() {
          _transcript
              .add(_TranscriptEntry.feedback(result.scores, result.reasons));
        });
        _scrollToBottom();
      }

      // Beat — the immediate ripple of the choice just made. Rendered as
      // narration between the player's reply and the next character's
      // message. Never merged into the next node's message (it would
      // inherit SceneCard styling and read as spoken dialogue).
      if (result.beat != null && result.beat!.isNotEmpty) {
        setState(() => _transcript.add(_TranscriptEntry.beat(result.beat!)));
        _scrollToBottom();
        await Future.delayed(_beatHoldDuration);
        if (!mounted) return;
      }

      if (result.terminal) {
        // Landing beat — a final cinematic moment between the last
        // decision and the outcome screen. The scene breathes before the
        // numbers arrive. Only shows if the terminal choice carries one.
        if (result.landing != null && result.landing!.isNotEmpty && mounted) {
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            barrierColor: Colors.black.withValues(alpha: 0.85),
            builder: (_) => _LandingScene(
              district: widget.district,
              text: result.landing!,
            ),
          );
        }

        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OutcomeScreen(
              district: widget.district,
              scenarioId: _scenario!.scenarioId,
              totalScores: _runningTotal,
              consequence: result.consequence ?? '',
              outcomeExplanation: result.outcomeExplanation ?? '',
              breakdown: List.unmodifiable(_breakdown),
            ),
          ),
        );
        return;
      }

      final nextNode = result.node!;
      setState(() => _presentationState = _NodePresentationState.transitioning);

      // Claim the reveal token BEFORE the interstitial so a back-nav
      // during the hold can't render a card for an abandoned node.
      final token = ++_revealToken;

      final interstitial = nextNode.interstitial;
      if (interstitial != null && interstitial.label.trim().isNotEmpty) {
        await showInterstitial(
          context,
          district: widget.district,
          label: interstitial.label,
          duration: interstitial.duration,
        );
        if (!mounted || token != _revealToken) return;
      }

      await _waitForReaction(nextNode);
      if (!mounted || token != _revealToken) return;

      _trackLocation(nextNode);
      setState(() {
        _currentNodeId = nextNode.nodeId;
        _presentationState = _NodePresentationState.revealing;
        if (!_isModalNode(nextNode)) {
          _transcript.add(_TranscriptEntry.persona(
            nextNode.message ?? '',
            presentation: nextNode.presentation,
            thread: nextNode.thread,
          ));
        }
      });
      _scrollToBottom();
      await _revealNode(nextNode, token: token);
      return;
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something went wrong: $error')),
      );
      setState(() {
        _presentationState = _NodePresentationState.waitingForChoice;
        _currentChoices = fromModal ? [] : choicesAtSelection;
        _selectedChoiceId = null;
      });
    } finally {
      if (mounted && _presentationState == _NodePresentationState.submitting) {
        setState(
            () => _presentationState = _NodePresentationState.waitingForChoice);
      }
    }
  }

  Widget _buildPersonaEntry(
      BuildContext context, Scenario scenario, _TranscriptEntry entry) {
    final presentation = entry.presentation;

    if (presentation != null && presentation.type == 'email') {
      final data = presentation.data;
      return EmailCard(
        district: widget.district,
        sender: data['sender'] as String? ?? scenario.persona.name,
        senderEmail: data['senderEmail'] as String? ?? '',
        subject: data['subject'] as String? ?? '',
        body: entry.text,
      );
    }

    if (presentation != null && presentation.type == 'sms') {
      final data = presentation.data;
      return SmsCard(
        district: widget.district,
        sender: data['sender'] as String? ?? scenario.persona.name,
        senderNumber: data['senderNumber'] as String? ?? '',
        body: entry.text,
      );
    }

    if (presentation != null && presentation.type == 'scene') {
      final data = presentation.data;
      final character = data['character'] as Map<String, dynamic>? ?? {};
      return SceneCard(
        district: widget.district,
        characterName: character['name'] as String? ?? scenario.persona.name,
        characterRole: character['role'] as String? ?? scenario.persona.role,
        mood: character['mood'] as String? ?? '',
        location: data['location'] as String? ?? '',
        message: entry.text,
      );
    }

    // Non-modal messages fallback. No scenario uses this today (every
    // messages node in The Secret is modal), but kept for symmetry with
    // the other presentation types.
    if (presentation != null && presentation.type == 'messages') {
      final data = presentation.data;
      final character = data['character'] as Map<String, dynamic>? ?? {};
      return MessagesCard(
        district: widget.district,
        contactName: character['name'] as String? ?? scenario.persona.name,
        contactRole: character['role'] as String? ?? scenario.persona.role,
        thread: entry.thread ?? const [],
      );
    }

    return PersonaBubble(
      district: widget.district,
      name: scenario.persona.name,
      role: scenario.persona.role,
      message: entry.text,
      showHeader: entry.showHeader,
    );
  }

  @override
  Widget build(BuildContext context) {
    final district = widget.district;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: district.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<Scenario>(
            future: _scenarioFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return Center(
                  child: CircularProgressIndicator(color: district.accent),
                );
              }
              if (snapshot.hasError) {
                return _ErrorState(
                    district: district, error: '${snapshot.error}');
              }

              final scenario = _scenario!;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: AppColors.textPrimary),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: Text(
                            scenario.title,
                            style: district.labelFont().copyWith(
                                  fontSize: 12,
                                  letterSpacing: 1.0,
                                  color: district.accent,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  if (_isNeighborhood && _visitedLocations.length > 1)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: _LocationStrip(
                        locations: _visitedLocations,
                        accent: district.accent,
                      ),
                    )
                  else
                    const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final entry in _transcript)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: switch (entry.kind) {
                                  _EntryKind.player => PlayerBubble(
                                      district: district, label: entry.text),
                                  _EntryKind.feedback => ScoreFeedback(
                                      scores: entry.scores!,
                                      reasons: entry.reasons!,
                                      district: district,
                                      compact: true,
                                    ),
                                  _EntryKind.beat =>
                                    _BeatLine(text: entry.text),
                                  _EntryKind.persona => _buildPersonaEntry(
                                      context, scenario, entry),
                                },
                              ),
                            if (_showTyping)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: TypingIndicator(district: district),
                              ),
                            if (_presentationState ==
                                    _NodePresentationState.submitting &&
                                !_showTyping)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: district.accent,
                                  ),
                                ),
                              ),
                            if (_currentChoices.isNotEmpty) ...[
                              Text(
                                'HOW DO YOU RESPOND?',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              const SizedBox(height: 12),
                              ..._currentChoices.map(
                                (choice) => TweenAnimationBuilder<double>(
                                  key: ValueKey(
                                      'choice-$_currentNodeId-${choice.id}'),
                                  tween: Tween(begin: 0, end: 1),
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, child) => Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(0, (1 - value) * 8),
                                      child: child,
                                    ),
                                  ),
                                  child: ChoiceTile(
                                    label: choice.label,
                                    district: district,
                                    disabled: _choiceInputLocked,
                                    selected: _selectedChoiceId == choice.id,
                                    onTap: () => _selectChoice(choice),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A subtle horizontal breadcrumb showing locations the player has moved
/// through — "Kitchen → Coffee shop → ???" — selling progression as a
/// journey through places rather than a numbered step counter.
class _LocationStrip extends StatelessWidget {
  final List<String> locations;
  final Color accent;

  const _LocationStrip({required this.locations, required this.accent});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < locations.length; i++) ...[
            if (i > 0) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.arrow_forward_ios_rounded,
                    size: 8, color: accent.withValues(alpha: 0.35)),
              ),
            ],
            Text(
              locations[i],
              style: TextStyle(
                fontSize: 10,
                color: i == locations.length - 1
                    ? accent
                    : accent.withValues(alpha: 0.45),
                fontWeight: i == locations.length - 1
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The ripple from a single choice — "Alex relaxes. But the question
/// hangs in the room like smoke." Sits between the player's reply and
/// whatever comes next. Styled as narration, deliberately unlike both
/// PlayerBubble and PersonaBubble so it never reads as dialogue.
class _BeatLine extends StatelessWidget {
  final String text;

  const _BeatLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(opacity: value, child: child),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            height: 1.7,
            fontStyle: FontStyle.italic,
            color: Colors.white.withValues(alpha: 0.52),
          ),
        ),
      ),
    );
  }
}

/// A final emotional beat before the outcome screen — no choices, just a
/// moment to sit with what happened. Renders as a minimal, centered text
/// card over a darkened backdrop, with a single "Continue" to dismiss.
class _LandingScene extends StatelessWidget {
  final DistrictTheme district;
  final String text;

  const _LandingScene({required this.district, required this.text});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 60),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) =>
            Opacity(opacity: value, child: child),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 15,
                      height: 1.6,
                    ),
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: district.accent.withValues(alpha: 0.7),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                ),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final DistrictTheme district;
  final String error;

  const _ErrorState({required this.district, required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, color: district.accent, size: 32),
            const SizedBox(height: 12),
            Text(
              'Couldn\'t reach the IRL backend.\n$error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Make sure the Node/Express server is running.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}