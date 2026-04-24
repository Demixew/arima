import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/api_exception.dart';
import '../data/teacher_repository.dart';
import '../application/teacher_controller.dart';
import '../domain/ai_task_draft.dart';
import '../domain/linked_student.dart';
import '../domain/task_submission.dart';
import '../domain/teacher_metrics.dart';

class TeacherHomePage extends ConsumerStatefulWidget {
  const TeacherHomePage({super.key});

  @override
  ConsumerState<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends ConsumerState<TeacherHomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final teacherState = ref.watch(teacherControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: teacherState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('${l10n.somethingWentWrong}: $error')),
        data: (state) => IndexedStack(
          index: _selectedIndex,
          children: [
            _StudentsTab(state: state),
            _AssignTaskTab(students: state.students),
            _SubmissionsTab(
              submissions: state.pendingSubmissions,
              students: state.students,
            ),
            _StatsTab(metrics: state.metrics),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.people_outline),
            selectedIcon: const Icon(Icons.people),
            label: l10n.studentsTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.assignment_add),
            selectedIcon: const Icon(Icons.assignment_add),
            label: l10n.assignTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.inbox_outlined),
            selectedIcon: const Icon(Icons.inbox),
            label: l10n.submissionsTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: l10n.statsTab,
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _showLinkStudentDialog,
              icon: const Icon(Icons.person_add),
              label: Text(l10n.linkStudent),
            )
          : null,
    );
  }

  void _showLinkStudentDialog() {
    final l10n = AppLocalizations.of(context)!;
    final emailController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.linkStudent),
        content: TextField(
          controller: emailController,
          decoration: InputDecoration(
            labelText: l10n.studentEmail,
            hintText: l10n.studentEmailHint,
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) {
                return;
              }

              Navigator.pop(context);
              await ref.read(teacherControllerProvider.notifier).linkStudent(email);
            },
            child: Text(l10n.link),
          ),
        ],
      ),
    );
  }
}

class _StudentsTab extends ConsumerWidget {
  const _StudentsTab({required this.state});

  final TeacherState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (state.students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: theme.colorScheme.primary.withAlpha(100),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noStudentsLinkedYet,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tapToLinkStudent,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(153),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.students.length,
      itemBuilder: (context, index) {
        final student = state.students[index];
        return _StudentCard(student: student);
      },
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.student});

  final LinkedStudent student;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outline.withAlpha(26)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    student.studentName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.studentName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        student.studentEmail,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(153),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(student.linkStatus, theme)
                        .withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(student.linkStatus, l10n).toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(student.linkStatus, theme),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  icon: Icons.assignment_outlined,
                  label: l10n.assigned,
                  value: student.assignedTasksCount.toString(),
                  color: theme.colorScheme.primary,
                ),
                _StatItem(
                  icon: Icons.check_circle_outline,
                  label: l10n.submitted,
                  value: student.submittedCount.toString(),
                  color: Colors.green,
                ),
                _StatItem(
                  icon: Icons.grade_outlined,
                  label: l10n.graded,
                  value: student.gradedCount.toString(),
                  color: Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      default:
        return theme.colorScheme.primary;
    }
  }

  String _statusLabel(String status, AppLocalizations l10n) {
    switch (status.toLowerCase()) {
      case 'active':
        return l10n.statusActive;
      case 'inactive':
        return l10n.statusInactive;
      default:
        return status;
    }
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color.withAlpha(180),
          ),
        ),
      ],
    );
  }
}

class _AssignTaskTab extends ConsumerStatefulWidget {
  const _AssignTaskTab({required this.students});

  final List<LinkedStudent> students;

  @override
  ConsumerState<_AssignTaskTab> createState() => _AssignTaskTabState();
}

