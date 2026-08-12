import 'package:flutter/material.dart';
import '../models/scenario.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/district_theme.dart';
import 'scenario_screen.dart';

/// Dev-only: lists every scenario currently on disk and lets you jump
/// straight into any of them, bypassing whatever the backend's default
/// "today" scenario happens to be. Only ever reached from a debug-mode
/// entry point on the home screen - see [kDebugMode] usage there.
class DevScenarioPickerScreen extends StatefulWidget {
  const DevScenarioPickerScreen({super.key});

  @override
  State<DevScenarioPickerScreen> createState() => _DevScenarioPickerScreenState();
}

class _DevScenarioPickerScreenState extends State<DevScenarioPickerScreen> {
  final ApiService _api = ApiService();
  late Future<List<ScenarioSummary>> _scenariosFuture;

  @override
  void initState() {
    super.initState();
    _scenariosFuture = _api.fetchScenarioList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Dev: Scenario Picker'),
      ),
      body: FutureBuilder<List<ScenarioSummary>>(
        future: _scenariosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Could not load scenario list.\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted),
              ),
            );
          }

          final scenarios = snapshot.data!;
          if (scenarios.isEmpty) {
            return const Center(
              child: Text('No scenarios on disk yet.', style: TextStyle(color: AppColors.textMuted)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: scenarios.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final summary = scenarios[index];
              final district = Districts.byId(summary.district);

              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ScenarioScreen(
                      district: district,
                      scenarioIdOverride: summary.id,
                    ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: district.accent.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${summary.difficulty}',
                          style: TextStyle(color: district.accent, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(summary.title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15)),
                            Text(
                              '${summary.district} · difficulty ${summary.difficulty}',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: district.accent),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}