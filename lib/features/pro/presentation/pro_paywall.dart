import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trail_path/core/domain/premium.dart';
import 'package:trail_path/core/localization/app_localizations.dart';
import 'package:trail_path/features/pro/application/premium_controller.dart';

Future<void> showTrailPathProPaywall(
  BuildContext context,
  WidgetRef ref,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const TrailPathProSheet(),
  );
}

class TrailPathProSheet extends ConsumerWidget {
  const TrailPathProSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final premium = ref.watch(premiumControllerProvider);
    final controller = ref.read(premiumControllerProvider.notifier);
    final monthly = premium.offerFor(PremiumPlan.monthly);
    final yearly = premium.offerFor(PremiumPlan.yearly);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.trailPathPro,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        premium.isPro ? strings.proActive : strings.proSubtitle,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _Benefit(
              icon: Icons.satellite_alt_rounded,
              text: strings.proBenefitMaps,
            ),
            _Benefit(icon: Icons.draw_rounded, text: strings.proBenefitTrace),
            _Benefit(
              icon: Icons.download_for_offline_rounded,
              text: strings.proBenefitOffline,
            ),
            _Benefit(
              icon: Icons.insights_rounded,
              text: strings.proBenefitStats,
            ),
            _Benefit(
              icon: Icons.cloud_sync_rounded,
              text: strings.proBenefitCloud,
            ),
            const SizedBox(height: 18),
            if (premium.isLoading)
              const Center(child: CircularProgressIndicator.adaptive())
            else if (premium.isPro)
              FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.verified_rounded),
                label: Text(strings.proActive),
              )
            else ...[
              FilledButton(
                onPressed: monthly == null || premium.purchasePending
                    ? null
                    : () => controller.purchase(PremiumPlan.monthly),
                child: Text(
                  monthly == null
                      ? strings.proMonthlyUnavailable
                      : '${strings.proMonthly} · ${monthly.price}',
                ),
              ),
              const SizedBox(height: 9),
              FilledButton.tonal(
                onPressed: yearly == null || premium.purchasePending
                    ? null
                    : () => controller.purchase(PremiumPlan.yearly),
                child: Text(
                  yearly == null
                      ? strings.proYearlyUnavailable
                      : '${strings.proYearly} · ${yearly.price}',
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: premium.storeAvailable && !premium.purchasePending
                    ? controller.restore
                    : null,
                child: Text(strings.restorePurchases),
              ),
            ],
            if (!premium.isPro &&
                !premium.storeAvailable &&
                !premium.isLoading) ...[
              const SizedBox(height: 8),
              Text(
                strings.proStoreUnavailable,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
            if (premium.error != null) ...[
              const SizedBox(height: 8),
              Text(
                strings.proPurchaseError,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (!premium.isPro) ...[
              const SizedBox(height: 10),
              Text(
                strings.proRenewalNotice,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              strings.proSafetyFree,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
