import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../utils/date_formatting.dart';
import '../view_models/habit_detail_viewmodel.dart';

class HabitDetailScreen extends StatefulWidget {
  final HabitDetailViewModel viewModel;
  final VoidCallback? onDeleted;

  const HabitDetailScreen({super.key, required this.viewModel, this.onDeleted});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  @override
  void dispose() {
    widget.viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: ListenableBuilder(
          listenable: viewModel.load,
          builder: (_, _) {
            final habit = viewModel.habit;
            return Text(habit?.name ?? l10n.habitDefaultTitle);
          },
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete') {
                await viewModel.delete.execute();
                if (!viewModel.delete.error) {
                  widget.onDeleted?.call();
                }
              }
            },
            itemBuilder: (_) => [PopupMenuItem(value: 'delete', child: Text(l10n.delete))],
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          viewModel,
          viewModel.load,
          viewModel.delete,
          viewModel.loadCompletions,
          viewModel.toggleDayCompletion,
        ]),
        builder: (_, _) {
          if (viewModel.load.running) {
            return const Center(child: CircularProgressIndicator());
          }
          if (viewModel.load.error) {
            return Center(child: Text(l10n.habitNotFound));
          }
          if (viewModel.delete.running) {
            return const Center(child: CircularProgressIndicator());
          }
          if (viewModel.loadCompletions.running) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              const SizedBox(height: 24),
              Text('${viewModel.score}', style: Theme.of(context).textTheme.displayMedium),
              Text(
                _scoreBand(viewModel.score, l10n),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: viewModel.last30Days.length,
                  itemBuilder: (context, index) {
                    final date = viewModel.last30Days[index];
                    final dayOfMonth = date.day.toString();
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(formatDayOfWeek(context, date), style: Theme.of(context).textTheme.bodySmall),
                          Text(dayOfMonth, style: Theme.of(context).textTheme.bodySmall),
                          Checkbox(
                            value: viewModel.isDayCompleted(date),
                            onChanged: (_) => viewModel.toggleDayCompletion.execute(date),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

String _scoreBand(int score, AppLocalizations l10n) {
  if (score <= 20) return l10n.habitScoreStartingOut;
  if (score <= 50) return l10n.habitScoreBuilding;
  if (score <= 80) return l10n.habitScoreTakingShape;
  if (score <= 95) return l10n.habitScoreStrongHabit;
  return l10n.habitScoreAutomatic;
}
