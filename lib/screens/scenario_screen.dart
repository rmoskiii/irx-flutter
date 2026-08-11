import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/scenario.dart';
import '../services/api_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/district_theme.dart';
import '../widgets/choice_tile.dart';
import '../widgets/persona_bubble.dart';
import 'outcome_screen.dart';

class ScenarioScreen extends StatefulWidget {
  final DistrictTheme district;

  const ScenarioScreen({super.key, required this.district});

  @override
  State<ScenarioScreen> createState() => _ScenarioScreenState();
}

class _ScenarioScreenState extends State<ScenarioScreen> {
  final ApiService _api = ApiService();

  late Future<Scenario> _scenarioFuture;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _scenarioFuture = _api.fetchTodayScenario();
  }

  Future<void> _selectChoice(Scenario scenario, ScenarioChoice choice) async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      final result = await _api.submitChoice(
        scenarioId: scenario.id,
        choiceId: choice.id,
      );

      if (!mounted) return;
      context.read<AppState>().applyResult(result.scores);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OutcomeScreen(district: widget.district, result: result),
        ),
      );
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

              final scenario = snapshot.data!;

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
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PersonaBubble(
                              district: district,
                              name: scenario.persona.name,
                              role: scenario.persona.role,
                              message: scenario.opening,
                            ),
                            const SizedBox(height: 28),
                            Text(
                              'HOW DO YOU RESPOND?',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            const SizedBox(height: 12),
                            ...scenario.choices.map(
                              (choice) => ChoiceTile(
                                label: choice.label,
                                district: district,
                                disabled: _submitting,
                                onTap: () => _selectChoice(scenario, choice),
                              ),
                            ),
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
