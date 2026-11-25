import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/admin_detail_widgets.dart';
import '../../../core/widgets/admin_ui.dart';
import 'questionnaire_controller.dart';

class QuestionnaireScreen extends ConsumerWidget {
  const QuestionnaireScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(questionnaireControllerProvider);
    final notifier = ref.read(questionnaireControllerProvider.notifier);
    final theme = Theme.of(context);

    if (state.isLoading && state.overview == null) {
      return const AdminPage(
        title: 'Questionnaire',
        child: Padding(
          padding: EdgeInsets.all(48),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AdminPage(
      title: 'Questionnaire',
      subtitle: 'Lifestyle questions and how much each one counts in matching',
      actions: [
        FilledButton.icon(
          onPressed: state.isSaving
              ? null
              : () async {
                  final success = await notifier.saveWeights();
                  if (success && context.mounted) {
                    showAdminSnack(
                      context,
                      'Matching heuristic weights updated successfully',
                    );
                  }
                },
          icon: state.isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.tune, size: 18),
          label: const Text('Save Weights'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.error != null) ...[
            AdminErrorBanner(state.error!),
            const SizedBox(height: 16),
          ],

          // Heuristic weights
          AdminCard(
            title: 'Matching weights',
            subtitle:
                'Higher weights increase the penalty for differing lifestyle '
                'answers between seeker and candidate.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _WeightSlider(
                  label: 'Cleanliness Level Weight',
                  value: state.cleanlinessWeight,
                  onChanged: notifier.updateCleanlinessWeight,
                ),
                _WeightSlider(
                  label: 'Sleep Schedule Weight',
                  value: state.sleepWeight,
                  onChanged: notifier.updateSleepWeight,
                ),
                _WeightSlider(
                  label: 'Guest Tolerance Weight',
                  value: state.guestWeight,
                  onChanged: notifier.updateGuestWeight,
                ),
                _WeightSlider(
                  label: 'Dietary Preference Weight',
                  value: state.dietWeight,
                  onChanged: notifier.updateDietWeight,
                ),
                const Divider(height: 24),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Smoking Habit Dealbreaker'),
                  subtitle: const Text(
                    'Immediately disqualify matches where a Non-smoker meets a '
                    'Regular smoker (0% match percentage)',
                  ),
                  value: state.smokingDealbreaker,
                  onChanged: notifier.updateSmokingDealbreaker,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Active Questionnaire Dimensions',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (state.overview != null)
            for (final cat in state.overview!.categories) ...[
              AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(cat.title, style: theme.textTheme.titleSmall),
                        AdminChip(
                          cat.isDealbreaker
                              ? 'Hard Dealbreaker'
                              : 'Weight: ${cat.weight.toStringAsFixed(1)}',
                          tone: cat.isDealbreaker
                              ? ChipTone.danger
                              : ChipTone.info,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cat.headline,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(cat.description, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final opt in cat.options)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  opt.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  opt.description,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
        ],
      ),
    );
  }
}

/// "Label ——o—— 2.5": label on its own line when the card is narrow.
class _WeightSlider extends StatelessWidget {
  const _WeightSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final labelText = Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w600),
    );
    final slider = Row(
      children: [
        Expanded(
          child: Slider(
            value: value,
            min: 0.0,
            max: 5.0,
            divisions: 50,
            label: value.toStringAsFixed(1),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            value.toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: LayoutBuilder(
        builder: (context, c) => c.maxWidth < 520
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [labelText, slider],
              )
            : Row(
                children: [
                  SizedBox(width: 220, child: labelText),
                  Expanded(child: slider),
                ],
              ),
      ),
    );
  }
}
