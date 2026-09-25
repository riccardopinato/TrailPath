import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trail_path/core/database/database_providers.dart';
import 'package:trail_path/core/localization/app_localizations.dart';
import 'package:trail_path/features/home/presentation/home_shell.dart';

const onboardingCompletedSettingKey = 'onboarding.completed';

class OnboardingGate extends ConsumerStatefulWidget {
  const OnboardingGate({super.key});

  @override
  ConsumerState<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends ConsumerState<OnboardingGate> {
  bool? _completed;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_load);
  }

  Future<void> _load() async {
    final value = await ref
        .read(appDatabaseProvider)
        .getSetting(onboardingCompletedSettingKey);
    if (!mounted) {
      return;
    }
    setState(() => _completed = value == 'true');
  }

  Future<void> _complete() async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    await ref
        .read(appDatabaseProvider)
        .setSetting(onboardingCompletedSettingKey, 'true');
    if (!mounted) {
      return;
    }
    setState(() {
      _completed = true;
      _saving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final completed = _completed;
    if (completed == null) {
      return const Scaffold(
        body: Center(
          child: Semantics(
            label: 'TrailPath',
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    if (completed) {
      return const HomeShell();
    }

    return _OnboardingScreen(onStart: _complete, saving: _saving);
  }
}

class _OnboardingScreen extends StatelessWidget {
  const _OnboardingScreen({required this.onStart, required this.saving});

  final VoidCallback onStart;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          strings.onboardingTitle,
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        strings.onboardingIntro,
                        style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 26),
                      _OnboardingCard(
                        icon: Icons.route_rounded,
                        title: strings.onboardingPlanTitle,
                        body: strings.onboardingPlanBody,
                      ),
                      const SizedBox(height: 12),
                      _OnboardingCard(
                        icon: Icons.cloud_done_rounded,
                        title: strings.onboardingOfflineTitle,
                        body: strings.onboardingOfflineBody,
                      ),
                      const SizedBox(height: 12),
                      _OnboardingCard(
                        icon: Icons.navigation_rounded,
                        title: strings.onboardingRecordTitle,
                        body: strings.onboardingRecordBody,
                      ),
                      const SizedBox(height: 20),
                      Semantics(
                        container: true,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.privacy_tip_outlined,
                              size: 20,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                strings.onboardingPrivacy,
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      SizedBox(
                        height: 52,
                        child: FilledButton.icon(
                          key: const ValueKey('onboarding_start'),
                          onPressed: saving ? null : onStart,
                          icon: saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.arrow_forward_rounded),
                          label: Text(strings.onboardingStart),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      body,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