class _AssignTaskTabState extends ConsumerState<_AssignTaskTab> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _aiPromptController = TextEditingController();
  int? _selectedStudentId;
  DateTime? _dueAt;
  bool _requiresSubmission = false;
  bool _isLoading = false;
  bool _isGenerating = false;
  AITaskDraft? _draft;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _aiPromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (widget.students.isEmpty) {
      return Center(
        child: Text(
          l10n.linkStudentsFirst,
          style: theme.textTheme.titleMedium,
        ),
      );
    }

    final canSubmit = !_isLoading &&
        _selectedStudentId != null &&
        _titleController.text.trim().isNotEmpty;
    final canGenerate = !_isGenerating &&
        _selectedStudentId != null &&
        _aiPromptController.text.trim().isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.assignNewTask,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.createTaskForStudent,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(153),
            ),
          ),
          const SizedBox(height: 20),
          _buildAiCard(theme, l10n, canGenerate),
          const SizedBox(height: 24),
          DropdownButtonFormField<int>(
            initialValue: _selectedStudentId,
            decoration: InputDecoration(
              labelText: l10n.selectStudent,
              filled: true,
              fillColor:
                  theme.colorScheme.surfaceContainerHighest.withAlpha(100),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            items: widget.students.map((student) {
              return DropdownMenuItem<int>(
                value: student.studentId,
                child: Text(student.studentName),
              );
            }).toList(),
            onChanged: (value) => setState(() {
              _selectedStudentId = value;
              _draft = null;
            }),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: l10n.taskTitle,
              filled: true,
              fillColor:
                  theme.colorScheme.surfaceContainerHighest.withAlpha(100),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.descriptionOptional,
              filled: true,
              fillColor:
                  theme.colorScheme.surfaceContainerHighest.withAlpha(100),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickDueDate,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.dueDateOptional,
                filled: true,
                fillColor:
                    theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _dueAt == null
                        ? l10n.selectDate
                        : '${_dueAt!.day}/${_dueAt!.month}/${_dueAt!.year} '
                            '${_dueAt!.hour.toString().padLeft(2, '0')}:'
                            '${_dueAt!.minute.toString().padLeft(2, '0')}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(l10n.requiresSubmission),
            subtitle: Text(l10n.studentMustSubmit),
            value: _requiresSubmission,
            onChanged: (value) => setState(() => _requiresSubmission = value),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            tileColor: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: canSubmit ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.assignTask,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.send),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiCard(
    ThemeData theme,
    AppLocalizations l10n,
    bool canGenerate,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Text(
                l10n.aiAssistant,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _aiPromptController,
            minLines: 2,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.aiTaskPromptLabel,
              hintText: l10n.aiTaskPromptHint,
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: canGenerate ? _generateDraft : null,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    _isGenerating ? l10n.generatingDraft : l10n.generateWithAi,
                  ),
                ),
              ),
            ],
          ),
          if (_draft != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.aiDraftReady,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.aiModelLabel(_draft!.model),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _draft!.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(_draft!.description),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _applyDraft,
                      icon: const Icon(Icons.download_done),
                      label: Text(l10n.applyAiDraft),
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

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null || !mounted) {
      return;
    }

    setState(() {
      _dueAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isLoading = true);
    try {
      await ref.read(teacherControllerProvider.notifier).assignTask(
            studentId: _selectedStudentId!,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            dueAt: _dueAt,
            requiresSubmission: _requiresSubmission,
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _selectedStudentId = null;
        _titleController.clear();
        _descriptionController.clear();
        _dueAt = null;
        _requiresSubmission = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.taskAssignedSuccess)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.somethingWentWrong}: $error')),
      );
    }
  }

  Future<void> _generateDraft() async {
    final l10n = AppLocalizations.of(context)!;
    final studentId = _selectedStudentId;
    final prompt = _aiPromptController.text.trim();

    if (studentId == null || prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aiPromptRequired)),
      );
      return;
    }

    setState(() => _isGenerating = true);
    try {
      final draft = await ref.read(teacherRepositoryProvider).generateTaskDraft(
            studentId: studentId,
            prompt: prompt,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _draft = draft;
        _isGenerating = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is ApiException
          ? error.message
          : '${l10n.somethingWentWrong}: $error';
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _applyDraft() {
    final draft = _draft;
    if (draft == null) {
      return;
    }

    setState(() {
      _titleController.text = draft.title;
      _descriptionController.text = draft.description;
      _requiresSubmission = draft.requiresSubmission;
    });
  }
}

class _SubmissionsTab extends StatelessWidget {
  const _SubmissionsTab({
    required this.submissions,
    required this.students,
  });

  final List<TaskSubmission> submissions;
  final List<LinkedStudent> students;

  String _getStudentName(int studentId, AppLocalizations l10n) {
    try {
      return students.firstWhere((s) => s.studentId == studentId).studentName;
    } catch (_) {
      return l10n.unknownStudent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (submissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: theme.colorScheme.primary.withAlpha(100),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noPendingSubmissions,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.studentSubmissionsWillAppearHere,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(153),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: submissions.length,
      itemBuilder: (context, index) {
        final submission = submissions[index];
        return _SubmissionCard(
          submission: submission,
          studentName: _getStudentName(submission.studentId, l10n),
        );
      },
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  const _SubmissionCard({
    required this.submission,
    required this.studentName,
  });

  final TaskSubmission submission;
  final String studentName;

  String _formatDate(DateTime dt, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return l10n.justNow;
      }
      return l10n.hoursAgo(diff.inHours);
    }

    if (diff.inDays == 1) {
      return l10n.yesterday;
    }

    return l10n.daysAgo(diff.inDays);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outline.withAlpha(26)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Text(
                    studentName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${l10n.task} #${submission.taskId}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(153),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l10n.statusPending.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (submission.submissionText != null &&
                submission.submissionText!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Text(
                '${l10n.submission}:',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withAlpha(180),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                submission.submissionText!,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${l10n.submitted} ${_formatDate(submission.submittedAt, l10n)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(153),
                  ),
                ),
                Consumer(
                  builder: (context, ref, child) {
                    return FilledButton.icon(
                      onPressed: () => _showGradeDialog(context, ref, submission),
                      icon: const Icon(Icons.grade, size: 18),
                      label: Text(l10n.gradeLabel),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showGradeDialog(
    BuildContext context,
    WidgetRef ref,
    TaskSubmission submission,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final gradeController = TextEditingController();
    final feedbackController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.gradeForStudent(studentName)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              initialValue: int.tryParse(gradeController.text),
              decoration: InputDecoration(
                labelText: l10n.gradeRange,
                hintText: l10n.selectGrade,
              ),
              items: [1, 2, 3, 4, 5].map((grade) {
                return DropdownMenuItem<int>(
                  value: grade,
                  child: Text('$grade'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  gradeController.text = value.toString();
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: feedbackController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.feedbackOptional,
                hintText: l10n.enterFeedback,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final grade = int.tryParse(gradeController.text);
              if (grade == null || grade < 1 || grade > 5) {
                return;
              }

              Navigator.pop(context);
              await ref.read(teacherControllerProvider.notifier).gradeSubmission(
                    submissionId: submission.id,
                    grade: grade,
                    feedback: feedbackController.text.trim().isEmpty
                        ? null
                        : feedbackController.text.trim(),
                  );
            },
            child: Text(l10n.submitGrade),
          ),
        ],
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  const _StatsTab({this.metrics});

  final TeacherMetrics? metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (metrics == null) {
      return Center(child: Text(l10n.noMetricsAvailable));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.teacherDashboard,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _MetricCard(
            icon: Icons.people,
            label: l10n.totalStudents,
            value: metrics!.totalStudents.toString(),
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          _MetricCard(
            icon: Icons.assignment,
            label: l10n.assignedTasks,
            value: metrics!.totalAssignedTasks.toString(),
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _MetricCard(
            icon: Icons.check_circle,
            label: l10n.submissionsReceived,
            value: metrics!.totalSubmissions.toString(),
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _MetricCard(
            icon: Icons.pending_actions,
            label: l10n.pendingGrading,
            value: metrics!.pendingGrading.toString(),
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _MetricCard(
            icon: Icons.grade,
            label: l10n.averageGrade,
            value: metrics!.avgGrade.toStringAsFixed(1),
            color: Colors.purple,
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outline.withAlpha(26)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(153),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
