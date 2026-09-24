import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../content/scenario_intros.dart';
import '../models/scenario.dart';
import '../services/api_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/district_theme.dart';
import '../utils/reading_time.dart';
import '../widgets/call_modal.dart';
import '../widgets/choice_tile.dart';
import '../widgets/document_modal.dart';
import '../widgets/email_card.dart';
import '../widgets/interstitial_overlay.dart';
import '../state/run_store.dart';
import '../widgets/messages_card.dart';
import '../widgets/montage_card.dart';
import '../widgets/payment_request_modal.dart';
import '../widgets/persona_bubble.dart';
import '../widgets/player_bubble.dart';
import '../widgets/scenario_intro_modal.dart';
import '../widgets/scene_card.dart';
import '../widgets/scene_modal.dart';
import '../widgets/score_feedback.dart';
import '../widgets/search_results_card.dart';
import '../widgets/sms_card.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/work_artifact_card.dart';
import 'outcome_screen.dart';
import '../models/scene_render.dart';
import '../widgets/shell/cinematic_shell.dart';

/// Reaction delay floors keyed by the string value in the scenario JSON.
/// The actual pause also scales with the node's text length.
const _reactionDelayFloors = {
  'short': Duration(milliseconds: 800),
  'medium': Duration(milliseconds: 1500),
  'long': Duration(milliseconds: 2500),
};

const _choiceStaggerDelay = Duration(milliseconds: 95);
const _choiceCommitDelay = Duration(milliseconds: 140);
const _defaultInlineRevealDuration = Duration(milliseconds: 280);

const _modalDismissDwell = Duration(milliseconds: 600);

/// One entry in the on-screen transcript. A persona entry carries either
/// [text] (chat/scene/email/sms/search_results) OR [thread] (messages) —
/// never both.
class _TranscriptEntry {
  final _EntryKind kind;
  final String text;
  final List<ThreadSegment>? thread;
  final bool showHeader;
  final ScenarioPresentation? presentation;
  final SceneRender? render; 
  final StatDelta? scores;
  final Map<String, String>? reasons;

  const _TranscriptEntry.persona(
    this.text, {
    this.showHeader = false,
    this.presentation,
    this.thread,
    this.render,
  })  : kind = _EntryKind.persona,
        scores = null,
        reasons = null;

  const _TranscriptEntry.player(this.text)
      : kind = _EntryKind.player,
        thread = null,
        showHeader = false,
        presentation = null,
        render = null,
        scores = null,
        reasons = null;

    const _TranscriptEntry.feedback(this.scores, this.reasons)
      : kind = _EntryKind.feedback,
        text = '',
        thread = null,
        showHeader = false,
        presentation = null,
        render = null;

  const _TranscriptEntry.beat(this.text)
      : kind = _EntryKind.beat,
        thread = null,
        showHeader = false,
        presentation = null,
        render = null,
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

  /// Whether to show the framing card before the first node. Replay from
  /// the outcome screen can pass false to skip it, or leave it true and
  /// rely on [isReplay] to soften it instead.
  final bool showIntro;

  /// Softens the intro on a second run: barrier becomes dismissible so
  /// the player isn't forced through copy they've already read.
  final bool isReplay;

  const ScenarioScreen({
    super.key,
    required this.district,
    this.scenarioIdOverride,
    this.showIntro = true,
    this.isReplay = false,
  });

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
  ScenarioNode? _currentNode;

  /// The ripple of the choice just made, while the next node is in flight. The
  /// transcript keeps its own copy; the shell has no transcript to put it in,
  /// so it shows here and is cleared the moment the next node reveals.
  String? _currentBeat;
  StatDelta _runningTotal = const StatDelta();

  /// Opaque scenario state — initialised by the backend from stateSchema,
  /// updated on every /respond, sent back verbatim on the next turn. The
  /// client NEVER reads a key out of this map, so variant/routing logic
  /// on the backend can't desync from the renderer.
  Map<String, dynamic> _scenarioState = const {};

  /// The day the current node belongs to. Null for scenarios that aren't
  /// day-structured. Compared against the day of each incoming node: a change
  /// is a day boundary, and a day boundary is the only moment a run is saved.
  int? _currentDay;

  /// Run creation time, carried through every snapshot so run age survives
  /// a resume. Provenance only — it does not gate anything.
  DateTime _startedAt = DateTime.now();

  /// True when this session opened from a saved run rather than the root.
  /// The transcript starts empty either way — day openings are authored as
  /// cold opens precisely so a resume needs no recap.
  bool _resumed = false;

  /// Set when a saved run existed but could not be used. Null in the ordinary
  /// case of there being no run at all.
  RunDiscardReason? _discardedRun;

