import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/scenario.dart';
import '../services/api_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/district_theme.dart';
import '../widgets/choice_tile.dart';
import '../widgets/persona_bubble.dart';
import '../widgets/player_bubble.dart';
import 'outcome_screen.dart';

/// One entry in the on-screen transcript. Either a persona message or the
/// player's own chosen response - rendered in order as the conversation
/// grows across turns.
class _TranscriptEntry {
  final bool isPlayer;
  final String text;
  final bool showHeader;

  const _TranscriptEntry.persona(this.text, {this.showHeader = false}) : isPlayer = false;
  const _TranscriptEntry.player(this.text)
      : isPlayer = true,
        showHeader = false;
}

class ScenarioScreen extends StatefulWidget {
  final DistrictTheme district;

  const ScenarioScreen({super.key, required this.district});

  @override
  State<ScenarioScreen> createState() => _ScenarioScreenState();
}

class _ScenarioScreenState extends State<ScenarioScreen> {
  final ApiService _api = ApiService();
  final ScrollController _scrollController = ScrollController();

  late Future<Scenario> _scenarioFuture;
  Scenario? _scenario;

  final List<_TranscriptEntry> _transcript = [];
  List<ScenarioChoice> _currentChoices = [];
  String _currentNodeId = '';
  StatDelta _runningTotal = const StatDelta();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _scenarioFuture = _api.fetchTodayScenario().then((scenario) {
      setState(() {
        _scenario = scenario;
        _currentNodeId = scenario.node.nodeId;
        _currentChoices = scenario.node.choices;
        _transcript.add(_TranscriptEntry.persona(scenario.node.message, showHeader: true));
      });
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

      if (result.terminal) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OutcomeScreen(
              district: widget.district,
              totalScores: _runningTotal,
              consequence: result.consequence ?? '',
              outcomeExplanation: result.outcomeExplanation ?? '',
            ),
          ),
        );
        return;
      }

      setState(() {
        _currentNodeId = result.node!.nodeId;
        _currentChoices = result.node!.choices;
        _transcript.add(_TranscriptEntry.persona(result.node!.message));
      });
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something went wrong: $error')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
                                child: entry.isPlayer
                                    ? PlayerBubble(district: district, label: entry.text)
                                    : PersonaBubble(
                                        district: district,
                                        name: scenario.persona.name,
                                        role: scenario.persona.role,
                                        message: entry.text,
                                        showHeader: entry.showHeader,
                                      ),
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