import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/district_theme.dart';
import '../widgets/district_card.dart';
import '../widgets/stat_pill.dart';
import 'scenario_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
                    Text(
                      'Good evening.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'What will life throw at you today?',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: 24),
                    StatPill(
                      icon: Icons.psychology_outlined,
                      label: 'SAVVY',
                      description: 'Understand what is really happening',
                      value: stats.savvy,
                      accent: AppColors.violet,
                    ),
                    const SizedBox(height: 10),
                    StatPill(
                      icon: Icons.balance_outlined,
                      label: 'INTEGRITY',
                      description: 'Stay true to what\'s right under pressure',
                      value: stats.integrity,
                      accent: AppColors.amber,
                    ),
                    const SizedBox(height: 10),
                    StatPill(
                      icon: Icons.bolt_outlined,
                      label: 'STREET SMARTS',
                      description: 'Good judgment to protect yourself',
                      value: stats.streetSmarts,
                      accent: AppColors.success,
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
                          progress: district.available ? 0.4 : 0,
                          onTap: district.available
                              ? () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ScenarioScreen(district: district),
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