import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/district_theme.dart';
import '../widgets/district_card.dart';
import '../widgets/stat_pill.dart';
import 'dev_scenario_picker_screen.dart';
import 'scenario_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Hardcoded for now, matching what's actually built. MVP ships one
  // anchor scenario per live district — The Prince for Digital, The
  // Secret for Neighbourhood — with The Bank and The Favor intentionally
  // stale/parked rather than counted here. Once the home screen fetches
  // GET /api/scenarios/list, this becomes a real count instead of a
  // maintained constant - flagged as a near-term follow-up.
  String _scenarioCountLabel(String districtId) {
    switch (districtId) {
      case 'digital':
        return '1 scenario live';
      case 'neighborhood':
        return '1 scenario live';
      case 'career':
        return '1 scenario live';
      case 'streets':
        return '7 days live';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<AppState>();

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned(
              top: -60,
              right: -40,
              child: AmbientGlow(color: AppColors.violet, size: 260),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Interactive Reality Xperience',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        // Debug-only - never ships in a release build.
                        // Purely a way to jump into any scenario on disk
                        // while building/testing them.
                        if (kDebugMode) ...[
                          const SizedBox(width: 12),
                          TextButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const DevScenarioPickerScreen(),
                              ),
                            ),
                            icon: const Icon(Icons.build_outlined, size: 14),
                            label: const Text('Dev'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.textMuted,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'IRX',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        StatPill(
                          icon: Icons.psychology_outlined,
                          label: 'SAVVY',
                          value: stats.savvy,
                          accent: AppColors.violet,
                          description: 'Spot what\'s real',
                        ),
                        const SizedBox(width: 10),
                        StatPill(
                          icon: Icons.balance_outlined,
                          label: 'INTEGRITY',
                          value: stats.integrity,
                          accent: AppColors.amber,
                          description: 'Do what\'s right',
                        ),
                        const SizedBox(width: 10),
                        StatPill(
                          icon: Icons.bolt_outlined,
                          label: 'STREET SMARTS',
                          value: stats.streetSmarts,
                          accent: AppColors.success,
                          description: 'Handle it well',
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'WORLDS',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 12),
                    ...Districts.all.map(
                      (district) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DistrictCard(
                          district: district,
                          statusLabel: _scenarioCountLabel(district.id),
                          onTap: district.available
                              ? () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ScenarioScreen(
                                        district: district,
                                        scenarioIdOverride:
                                            district.anchorScenarioId,
                                      ),
                                    ),
                                  )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}