  _NodePresentationState _presentationState = _NodePresentationState.revealing;
  bool _showTyping = false;
  String? _selectedChoiceId;
  int _revealToken = 0;

  /// True while the intro card is up. Suppresses the loading spinner
  /// underneath it — the scenario future deliberately doesn't resolve
  /// until the card is dismissed, so without this a spinner sits behind
  /// the barrier for the whole read.
  bool _introVisible = false;

  bool get _isNeighborhood => widget.district.id == 'neighborhood';

  /// Whether per-turn score reasons are suppressed during play. Declared by
  /// the scenario rather than inferred from its district: The Prince is
  /// Digital but must hide deltas, because visible numbers let a player
  /// shop the verification menu — the exact skill under test. The full
  /// ledger still appears on the outcome screen either way.
  bool get _hidesInlineFeedback => _scenario?.revealTiming == 'end_only';

  bool get _choiceInputLocked =>
      _presentationState != _NodePresentationState.waitingForChoice;

  /// Opens the scenario, resuming a saved run if one is still valid.
  ///
  /// `/today` is always called first, because it is the authority on the
  /// current `contentRevision` — a snapshot cannot be trusted to describe the
  /// content it was written against. Only then is the stored run consulted.
  ///
  /// A replay explicitly discards any saved run: choosing to start again is
  /// the one place where losing a week is what the player asked for.
  Future<Scenario> _loadOrResume() async {
    final fresh =
        await _api.fetchTodayScenario(scenarioId: widget.scenarioIdOverride);

    if (widget.isReplay) {
      await RunStore.clear(fresh.scenarioId);
      return fresh;
    }

    RunReadResult stored;
    try {
      stored = await RunStore.read(fresh.scenarioId,
          currentContentRevision: fresh.contentRevision);
    } catch (_) {
      return fresh;
    }

    // A discarded run is not an error path the player should meet silently,
    // but it is also not a reason to fail to open: they start the week again.
    // _discardedRun lets the UI say something true about why.
    _discardedRun = stored.discarded;
    if (!stored.hasRun) return fresh;

    final snapshot = stored.snapshot!;
    try {
      final resumed = await _api.fetchNode(
        scenarioId: snapshot.scenarioId,
        nodeId: snapshot.nodeId,
        state: snapshot.state,
      );
      _runningTotal = snapshot.runningTotal;
      _breakdown
        ..clear()
        ..addAll(snapshot.breakdown);
      _startedAt = snapshot.startedAt;
      _resumed = true;
      return resumed;
    } catch (_) {
      // Server unreachable or the node no longer exists. Keep the snapshot —
      // the next launch may succeed — and open the scenario from the top
      // rather than refusing to open at all.
      return fresh;
    }
  }

