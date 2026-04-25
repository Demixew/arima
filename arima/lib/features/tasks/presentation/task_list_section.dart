import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../application/task_list_controller.dart';
import '../application/task_mutation_controller.dart';
import '../application/task_view_controller.dart';
import '../domain/task_item.dart';
import '../domain/task_reminder.dart';
import '../domain/task_status.dart';
import 'task_form_dialog.dart';

class TaskListSection extends ConsumerStatefulWidget {
  const TaskListSection({super.key});

  @override
  ConsumerState<TaskListSection> createState() => _TaskListSectionState();
}

class _TaskListSectionState extends ConsumerState<TaskListSection> {
  ProviderSubscription<AsyncValue<void>>? _mutationSubscription;

  @override
  void initState() {
    super.initState();
    _mutationSubscription = ref.listenManual<AsyncValue<void>>(
      taskMutationControllerProvider,
      (AsyncValue<void>? previous, AsyncValue<void> next) {
        if (!mounted) {
          return;
        }

        final l10n = AppLocalizations.of(context)!;

        if (next.hasError) {
          final String message =
              ref.read(taskMutationControllerProvider.notifier).errorMessage() ??
              l10n.taskActionFailed;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
          return;
        }

        final bool completedAction =
            previous != null && previous.isLoading && !next.isLoading && !next.hasError;
        if (completedAction) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.taskSyncedSuccess)),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _mutationSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<TaskItem>> taskState = ref.watch(taskListControllerProvider);
    final AsyncValue<void> mutationState = ref.watch(taskMutationControllerProvider);
    final TaskFilter activeFilter = ref.watch(taskViewControllerProvider);
    final ThemeData theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final String? error = ref.read(taskListControllerProvider.notifier).errorMessage();
    final List<TaskItem> tasks = taskState.valueOrNull ?? <TaskItem>[];
    final List<TaskItem> visibleTasks = tasks
        .where((TaskItem task) => ref.read(taskViewControllerProvider.notifier).matches(task.status))
        .toList();
    final bool isMutating = mutationState.isLoading;
    final int completedCount =
        tasks.where((TaskItem task) => task.status == TaskStatus.completed).length;
    final int activeCount = tasks
        .where((TaskItem task) => task.status == TaskStatus.pending || task.status == TaskStatus.inProgress)
        .length;
    final int escalatedCount = tasks
        .where((TaskItem task) => task.reminder?.escalatedToParent == true)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(l10n.tasksSectionTitle, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text(l10n.tasksSectionSubtitle),
                ],
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              tooltip: l10n.refreshTasks,
              onPressed: isMutating ? null : ref.read(taskListControllerProvider.notifier).refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: isMutating ? null : () => _openCreateDialog(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.newTask),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: <Widget>[
            _TaskMetricCard(
              label: l10n.totalTasks,
              value: tasks.length.toString(),
              icon: Icons.inbox_rounded,
            ),
            _TaskMetricCard(
              label: l10n.activeNow,
              value: activeCount.toString(),
              icon: Icons.play_circle_outline_rounded,
            ),
            _TaskMetricCard(
              label: l10n.completedTasks,
              value: completedCount.toString(),
              icon: Icons.check_circle_outline_rounded,
            ),
            _TaskMetricCard(
              label: l10n.escalations,
              value: escalatedCount.toString(),
              icon: Icons.notifications_active_outlined,
            ),
          ],
        ),
        const SizedBox(height: 18),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: TaskFilter.values
                .map(
                  (TaskFilter filter) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text(filter.label(l10n)),
                      selected: filter == activeFilter,
                      onSelected: (_) => ref.read(taskViewControllerProvider.notifier).setFilter(filter),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 20),
        AppAsyncView(
          isLoading: taskState.isLoading && tasks.isEmpty,
          error: tasks.isEmpty ? error : null,
          child: tasks.isEmpty
              ? EmptyStateView(
                  title: l10n.noTasksYet,
                  message: l10n.addFirstTaskHint,
                  action: ElevatedButton(
                    onPressed: isMutating ? null : () => _openCreateDialog(context),
                    child: Text(l10n.createFirstTask),
                  ),
                )
              : visibleTasks.isEmpty
              ? EmptyStateView(
                  title: l10n.noTasksInThisView,
                  message: l10n.switchFilterOrCreate,
                  action: TextButton(
                    onPressed: () => ref.read(taskViewControllerProvider.notifier).setFilter(TaskFilter.all),
                    child: Text(l10n.showAllTasks),
                  ),
                )
              : Column(
                  children: <Widget>[
                    if (taskState.isRefreshing) ...<Widget>[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: LinearProgressIndicator(),
                      ),
                    ],
                    ...visibleTasks.map(
                      (TaskItem task) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _TaskCard(
                          task: task,
                          isBusy: isMutating,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _openCreateDialog(BuildContext context) async {
    final TaskFormResult? result = await showDialog<TaskFormResult>(
      context: context,
      builder: (BuildContext context) => const TaskFormDialog(),
    );

    if (result == null) {
      return;
    }

    await ref.read(taskMutationControllerProvider.notifier).createTask(
          title: result.title,
          description: result.description,
          status: result.status,
          dueAt: result.dueAt,
          reminderEnabled: result.reminderEnabled,
          remindAfterHours: result.remindAfterHours,
          maxMissedCount: result.maxMissedCount,
          difficultyLevel: result.difficultyLevel,
          estimatedTimeMinutes: result.estimatedTimeMinutes,
          antiFatigueEnabled: result.antiFatigueEnabled,
        );
  }
}

class _TaskCard extends ConsumerWidget {
  const _TaskCard({
    required this.task,
    required this.isBusy,
  });

  final TaskItem task;
  final bool isBusy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(task.title, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 6),
                      Text(task.description ?? l10n.noDescriptionYet),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _StatusBadge(status: task.status),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
            children: <Widget>[
              _InfoPill(
                icon: Icons.schedule_rounded,
                label: DateFormatters.shortDateTime(task.dueAt, l10n: l10n),
              ),
              _InfoPill(
                icon: Icons.bolt_rounded,
                label: l10n.difficultyValue(task.difficultyLevel),
              ),
              if (task.estimatedTimeMinutes != null)
                _InfoPill(
                  icon: Icons.timer_outlined,
                  label: l10n.estimatedTimeMinutes(task.estimatedTimeMinutes!),
                ),
              if (task.antiFatigueEnabled)
                _InfoPill(
                  icon: Icons.self_improvement_rounded,
                  label: l10n.antiFatigueLabel,
                ),
              _InfoPill(
                icon: Icons.sync_rounded,
                label: l10n.updatedAtLabel(
                  DateFormatters.shortDateTime(task.updatedAt, l10n: l10n),
                ),
                ),
                if (task.reminder != null)
                  _InfoPill(
                    icon: Icons.notifications_active_outlined,
                    label: _reminderLabel(task.reminder!, l10n),
                  ),
              ],
            ),
            if (task.reminder?.escalatedToParent == true) ...<Widget>[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Text(
                  task.reminder?.parentAlertMessage ??
                      l10n.parentEscalationTriggered,
                  style: TextStyle(
                    color: Colors.red.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                TextButton.icon(
                  onPressed: isBusy ? null : () => _editTask(context, ref),
                  icon: const Icon(Icons.edit_rounded),
                  label: Text(l10n.edit),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: isBusy ? null : () => _deleteTask(context, ref),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(l10n.deleteTask),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editTask(BuildContext context, WidgetRef ref) async {
    final TaskFormResult? result = await showDialog<TaskFormResult>(
      context: context,
      builder: (BuildContext context) => TaskFormDialog(initialTask: task),
    );

    if (result == null) {
      return;
    }

    await ref.read(taskMutationControllerProvider.notifier).updateTask(
          id: task.id,
          title: result.title,
          description: result.description,
          status: result.status,
          dueAt: result.dueAt,
          reminderEnabled: result.reminderEnabled,
          remindAfterHours: result.remindAfterHours,
          maxMissedCount: result.maxMissedCount,
          difficultyLevel: result.difficultyLevel,
          estimatedTimeMinutes: result.estimatedTimeMinutes,
          antiFatigueEnabled: result.antiFatigueEnabled,
        );
  }

  Future<void> _deleteTask(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.deleteTaskTitle),
          content: Text(l10n.deleteTaskMessage(task.title)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.deleteTask),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await ref.read(taskMutationControllerProvider.notifier).deleteTask(task.id);
  }

  String _reminderLabel(TaskReminder reminder, AppLocalizations l10n) {
    if (!reminder.isEnabled) {
      return l10n.remindersPaused;
    }

    if (reminder.escalatedToParent) {
      return l10n.reminderEscalated(reminder.missedCount);
    }

    return l10n.reminderSchedule(
      reminder.remindAfterHours,
      reminder.maxMissedCount,
    );
  }
}

class _TaskMetricCard extends StatelessWidget {
  const _TaskMetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: SizedBox(
          width: 180,
          child: Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(value, style: theme.textTheme.titleLarge),
                  Text(label),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final Color background = switch (status) {
      TaskStatus.completed => Colors.green.shade100,
      TaskStatus.inProgress => Colors.blue.shade100,
      TaskStatus.overdue => Colors.red.shade100,
      TaskStatus.pending => Colors.amber.shade100,
    };

    final Color foreground = switch (status) {
      TaskStatus.completed => Colors.green.shade900,
      TaskStatus.inProgress => Colors.blue.shade900,
      TaskStatus.overdue => Colors.red.shade900,
      TaskStatus.pending => Colors.orange.shade900,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label(l10n),
        style: TextStyle(color: foreground, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
