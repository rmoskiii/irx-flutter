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

/// One entry in the on-screen transcript.
class _TranscriptEntry {
  final _EntryKind kind;
  final String text;
  final bool showHeader;
  final ScenarioPresentation? presentation;
  final StatDelta? scores;
  final Map<String, String>? reasons;

  const _TranscriptEntry.persona(this.text,
      {this.showHeader = false, this.presentation})
      : kind = _EntryKind.persona,
        scores = null,
        reasons = null;

  const _TranscriptEntry.player(this.text)
      : kind = _EntryKind.player,
        showHeader = false,
        presentation = null,
        scores = null,
        reasons = null;

  const _TranscriptEntry.feedback(this.scores, this.reasons)
      : kind = _EntryKind.feedback,
        text = '',
        showHeader = false,
        presentation = null;
}

enum _EntryKind { persona, player, feedback }

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
        _presentationState = _NodePresentationState.revealing;
        if (!_isModalNode(scenario.node)) {
          _transcript.add(_TranscriptEntry.persona(
            scenario.node.message,
            showHeader: true,
            presentation: scenario.node.presentation,
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
    final delay = _reactionDelays[node.reactionDelay];
    if (delay == null) return;
    setState(() => _showTyping = true);
    _scrollToBottom();
    await Future.delayed(delay);
    if (mounted) setState(() => _showTyping = false);
  }

  Future<void> _revealNode(ScenarioNode node) async {
    final token = ++_revealToken;
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
            message: node.message,
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
            message: node.message,
            choices: node.choices,
          );
          if (!mounted || selectedScene == null) return;
          await _selectChoice(selectedScene, fromModal: true);
          return;
      }
    }

    if (!mounted) return;
    await Future.delayed(_inlineRevealDurationFor(node));
    await _revealChoices(node.choices, token);
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
      );

      if (!mounted) return;
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

      // Reaction delay — typing indicator shows while we "wait" for
      // the character to respond. Only in Neighbourhood.
      await _waitForReaction(nextNode);
      if (!mounted) return;

      _trackLocation(nextNode);
      setState(() {
        _currentNodeId = nextNode.nodeId;
        _presentationState = _NodePresentationState.revealing;
        if (!_isModalNode(nextNode)) {
          _transcript.add(_TranscriptEntry.persona(
            nextNode.message,
            presentation: nextNode.presentation,
          ));
        }
      });
      _scrollToBottom();
      await _revealNode(nextNode);
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
                  // Header: back button + title.
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
                  // Location progress strip — shows where the player has
                  // been, filling in as they move through the scenario.
                  // Only renders if there's more than one visited location.
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

/// A final emotional beat before the outcome screen — no choices, just a
/// moment to sit with what happened. Renders as a minimal, centered text
/// card over a darkened backdrop, with a single "Continue" to dismiss.
/// The absence of any UI chrome (no avatar, no location strip, no
/// choices) is deliberate — this is the quiet after the storm.
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