  @override
  void initState() {
    super.initState();
    _scenarioFuture = _loadOrResume().then((scenario) async {
      if (!mounted) return scenario;

      setState(() {
        _scenario = scenario;
        _currentNodeId = scenario.node.nodeId;
        _currentDay = scenario.node.day;
        _scenarioState = scenario.state;
        _presentationState = _NodePresentationState.revealing;
      });

      // Intro first, transcript second. Populating the transcript before
      // the card is dismissed would let a modal-presentation root node
      // stack on top of it.
      // Not on a resume: the intro introduces a week that is already
      // four days old by then.
      if (widget.showIntro && !_resumed) {
        final intro = ScenarioIntros.forScenario(scenario.scenarioId);
        if (intro != null && mounted) {
          setState(() => _introVisible = true);
          await showScenarioIntro(
            context,
            district: widget.district,
            intro: intro,
            dismissible: widget.isReplay,
          );
          if (!mounted) return scenario;
          setState(() => _introVisible = false);
        }
      }

      setState(() {
        if (!_isModalNode(scenario.node)) {
          _transcript.add(_TranscriptEntry.persona(
            scenario.node.message ?? '',
            showHeader: true,
            presentation: scenario.node.presentation,
            thread: scenario.node.thread,
            render: scenario.node.render,
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

  Duration _choiceRevealDelayFor(ScenarioNode node) {
    final revealDuration = _inlineRevealDurationFor(node);
    if (!_isNeighborhood && !widget.district.usesCinematicShell) {
      return revealDuration;
    }
    if (node.thread != null) {
      return readingHoldForThread(
        node.thread!,
        minMs: revealDuration.inMilliseconds,
        maxMs: 7000,
      );
    }
    return readingHoldForText(
      node.message ?? '',
      minMs: revealDuration.inMilliseconds,
      maxMs: 7000,
    );
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

  /// Waits for the node's reaction delay while showing a typing indicator.
  ///
  /// Driven by the presence of an authored `reactionDelay` rather than by
  /// district. Digital scenarios that want the old immediate/functional
  /// pacing simply don't author one and this no-ops, exactly as before —
  /// but The Prince, which is Digital and deliberately slow, gets the
  /// pauses it asks for instead of having them discarded.
  Future<void> _waitForReaction(ScenarioNode node) async {
    // An interstitial is already a pause. Running both back-to-back gives
    // 4.5s of blank screen on exactly the beats that matter most.
    if (node.interstitial != null) return;
    final floor = _reactionDelayFloors[node.reactionDelay];
    if (floor == null) return;
    final textHold = node.thread != null
        ? readingHoldForThread(
            node.thread!,
            minMs: floor.inMilliseconds,
            maxMs: 3500,
            msPerWord: 45,
          )
        : readingHoldForText(
            node.message ?? '',
            minMs: floor.inMilliseconds,
            maxMs: 3500,
            msPerWord: 45,
          );
    setState(() => _showTyping = true);
    _scrollToBottom();
    await Future.delayed(textHold);
    if (mounted) setState(() => _showTyping = false);
  }

  void _addModalNodeToTranscript(ScenarioNode node) {
    final hasMessage = (node.message ?? '').trim().isNotEmpty;
    final hasThread = node.thread?.isNotEmpty ?? false;
    if (!hasMessage && !hasThread) return;

    setState(() {
      _transcript.add(_TranscriptEntry.persona(
        node.message ?? '',
        presentation: node.presentation,
        thread: node.thread,
        render: null,
      ));
    });
    _scrollToBottom();
  }

  Future<void> _commitModalChoice(
    ScenarioNode node,
    ScenarioChoice choice,
  ) async {
    _addModalNodeToTranscript(node);
    await Future.delayed(_modalDismissDwell);
    if (!mounted) return;
    await _selectChoice(choice, fromModal: true);
  }

  Future<void> _revealNode(ScenarioNode node, {int? token}) async {
    final revealToken = token ?? ++_revealToken;
    if (revealToken != _revealToken) return;
    final presentation = node.presentation;
    setState(() {
      _presentationState = _NodePresentationState.revealing;
      _currentChoices = [];
      _selectedChoiceId = null;
      _currentNode = node;
      _currentBeat = null;
    });

    // In the cinematic shell every scene is ALREADY a full-screen interruption,
    // so a scene node's `modal: true` has nothing left to add: it puts a card of
    // the same room on top of the room. Eleven Streets nodes carry that flag,
    // and in the shell they play like any other scene.
    //
    // `messages` and `call` keep their modals. Those are phone interfaces rather
    // than rooms — the point of them is that they interrupt the scene — and
    // `document` and `payment_request` are the same kind of object.
    final suppressModal =
        widget.district.usesCinematicShell && presentation?.type == 'scene';

    if (presentation != null && presentation.modal && !suppressModal) {
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
          await _commitModalChoice(node, selected);
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
          await _commitModalChoice(node, selectedCall);
          return;
        case 'scene':
          final selectedScene = await showSceneModal(
            context,
            district: widget.district,
            data: presentation.data,
            message: node.message ?? '',
            choices: node.choices,
            render: node.render,
          );
          if (!mounted || selectedScene == null) return;
          await _commitModalChoice(node, selectedScene);
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
          await _commitModalChoice(node, selectedThread);
          return;
      }
    }

    if (!mounted) return;
    await Future.delayed(_choiceRevealDelayFor(node));
    await _revealChoices(node.choices, revealToken);
  }

  /// Writes the run at a day boundary. Stores the NEXT day's opening node, so
  /// a resume opens on the new day rather than replaying the close of the old
  /// one. Best-effort: a failed write costs the player a replayed day, so it
  /// must never take down the turn that succeeded.
  Future<void> _persistDayBoundary(String nextNodeId, int? day) async {
    final scenario = _scenario;
    if (scenario == null) return;

    try {
      await RunStore.write(RunSnapshot(
        snapshotVersion: RunSnapshot.currentVersion,
        contentRevision: scenario.contentRevision,
        scenarioId: scenario.scenarioId,
        nodeId: nextNodeId,
        day: day,
        state: _scenarioState,
        runningTotal: _runningTotal,
        breakdown: List.unmodifiable(_breakdown),
        startedAt: _startedAt,
        updatedAt: DateTime.now(),
      ));
    } catch (_) {
      // Persistence is best-effort, not load-bearing.
    }
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

      // A day boundary is a non-terminal node whose day differs from the one
      // we were on. Persist BEFORE any interstitial or UI transition runs, so
      // the window in which a kill loses the boundary is milliseconds rather
      // than the length of an animation.
      //
      // Deliberately loss-tolerant in one direction only: a player may lose a
      // day and replay it, never gain one.
      final nextDay = result.node?.day;
      final crossedDay = !result.terminal &&
          result.node != null &&
          nextDay != null &&
          nextDay != _currentDay;

      if (crossedDay) {
        _currentDay = nextDay;
        await _persistDayBoundary(result.node!.nodeId, nextDay);
        if (!mounted) return;
      }

      // Declared by the scenario, not inferred from its district. The Streets
      // keeps real score values for compatibility and for the results log, and
      // contributes none of them to the player-facing pool the home screen
      // reads. _runningTotal and _breakdown are still accumulated: the outcome
      // screen decides what it renders, and the run's own totals are not the
      // cross-scenario pool.
      if (_scenario?.playerVisible ?? true) {
        context.read<AppState>().applyResult(result.scores);
      }
      _runningTotal = _runningTotal + result.scores;
      _breakdown.add(TurnBreakdown(
        choiceLabel: choice.label,
        scores: result.scores,
        reasons: result.reasons,
      ));

      // Reveal timing is declared by the scenario, not inferred from the
      // district it lives in.
      if (!_hidesInlineFeedback) {
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
        setState(() {
          _transcript.add(_TranscriptEntry.beat(result.beat!));
          _currentBeat = result.beat;
        });
        _scrollToBottom();
        await Future.delayed(readingHoldForText(result.beat!));
        if (!mounted) return;
      }

      if (result.terminal) {
        // The week is over: the run is no longer resumable. Cleared here
        // rather than on the outcome screen so a kill during the ending
        // cannot leave a completed run looking resumable.
        await RunStore.clear(_scenario!.scenarioId);
        if (!mounted) return;

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
              reflectionTitle: result.reflectionTitle,
              reflectionText: result.reflectionText,
              aftermath: result.aftermath,
              finalMessage: result.finalMessage,
              breakdown: List.unmodifiable(_breakdown),
              playerVisible: _scenario!.playerVisible,
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
            render: nextNode.render,
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

    if (presentation != null && presentation.type == 'work_artifact') {
      return WorkArtifactCard(
        district: widget.district,
        data: presentation.data,
        body: entry.text,
      );
    }

    // A results page for a query the player ran themselves. The node's
    // own message still renders underneath as the narration of what they
    // found — the card is the artifact, the message is the reading of it.
    if (presentation != null && presentation.type == 'search_results') {
      final data = presentation.data;
      final results = ((data['results'] as List?) ?? const [])
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchResultsCard(
            district: widget.district,
            query: data['query'] as String? ?? '',
            results: results,
          ),
          if (entry.text.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              entry.text,
              style:
                  Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.55),
            ),
          ],
        ],
      );
    }

    // Compressed time. Must come before the generic fallback: without it a
    // montage node reached PersonaBubble and its composed panels were dropped.
    if (presentation != null && presentation.type == 'montage') {
      return MontageCard(
        district: widget.district,
        location: presentation.data['location'] as String? ?? '',
        message: entry.text,
        render: entry.render,
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
        data: data,
        render: entry.render,
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

  /// The full-screen presentation, for districts that declare it. Deliberately
  /// a sibling of the transcript build rather than a branch inside it: the two
  /// share every piece of turn machinery above this line and no layout at all
  /// below it, and keeping them apart means moving a district onto the shell
  /// cannot disturb the districts still on the transcript.
  Widget _buildShell(BuildContext context, DistrictTheme district) {
    return Scaffold(
      backgroundColor: district.backgroundGradient.last,
      body: FutureBuilder<Scenario>(
        future: _scenarioFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            // as in the transcript: the future stays unresolved behind the
            // intro card on purpose, so don't spin underneath it
            if (_introVisible) return const SizedBox.shrink();
            return Center(
              child: CircularProgressIndicator(color: district.accent),
            );
          }
          if (snapshot.hasError) {
            return SafeArea(
              child: _ErrorState(district: district, error: '${snapshot.error}'),
            );
          }

          return CinematicShell(
            district: district,
            scenarioId: snapshot.data?.scenarioId ?? _scenario?.scenarioId ?? '',
            node: _currentNode,
            beat: _currentBeat,
            choices: _currentChoices,
            selectedChoiceId: _selectedChoiceId,
            locked: _choiceInputLocked,
            busy: _showTyping ||
                _presentationState == _NodePresentationState.submitting ||
                _presentationState == _NodePresentationState.transitioning,
            onChoice: _selectChoice,
            onExit: () => Navigator.of(context).pop(),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final district = widget.district;

    if (district.usesCinematicShell) return _buildShell(context, district);

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
                // The future intentionally stays unresolved while the
                // intro card is up. Don't spin behind it.
                if (_introVisible) return const SizedBox.shrink();
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