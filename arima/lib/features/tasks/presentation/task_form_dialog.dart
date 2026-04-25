import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/date_formatters.dart';
import '../domain/task_item.dart';
import '../domain/task_status.dart';

class TaskFormResult {
  const TaskFormResult({
    required this.title,
    required this.description,
    required this.status,
    required this.dueAt,
    required this.reminderEnabled,
    required this.remindAfterHours,
    required this.maxMissedCount,
    required this.difficultyLevel,
    required this.estimatedTimeMinutes,
    required this.antiFatigueEnabled,
  });

  final String title;
  final String? description;
  final TaskStatus status;
  final DateTime? dueAt;
  final bool reminderEnabled;
  final int remindAfterHours;
  final int maxMissedCount;
  final int difficultyLevel;
  final int? estimatedTimeMinutes;
  final bool antiFatigueEnabled;
}

class TaskFormDialog extends StatefulWidget {
  const TaskFormDialog({
    this.initialTask,
    super.key,
  });

  final TaskItem? initialTask;

  @override
  State<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<TaskFormDialog> with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _remindAfterHoursController;
  late final TextEditingController _maxMissedCountController;
  late final TextEditingController _estimatedTimeController;
  late TaskStatus _status;
  DateTime? _dueAt;
  bool _reminderEnabled = true;
  int _difficultyLevel = 2;
  bool _antiFatigueEnabled = false;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTask?.title ?? '');
    _descriptionController = TextEditingController(text: widget.initialTask?.description ?? '');
    _remindAfterHoursController = TextEditingController(
      text: (widget.initialTask?.reminder?.remindAfterHours ?? 6).toString(),
    );
    _maxMissedCountController = TextEditingController(
      text: (widget.initialTask?.reminder?.maxMissedCount ?? 3).toString(),
    );
    _estimatedTimeController = TextEditingController(
      text: (widget.initialTask?.estimatedTimeMinutes ?? '').toString(),
    );
    _status = widget.initialTask?.status ?? TaskStatus.pending;
    _dueAt = widget.initialTask?.dueAt;
    _reminderEnabled = widget.initialTask?.reminder?.isEnabled ?? true;
    _difficultyLevel = widget.initialTask?.difficultyLevel ?? 2;
    _antiFatigueEnabled = widget.initialTask?.antiFatigueEnabled ?? false;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _remindAfterHoursController.dispose();
    _maxMissedCountController.dispose();
    _estimatedTimeController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.initialTask != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: 460,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isEditing ? Icons.edit_rounded : Icons.add_task_rounded,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing ? l10n.editTask : l10n.newTask,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              isEditing
                                  ? l10n.updateTaskDetails
                                  : l10n.createNewTask,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _titleController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.taskTitle,
                      hintText: l10n.taskTitleHint,
                      prefixIcon: const Icon(Icons.title_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.titleRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    minLines: 2,
                    decoration: InputDecoration(
                      labelText: l10n.descriptionOptional,
                      hintText: l10n.descriptionHint,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 48),
                        child: Icon(Icons.notes_rounded),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<TaskStatus>(
                    initialValue: _status,
                    decoration: InputDecoration(
                      labelText: l10n.status,
                      prefixIcon: const Icon(Icons.flag_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    items: TaskStatus.values
                        .map(
                          (TaskStatus status) => DropdownMenuItem<TaskStatus>(
                            value: status,
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _getStatusColor(status),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(status.label(l10n)),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (TaskStatus? status) {
                      if (status != null) {
                        setState(() => _status = status);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDifficultySection(theme),
                  const SizedBox(height: 16),
                  _buildTimingSection(theme),
                  const SizedBox(height: 16),
                  _buildFatigueSection(theme),
                  const SizedBox(height: 16),
                  _buildDeadlinePicker(theme),
                  const SizedBox(height: 20),
                  _buildReminderSection(theme),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(l10n.cancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(isEditing ? l10n.updateTask : l10n.createTask),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Colors.blue;
      case TaskStatus.inProgress:
        return Colors.orange;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.overdue:
        return Colors.red;
    }
  }

  Widget _buildDeadlinePicker(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Text(
                l10n.deadline,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 18,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _dueAt == null
                            ? l10n.noDeadlineSet
                            : DateFormatters.shortDateTime(_dueAt, l10n: l10n),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _dueAt == null
                              ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                              : null,
                          fontWeight: _dueAt != null ? FontWeight.w500 : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (_dueAt != null)
                IconButton(
                  onPressed: () => setState(() => _dueAt = null),
                  icon: Icon(
                    Icons.clear_rounded,
                    color: theme.colorScheme.error,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.errorContainer,
                  ),
                ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: _pickDueDate,
                icon: Icon(
                  Icons.edit_calendar_rounded,
                  color: theme.colorScheme.primary,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.primaryContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReminderSection(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _reminderEnabled
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _reminderEnabled
              ? theme.colorScheme.primary.withValues(alpha: 0.2)
              : theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_active_rounded,
                size: 20,
                color: _reminderEnabled
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.smartReminders,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch(
                value: _reminderEnabled,
                onChanged: (value) {
                  setState(() => _reminderEnabled = value);
                },
              ),
            ],
          ),
          if (_reminderEnabled) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _remindAfterHoursController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: l10n.remindEvery,
                      suffixText: l10n.hours,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    validator: (String? value) {
                      if (!_reminderEnabled) return null;
                      final int? parsed = int.tryParse(value ?? '');
                      if (parsed == null || parsed < 1 || parsed > 72) {
                        return l10n.reminderHoursRange;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _maxMissedCountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: l10n.escalateAfter,
                      suffixText: l10n.misses,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    validator: (String? value) {
                      if (!_reminderEnabled) return null;
                      final int? parsed = int.tryParse(value ?? '');
                      if (parsed == null || parsed < 1 || parsed > 20) {
                        return l10n.reminderMissesRange;
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.reminderInfo,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDifficultySection(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rocket_launch_rounded, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Text(
                l10n.difficultyLabel,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                l10n.difficultyValue(_difficultyLevel),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          Slider(
            value: _difficultyLevel.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: _difficultyLevel.toString(),
            onChanged: (value) {
              setState(() => _difficultyLevel = value.round());
            },
          ),
          Text(
            l10n.difficultyHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingSection(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Text(
                l10n.estimatedTimeLabel,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _estimatedTimeController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.estimatedTimeHint,
              suffixText: l10n.minutes,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) {
                return null;
              }
              final parsed = int.tryParse(text);
              if (parsed == null || parsed < 1 || parsed > 480) {
                return l10n.estimatedTimeRange;
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFatigueSection(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      value: _antiFatigueEnabled,
      onChanged: (value) => setState(() => _antiFatigueEnabled = value),
      title: Text(l10n.antiFatigueLabel),
      subtitle: Text(l10n.antiFatigueHint),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      tileColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
    );
  }

  Future<void> _pickDueDate() async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(now.year - 1);
    final DateTime lastDate = DateTime(now.year + 5);

    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _dueAt ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (date == null || !mounted) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueAt ?? now),
    );
    if (time == null) return;

    setState(() {
      _dueAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _submit() {
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    Navigator.of(context).pop(
      TaskFormResult(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        status: _status,
        dueAt: _dueAt,
        reminderEnabled: _reminderEnabled,
        remindAfterHours: int.tryParse(_remindAfterHoursController.text.trim()) ?? 6,
        maxMissedCount: int.tryParse(_maxMissedCountController.text.trim()) ?? 3,
        difficultyLevel: _difficultyLevel,
        estimatedTimeMinutes: int.tryParse(_estimatedTimeController.text.trim()),
        antiFatigueEnabled: _antiFatigueEnabled,
      ),
    );
  }
}
