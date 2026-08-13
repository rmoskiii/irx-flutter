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
import 'outcome_screen.dart';

/// One entry in the on-screen transcript: a persona message, the player's
/// own response, or a transparency note explaining what just changed and
/// why. [presentation] (persona entries only) decides whether a persona
/// entry renders as the default chat bubble or an inline type like
/// [EmailCard].
class _TranscriptEntry {
  final _EntryKind kind;
  final String text;
  final bool showHeader;
  final ScenarioPresentation? presentation;
  final StatDelta? scores;
  final Map<String, String>? reasons;

  const _TranscriptEntry.persona(this.text, {this.showHeader = false, this.presentation})
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

class ScenarioScreen extends StatefulWidget {
  final DistrictTheme district;

  /// Optional - when set (from the dev picker), fetches this specific
  /// scenario instead of the backend's default. Omit for normal play.
  final String? scenarioIdOverride;

  const ScenarioScreen({super.key, required this.district, this.scenarioIdOverride});

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
  List<ScenarioChoice> _currentChoices = [];
  String _currentNodeId = '';
  StatDelta _runningTotal = const StatDelta();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _scenarioFuture = _api.fetchTodayScenario(scenarioId: widget.scenarioIdOverride).then((scenario) {
      setState(() {
        _scenario = scenario;
        _currentNodeId = scenario.node.nodeId;
        _transcript.add(_TranscriptEntry.persona(
          scenario.node.message,
          showHeader: true,
          presentation: scenario.node.presentation,
        ));
      });
      // The very first node could theoretically be a modal beat too, so
      // route it through the same reveal path as any other turn.
      _revealNode(scenario.node);
      return scenario;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  /// Decides how a newly-arrived node's choices get revealed. A plain node
  /// (or an inline-styled one, like "email") shows its choices
  /// immediately. A node flagged `presentation.modal` holds its choices
  /// back until the player has closed the modal - so they can't respond to
  /// a document or payment request they haven't actually "seen" yet.
  Future<void> _revealNode(ScenarioNode node) async {
    final presentation = node.presentation;

    if (presentation != null && presentation.modal) {
      switch (presentation.type) {
        case 'document':
          await showDocumentModal(context, district: widget.district, data: presentation.data);
          break;
        case 'payment_request':
          final selected = await showPaymentRequestModal(
            context,
            district: widget.district,
            data: presentation.data,
            choices: node.choices,
          );
          if (!mounted || selected == null) return;
          // The response was made from inside the modal itself - hand it
          // straight to the normal choice flow instead of falling through
          // to the generic "reveal choices below" path.
          await _selectChoice(selected);
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
          await _selectChoice(selectedCall);
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
          await _selectChoice(selectedScene);
          return;
        // Future modal types get their own case here.
      }
    }

    if (!mounted) return;
    setState(() => _currentChoices = node.choices);
    _scrollToBottom();
  }

  Future<void> _selectChoice(ScenarioChoice choice) async {
    if (_submitting || _scenario == null) return;
    setState(() {
      _submitting = true;
      _transcript.add(_TranscriptEntry.player(choice.label));
      _currentChoices = [];
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

      setState(() {
        // Transparency note lands immediately, before the conversation
        // continues - the point is to build trust turn by turn, not save
        // the explanation for a summary screen at the very end.
        _transcript.add(_TranscriptEntry.feedback(result.scores, result.reasons));
      });
      _scrollToBottom();

      if (result.terminal) {
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
      setState(() {
        _currentNodeId = nextNode.nodeId;
        _transcript.add(_TranscriptEntry.persona(
          nextNode.message,
          presentation: nextNode.presentation,
        ));
      });
      _scrollToBottom();
      setState(() => _submitting = false);
      await _revealNode(nextNode);
      return;
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something went wrong: $error')),
      );
    } finally {
      if (mounted && _submitting) setState(() => _submitting = false);
    }
  }

  Widget _buildPersonaEntry(BuildContext context, Scenario scenario, _TranscriptEntry entry) {
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
                return _ErrorState(district: district, error: '${snapshot.error}');
              }

              final scenario = _scenario!;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
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
                                  _EntryKind.player =>
                                    PlayerBubble(district: district, label: entry.text),
                                  _EntryKind.feedback => ScoreFeedback(
                                      scores: entry.scores!,
                                      reasons: entry.reasons!,
                                      district: district,
                                      compact: true,
                                    ),
                                  _EntryKind.persona =>
                                    _buildPersonaEntry(context, scenario, entry),
                                },
                              ),
                            if (_submitting)
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
                                (choice) => ChoiceTile(
                                  label: choice.label,
                                  district: district,
                                  disabled: _submitting,
                                  onTap: () => _selectChoice(choice),
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