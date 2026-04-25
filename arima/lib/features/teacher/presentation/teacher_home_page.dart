import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/date_formatters.dart';
import '../../tasks/domain/task_review_mode.dart';
import '../data/teacher_repository.dart';
import '../application/teacher_controller.dart';
import '../domain/ai_status.dart';
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
        data: _buildTab,
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

  Widget _buildTab(TeacherState state) {
    switch (_selectedIndex) {
      case 0:
        return _StudentsTab(state: state);
      case 1:
        return _AssignTaskTab(students: state.students, aiStatus: state.aiStatus);
      case 2:
        return _SubmissionsTab(
          submissions: state.pendingSubmissions,
          students: state.students,
        );
      case 3:
        return _StatsTab(metrics: state.metrics);
      default:
        return const SizedBox.shrink();
    }
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

    final rankedStudents = [...state.students]
      ..sort((a, b) => b.riskScore.compareTo(a.riskScore));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _RiskRadarCard(students: rankedStudents),
        const SizedBox(height: 12),
        ...rankedStudents.map((student) => _StudentCard(student: student)),
      ],
    );
  }
}

class _StudentCard extends ConsumerWidget {
  const _StudentCard({required this.student});

  final LinkedStudent student;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final metrics = student.metrics;

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
                _RiskBadge(
                  level: student.riskLevel,
                  score: student.riskScore,
                ),
                const SizedBox(width: 8),
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
            if (metrics?.gamification != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withAlpha(220),
                      theme.colorScheme.secondary.withAlpha(220),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${l10n.levelLabel} ${metrics!.gamification!.level}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            metrics.gamification!.rankTitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withAlpha(220),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${metrics.gamification!.totalXp} ${l10n.xpLabel}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _riskBackground(student.riskLevel),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.riskReasonLabel(student.riskReason),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (student.aiTrend?.trendSummary?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 6),
                    Text(
                      student.aiTrend!.trendSummary!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
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
                if (metrics?.totalFocusTimeMinutes != null)
                  _StatItem(
                    icon: Icons.timer_outlined,
                    label: l10n.minutes,
                    value: metrics!.totalFocusTimeMinutes.toString(),
                    color: Colors.blue,
                ),
              ],
            ),
            if (student.weeklyNarrative != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withAlpha(90),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.weeklyNarrative!.headline,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      student.weeklyNarrative!.summary,
                      style: theme.textTheme.bodySmall,
                    ),
                    if (student.weeklyNarrative!.nextFocus?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 8),
                      Text(
                        student.weeklyNarrative!.nextFocus!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showStudentTasksSheet(context, ref),
                  icon: const Icon(Icons.assignment_outlined, size: 18),
                  label: Text(l10n.viewTasks),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    final state = ref.read(teacherControllerProvider).valueOrNull;
                    if (state == null) return;
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => Scaffold(
                          appBar: AppBar(title: Text(student.studentName)),
                          body: _SubmissionsTab(
                            submissions: state.pendingSubmissions
                                .where((submission) => submission.studentId == student.studentId)
                                .toList(),
                            students: state.students,
                          ),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.inbox_outlined, size: 18),
                  label: Text(l10n.viewSubmissions),
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

  Color _riskBackground(String riskLevel) {
    switch (riskLevel) {
      case 'high':
        return Colors.red.shade50;
      case 'watch':
        return Colors.orange.shade50;
      default:
        return Colors.green.shade50;
    }
  }

  Future<void> _showStudentTasksSheet(BuildContext context, WidgetRef ref) async {
    await ref.read(teacherControllerProvider.notifier).loadStudentTasks(student.studentId);
    if (!context.mounted) {
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.82,
        child: Consumer(
          builder: (context, ref, child) {
            final state = ref.watch(teacherControllerProvider).valueOrNull;
            final tasks = state?.studentTasks ?? const <Map<String, dynamic>>[];
            return _StudentTasksSheet(
              studentName: student.studentName,
              tasks: tasks,
              onExtendDeadline: (taskId, currentDueAt) =>
                  _showExtendDeadlineDialog(
                context,
                ref,
                taskId: taskId,
                currentDueAt: currentDueAt,
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showExtendDeadlineDialog(
    BuildContext context,
    WidgetRef ref, {
    required int taskId,
    required DateTime? currentDueAt,
  }) async {
    final start = currentDueAt ?? DateTime.now().add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: start,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(start),
    );
    if (time == null || !context.mounted) {
      return;
    }
    final dueAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    await ref.read(teacherControllerProvider.notifier).extendTaskDeadline(
          taskId: taskId,
          dueAt: dueAt,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.deadlineUpdated)),
      );
    }
  }
}

class _RiskRadarCard extends StatelessWidget {
  const _RiskRadarCard({required this.students});

  final List<LinkedStudent> students;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final high = students.where((student) => student.riskLevel == 'high').length;
    final watch = students.where((student) => student.riskLevel == 'watch').length;
    final stable = students.where((student) => student.riskLevel == 'stable').length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.atRiskRadarTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.atRiskRadarSubtitle,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(icon: Icons.priority_high, label: '${l10n.riskNeedsAttention}: $high'),
              _MetaChip(icon: Icons.visibility_outlined, label: '${l10n.riskWatch}: $watch'),
              _MetaChip(icon: Icons.check_circle_outline, label: '${l10n.riskStable}: $stable'),
            ],
          ),
          if (students.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              l10n.highestPriorityLabel(
                students.first.studentName,
                students.first.riskReason,
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({
    required this.level,
    required this.score,
  });

  final String level;
  final int score;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (level) {
      case 'high':
        color = Colors.red;
        label = AppLocalizations.of(context)!.riskNeedsAttention;
        break;
      case 'watch':
        color = Colors.orange;
        label = AppLocalizations.of(context)!.riskWatch;
        break;
      default:
        color = Colors.green;
        label = AppLocalizations.of(context)!.riskStable;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label • $score',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _localizedTaskStatusLabel(String status, AppLocalizations l10n) {
  switch (status.toLowerCase()) {
    case 'pending':
      return l10n.statusPending;
    case 'in_progress':
      return l10n.statusInProgress;
    case 'completed':
      return l10n.statusCompleted;
    case 'overdue':
      return l10n.statusOverdue;
    case 'active':
      return l10n.statusActive;
    case 'inactive':
      return l10n.statusInactive;
    default:
      return status;
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

class _StudentTasksSheet extends StatelessWidget {
  const _StudentTasksSheet({
    required this.studentName,
    required this.tasks,
    required this.onExtendDeadline,
  });

  final String studentName;
  final List<Map<String, dynamic>> tasks;
  final Future<void> Function(int taskId, DateTime? currentDueAt) onExtendDeadline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.studentTasksTitle(studentName),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: tasks.isEmpty
                  ? Center(
                      child: Text(
                        l10n.noStudentTasksYet,
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : ListView.separated(
                      itemCount: tasks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        final dueAt = task['due_at'] == null
                            ? null
                            : DateTime.parse(task['due_at'] as String);
                        final rescuePlan = task['rescue_plan'] as Map<String, dynamic>?;
                        final isChallenge = task['is_challenge'] as bool? ?? false;
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        task['title'] as String? ?? l10n.untitledTask,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (isChallenge)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade50,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          l10n.challengeXpLabel(
                                            AppLocalizations.of(context)!.weeklyChallengeTitle,
                                            task['challenge_bonus_xp'] as int? ?? 0,
                                          ),
                                          style: TextStyle(
                                            color: Colors.amber.shade900,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if ((task['description'] as String?)?.isNotEmpty ?? false) ...[
                                  const SizedBox(height: 6),
                                  Text(task['description'] as String),
                                ],
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _MetaChip(
                                      icon: Icons.flag_outlined,
                                      label: _localizedTaskStatusLabel(
                                        task['status'] as String? ?? 'pending',
                                        l10n,
                                      ),
                                    ),
                                    if (dueAt != null)
                                      _MetaChip(
                                        icon: Icons.calendar_today_outlined,
                                        label: DateFormatters.shortDateTime(dueAt),
                                      ),
                                    if ((task['estimated_time_minutes'] as int?) != null)
                                      _MetaChip(
                                        icon: Icons.timer_outlined,
                                        label: l10n.shortMinutesLabel(
                                          task['estimated_time_minutes'] as int,
                                        ),
                                      ),
                                  ],
                                ),
                                if (rescuePlan != null) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.deadlineRescuePlanTitle,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        ...(rescuePlan['mini_steps'] as List<dynamic>? ?? const [])
                                            .take(2)
                                            .map(
                                              (step) => Padding(
                                                padding: const EdgeInsets.only(bottom: 4),
                                                child: Text('- $step'),
                                              ),
                                            ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: OutlinedButton.icon(
                                    onPressed: () => onExtendDeadline(
                                      task['id'] as int,
                                      dueAt,
                                    ),
                                    icon: const Icon(Icons.schedule_outlined, size: 18),
                                    label: Text(l10n.extendDeadline),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignTaskTab extends ConsumerStatefulWidget {
  const _AssignTaskTab({required this.students, required this.aiStatus});

  final List<LinkedStudent> students;
  final AiStatus? aiStatus;

  @override
  ConsumerState<_AssignTaskTab> createState() => _AssignTaskTabState();
}

class _AssignTaskTabState extends ConsumerState<_AssignTaskTab> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _aiPromptController = TextEditingController();
  final _evaluationCriteriaController = TextEditingController();
  final _aiEstimatedTimeController = TextEditingController();
  final _challengeTitleController = TextEditingController();
  int? _selectedStudentId;
  DateTime? _dueAt;
  bool _requiresSubmission = false;
  bool _isChallenge = false;
  int _challengeBonusXp = 40;
  String _challengeCategory = 'weekly_goal';
  TaskReviewMode _reviewMode = TaskReviewMode.teacherOnly;
  int _aiTargetDifficulty = 2;
  String? _selectedRubricPreset;
  bool _isLoading = false;
  bool _isGenerating = false;
  AITaskDraft? _draft;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _aiPromptController.dispose();
    _evaluationCriteriaController.dispose();
    _aiEstimatedTimeController.dispose();
    _challengeTitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final rubricPresets = _rubricPresets(l10n);

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
        _aiPromptController.text.trim().isNotEmpty &&
        (widget.aiStatus == null ||
            widget.aiStatus!.mode != 'external' ||
            widget.aiStatus!.ready);

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
          _buildAiCard(theme, l10n, canGenerate, widget.aiStatus),
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
          Text(
            l10n.rubricTemplatesTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: rubricPresets.entries.map((entry) {
              final selected = _selectedRubricPreset == entry.key;
              return ChoiceChip(
                label: Text(_rubricPresetLabel(entry.key)),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    _selectedRubricPreset = entry.key;
                    _evaluationCriteriaController.text = entry.value;
                  });
                },
              );
            }).toList(),
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
            onChanged: (value) => setState(() {
              _requiresSubmission = value;
              if (!value) {
                _reviewMode = TaskReviewMode.teacherOnly;
                _evaluationCriteriaController.clear();
              }
            }),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            tileColor: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
          ),
          if (_requiresSubmission) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<TaskReviewMode>(
              initialValue: _reviewMode,
              decoration: InputDecoration(
                labelText: l10n.reviewModeLabel,
                filled: true,
                fillColor:
                    theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              items: TaskReviewMode.values
                  .map(
                    (mode) => DropdownMenuItem<TaskReviewMode>(
                      value: mode,
                      child: Text(mode.label(l10n)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() => _reviewMode = value);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _evaluationCriteriaController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.evaluationCriteriaLabel,
                hintText: l10n.evaluationCriteriaHint,
                filled: true,
                fillColor:
                    theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(l10n.weeklyChallengeTitle),
            subtitle: Text(l10n.weeklyChallengeSubtitle),
            value: _isChallenge,
            onChanged: (value) => setState(() {
              _isChallenge = value;
              if (value && _challengeTitleController.text.trim().isEmpty) {
                _challengeTitleController.text = l10n.weeklyChallengeTitle;
              }
            }),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            tileColor: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
          ),
          if (_isChallenge) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _challengeTitleController,
              decoration: InputDecoration(
                labelText: l10n.challengeTitleLabel,
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
            DropdownButtonFormField<String>(
              initialValue: _challengeCategory,
              decoration: InputDecoration(
                labelText: l10n.challengeCategoryLabel,
                filled: true,
                fillColor:
                    theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              items: [
                DropdownMenuItem(value: 'weekly_goal', child: Text(l10n.challengeCategoryWeeklyGoal)),
                DropdownMenuItem(value: 'punctuality', child: Text(l10n.challengeCategoryPunctuality)),
                DropdownMenuItem(value: 'writing_quality', child: Text(l10n.challengeCategoryWritingQuality)),
                DropdownMenuItem(value: 'focus_time', child: Text(l10n.challengeCategoryFocusTime)),
                DropdownMenuItem(value: 'streak', child: Text(l10n.challengeCategoryStreak)),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _challengeCategory = value);
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _challengeBonusXp,
              decoration: InputDecoration(
                labelText: l10n.bonusXpLabel,
                filled: true,
                fillColor:
                    theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              items: const [20, 40, 60, 80, 100]
                  .map(
                    (value) => DropdownMenuItem<int>(
                      value: value,
                      child: Text(
                        '$value ${AppLocalizations.of(context)!.xpLabel}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _challengeBonusXp = value);
                }
              },
            ),
          ],
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
                          AppLocalizations.of(context)!.assignTask,
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
    AiStatus? aiStatus,
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
                l10n.aiHelperTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _AiStatusBanner(status: aiStatus),
          const SizedBox(height: 12),
          Text(
            l10n.aiHelperSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
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
                child: DropdownButtonFormField<int>(
                  initialValue: _aiTargetDifficulty,
                  decoration: InputDecoration(
                    labelText: l10n.difficultyLabel,
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: [1, 2, 3, 4, 5]
                      .map(
                        (value) => DropdownMenuItem<int>(
                          value: value,
                          child: Text(l10n.difficultyValue(value)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _aiTargetDifficulty = value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _aiEstimatedTimeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.estimatedTimeLabel,
                    suffixText: l10n.minutes,
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
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
                  const SizedBox(height: 4),
                  Text(
                    l10n.sourceLabel(_draft!.provider),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaChip(
                        icon: Icons.bolt_rounded,
                        label:
                            l10n.difficultyValue(_draft!.difficultyLevel),
                      ),
                      if (_draft!.estimatedTimeMinutes != null)
                        _MetaChip(
                          icon: Icons.timer_outlined,
                          label: l10n.estimatedTimeMinutes(
                            _draft!.estimatedTimeMinutes!,
                          ),
                        ),
                      if (_draft!.antiFatigueEnabled)
                        _MetaChip(
                          icon: Icons.self_improvement_rounded,
                          label: l10n.antiFatigueLabel,
                        ),
                    ],
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
            difficultyLevel: _aiTargetDifficulty,
            estimatedTimeMinutes:
                int.tryParse(_aiEstimatedTimeController.text.trim()),
            antiFatigueEnabled: _draft?.antiFatigueEnabled ?? false,
            isChallenge: _isChallenge,
            challengeTitle: _isChallenge
                ? _challengeTitleController.text.trim().isEmpty
                    ? null
                    : _challengeTitleController.text.trim()
                : null,
            challengeCategory: _isChallenge ? _challengeCategory : null,
            challengeBonusXp: _isChallenge ? _challengeBonusXp : 0,
            reviewMode: _requiresSubmission
                ? _reviewMode
                : TaskReviewMode.teacherOnly,
            evaluationCriteria: _requiresSubmission &&
                    _evaluationCriteriaController.text.trim().isNotEmpty
                ? _evaluationCriteriaController.text.trim()
                : null,
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _selectedStudentId = null;
        _titleController.clear();
        _descriptionController.clear();
        _evaluationCriteriaController.clear();
        _aiPromptController.clear();
        _aiEstimatedTimeController.clear();
        _challengeTitleController.clear();
        _dueAt = null;
        _requiresSubmission = false;
        _isChallenge = false;
        _challengeBonusXp = 40;
        _challengeCategory = 'weekly_goal';
        _reviewMode = TaskReviewMode.teacherOnly;
        _aiTargetDifficulty = 2;
        _selectedRubricPreset = null;
        _draft = null;
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
    final rubricPresets = _rubricPresets(l10n);
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
            prompt: _selectedRubricPreset == null
                ? prompt
                : '$prompt\n\nEvaluation focus: ${rubricPresets[_selectedRubricPreset]}',
            difficultyLevel: _aiTargetDifficulty,
            estimatedTimeMinutes:
                int.tryParse(_aiEstimatedTimeController.text.trim()),
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
    final rubricPresets = _rubricPresets(AppLocalizations.of(context)!);

    setState(() {
      _titleController.text = draft.title;
      _descriptionController.text = draft.description;
      _requiresSubmission = draft.requiresSubmission;
      _reviewMode = TaskReviewMode.teacherOnly;
      _aiTargetDifficulty = draft.difficultyLevel;
      _aiEstimatedTimeController.text =
          draft.estimatedTimeMinutes?.toString() ?? '';
      if (_selectedRubricPreset != null) {
        _evaluationCriteriaController.text =
            rubricPresets[_selectedRubricPreset] ?? '';
      }
      if (!draft.requiresSubmission) {
        _reviewMode = TaskReviewMode.teacherOnly;
        _evaluationCriteriaController.clear();
      }
    });
  }

  String _rubricPresetLabel(String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'essay':
        return l10n.presetEssay;
      case 'short_answer':
        return l10n.presetShortAnswer;
      case 'math_explanation':
        return l10n.presetMathExplanation;
      case 'science_report':
        return l10n.presetScienceReport;
      case 'reading_response':
        return l10n.presetReadingResponse;
      case 'project_reflection':
        return l10n.presetProjectReflection;
      default:
        return key;
    }
  }

  Map<String, String> _rubricPresets(AppLocalizations l10n) {
    if (l10n.locale.languageCode == 'ru') {
      return <String, String>{
        'essay': 'Ясность, структура, аргументы, грамотность',
        'short_answer': 'Точность, полнота, объяснение',
        'math_explanation': 'Правильность, рассуждение, показ шагов',
        'science_report': 'Гипотеза, метод, доказательства, вывод',
        'reading_response': 'Понимание, интерпретация, опора на текст',
        'project_reflection': 'Осмысление, рефлексия, конкретные примеры, следующие шаги',
      };
    }
    return <String, String>{
      'essay': 'Clarity, structure, evidence, grammar',
      'short_answer': 'Accuracy, completeness, explanation',
      'math_explanation': 'Correctness, reasoning, showing steps',
      'science_report': 'Hypothesis, method, evidence, conclusion',
      'reading_response': 'Understanding, interpretation, evidence from text',
      'project_reflection': 'Insight, reflection, concrete examples, next steps',
    };
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

class _SubmissionCard extends StatefulWidget {
  const _SubmissionCard({
    required this.submission,
    required this.studentName,
  });

  final TaskSubmission submission;
  final String studentName;

  @override
  State<_SubmissionCard> createState() => _SubmissionCardState();
}

class _SubmissionCardState extends State<_SubmissionCard> {
  bool _expanded = false;

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

  bool get _canRunAiReview {
    final mode = widget.submission.reviewMode;
    return mode == TaskReviewMode.teacherAndAi || mode == TaskReviewMode.aiOnly;
  }

  bool get _isAiReviewPending => widget.submission.aiReviewStatus == 'pending';

  bool get _isAiReviewFailed => widget.submission.aiReviewStatus == 'failed';

  bool get _hasAiSuggestion =>
      widget.submission.aiGrade != null ||
      (widget.submission.aiFeedback?.isNotEmpty ?? false) ||
      widget.submission.aiCheckedAt != null;

  Color _statusColor(ThemeData theme) {
    if (widget.submission.isGraded) {
      return Colors.green;
    }
    if (_isAiReviewFailed) {
      return Colors.red;
    }
    if (_isAiReviewPending) {
      return theme.colorScheme.secondary;
    }
    if (_hasAiSuggestion) {
      return theme.colorScheme.primary;
    }
    return Colors.orange;
  }

  String _statusLabel(AppLocalizations l10n) {
    if (widget.submission.isGraded) {
      return l10n.graded;
    }
    if (_isAiReviewFailed) {
      return l10n.aiReviewFailedLabel;
    }
    if (_isAiReviewPending) {
      return l10n.aiReviewCheckingLabel;
    }
    if (_hasAiSuggestion) {
      return l10n.aiReviewCompleted;
    }
    return l10n.statusPending;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final submission = widget.submission;
    final studentName = widget.studentName;
    final taskLabel = submission.taskTitle ?? '${l10n.task} #${submission.taskId}';

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
                        taskLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(153),
                        ),
                      ),
                    ],
                  ),
                ),
                _AnimatedStatusPill(
                  label: _statusLabel(l10n).toUpperCase(),
                  color: _statusColor(theme),
                  isPulsing: _isAiReviewPending,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ReviewTimeline(
              submittedLabel: l10n.reviewTimelineSubmitted,
              aiCheckedLabel: l10n.reviewTimelineAiChecked,
              gradedLabel: l10n.reviewTimelineTeacherGraded,
              submittedSubtitle:
                  DateFormatters.shortDateTime(submission.submittedAt, l10n: l10n),
              aiCheckedSubtitle: submission.aiCheckedAt == null
                  ? null
                  : DateFormatters.shortDateTime(
                      submission.aiCheckedAt,
                      l10n: l10n,
                    ),
              gradedSubtitle: submission.gradedAt == null
                  ? null
                  : DateFormatters.shortDateTime(
                      submission.gradedAt,
                      l10n: l10n,
                    ),
              submittedDone: true,
              aiCheckedDone:
                  _hasAiSuggestion || _isAiReviewFailed || submission.isGraded,
              aiChecking: _isAiReviewPending,
              gradedDone: submission.isGraded,
              celebrateAiChecked: _hasAiSuggestion,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                label: Text(_expanded ? l10n.hideDetails : l10n.showDetails),
              ),
            ),
            if (_expanded) ...[
            if (submission.reviewMode != null ||
                (submission.evaluationCriteria?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (submission.reviewMode != null)
                    _MetaChip(
                      icon: Icons.rule_folder_outlined,
                      label:
                          '${l10n.reviewModeLabel}: ${submission.reviewMode!.label(l10n)}',
                    ),
                  if (submission.evaluationCriteria?.isNotEmpty ?? false)
                    _MetaChip(
                      icon: Icons.fact_check_outlined,
                      label:
                          '${l10n.evaluationCriteriaLabel}: ${submission.evaluationCriteria!}',
                    ),
                ],
              ),
            ],
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
            ] else ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Text(
                l10n.noSubmissionText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],
            if (_isAiReviewPending) ...[
              const SizedBox(height: 12),
              _ReviewPlaceholder(
                message: l10n.aiReviewRunningTeacher,
              ),
            ] else if (_isAiReviewFailed) ...[
              const SizedBox(height: 12),
              _ReviewPlaceholder(
                message: submission.aiReviewError?.isNotEmpty == true
                    ? l10n.aiReviewFailedTeacher(submission.aiReviewError!)
                    : l10n.aiReviewFailedTeacherFallback,
              ),
            ] else if (_hasAiSuggestion) ...[
              const SizedBox(height: 12),
              _ReviewPanel(
                title: l10n.aiSuggestionTitle,
                accentColor: theme.colorScheme.secondary,
                gradeLabel: l10n.aiSuggestedGrade,
                grade: submission.aiGrade,
                feedbackLabel: l10n.aiSuggestedFeedback,
                feedback: submission.aiFeedback,
                footer: submission.aiCheckedAt == null
                    ? null
                    : '${l10n.aiCheckedAtLabel(
                        DateFormatters.shortDateTime(
                          submission.aiCheckedAt,
                          l10n: l10n,
                        ),
                      )}${submission.aiProvider?.isNotEmpty == true ? ' • ${submission.aiProvider}' : ''}',
              ),
              if (submission.aiScorePercent != null ||
                  submission.aiConfidence != null ||
                  submission.aiRatingLabel?.isNotEmpty == true) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (submission.aiScorePercent != null)
                      _MetaChip(
                        icon: Icons.speed_outlined,
                        label: l10n.aiScoreDetailedLabel(
                          submission.aiScorePercent!,
                        ),
                      ),
                    if (submission.aiConfidence != null)
                      _MetaChip(
                        icon: Icons.verified_outlined,
                        label: l10n.confidenceDetailedLabel(
                          submission.aiConfidence!,
                        ),
                      ),
                    if (submission.aiRatingLabel?.isNotEmpty == true)
                      _MetaChip(
                        icon: Icons.workspace_premium_outlined,
                        label: submission.aiRatingLabel!,
                      ),
                  ],
                ),
              ],
              if (submission.aiStrengths.isNotEmpty) ...[
                const SizedBox(height: 10),
                _AiListPanel(
                  title: l10n.strengthsTitle,
                  accentColor: Colors.green,
                  items: submission.aiStrengths,
                ),
              ],
              if (submission.aiImprovements.isNotEmpty) ...[
                const SizedBox(height: 10),
                _AiListPanel(
                  title: l10n.nextStepsTitle,
                  accentColor: Colors.orange,
                  items: submission.aiImprovements,
                ),
              ],
              if (submission.aiRubric.isNotEmpty) ...[
                const SizedBox(height: 10),
                _AiRubricPanel(items: submission.aiRubric),
              ],
              if (submission.aiRiskFlags.isNotEmpty) ...[
                const SizedBox(height: 10),
                _AiListPanel(
                  title: l10n.reviewSignalsTitle,
                  accentColor: Colors.red,
                  items: submission.aiRiskFlags,
                ),
              ],
              if (submission.aiNextTask != null) ...[
                const SizedBox(height: 10),
                _AiNextTaskPanel(suggestion: submission.aiNextTask!),
                const SizedBox(height: 8),
                Consumer(
                  builder: (context, ref, child) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        onPressed: () async {
                          try {
                            await ref
                                .read(teacherControllerProvider.notifier)
                                .assignAiNextTask(submission.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.suggestedFollowupAssigned),
                                ),
                              );
                            }
                          } catch (error) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$error')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.assignment_turned_in_outlined, size: 18),
                        label: Text(l10n.assignSuggestedTask),
                      ),
                    );
                  },
                ),
              ],
            ] else if (_canRunAiReview) ...[
              const SizedBox(height: 12),
              _ReviewPlaceholder(message: l10n.aiReviewNeeded),
            ],
            if (submission.isGraded) ...[
              const SizedBox(height: 12),
              _ReviewPanel(
                title: l10n.finalTeacherDecision,
                accentColor: Colors.green,
                gradeLabel: l10n.gradeLabel,
                grade: submission.grade,
                feedbackLabel: l10n.feedbackOptional,
                feedback: submission.feedback,
                footer: submission.gradedAt == null
                    ? null
                    : DateFormatters.shortDateTime(submission.gradedAt, l10n: l10n),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 520;
                final actionButtons = Consumer(
                  builder: (context, ref, child) {
                    return OverflowBar(
                      alignment: MainAxisAlignment.end,
                      spacing: 8,
                      overflowSpacing: 8,
                      children: [
                        if (_canRunAiReview)
                          OutlinedButton.icon(
                            onPressed: _isAiReviewPending ? null : () async {
                              try {
                                await ref
                                    .read(teacherControllerProvider.notifier)
                                    .runAiReview(submission.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.aiReviewCompleted),
                                    ),
                                  );
                                }
                              } catch (error) {
                                final message = error is ApiException
                                    ? error.message
                                    : '${l10n.somethingWentWrong}: $error';
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(message)),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.auto_awesome, size: 18),
                            label: Text(l10n.runAiReview),
                          ),
                        FilledButton.icon(
                          onPressed: () =>
                              _showGradeDialog(context, ref, submission),
                          icon: const Icon(Icons.grade, size: 18),
                          label: Text(l10n.gradeLabel),
                        ),
                      ],
                    );
                  },
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n.submitted} ${_formatDate(submission.submittedAt, l10n)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(153),
                        ),
                      ),
                      const SizedBox(height: 8),
                      actionButtons,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${l10n.submitted} ${_formatDate(submission.submittedAt, l10n)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(153),
                        ),
                      ),
                    ),
                    actionButtons,
                  ],
                );
              },
            ),
            ],
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
    if (submission.aiGrade != null) {
      gradeController.text = submission.aiGrade.toString();
    }
    if (submission.aiFeedback?.isNotEmpty ?? false) {
      feedbackController.text = submission.aiFeedback!;
    }

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.gradeForStudent(widget.studentName)),
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
              try {
                await ref.read(teacherControllerProvider.notifier).gradeSubmission(
                      submissionId: submission.id,
                      grade: grade,
                      feedback: feedbackController.text.trim().isEmpty
                          ? null
                          : feedbackController.text.trim(),
                    );
              } catch (error) {
                if (context.mounted) {
                  final message = error is ApiException
                      ? error.message
                      : '${l10n.somethingWentWrong}: $error';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                }
              }
            },
            child: Text(l10n.submitGrade),
          ),
        ],
      ),
    );
  }
}

class _AiStatusBanner extends StatelessWidget {
  const _AiStatusBanner({required this.status});

  final AiStatus? status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (status == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          AppLocalizations.of(context)!.aiStatusLoading,
          style: theme.textTheme.bodySmall,
        ),
      );
    }

    final background = status!.ready
        ? Colors.green.withValues(alpha: 0.12)
        : Colors.red.withValues(alpha: 0.12);
    final accent = status!.ready ? Colors.green : Colors.red;
    final statusText = status!.provider == 'unknown'
        ? AppLocalizations.of(context)!.aiStatusUnavailable
        : (status!.ready
            ? AppLocalizations.of(context)!.aiReadyStatus(status!.providerLabel)
            : AppLocalizations.of(context)!.aiUnavailableStatus(status!.providerLabel));
    final modeText = status!.mode == 'external'
        ? AppLocalizations.of(context)!.aiModeExternal
        : status!.mode == 'builtin'
            ? AppLocalizations.of(context)!.aiModeBuiltin
            : AppLocalizations.of(context)!.aiModeUnavailable;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud, size: 18, color: accent),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context)!.modeLabel(modeText),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.providerValueLabel(status!.provider),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.modelValueLabel(
              status!.selectedModel.isEmpty
                  ? AppLocalizations.of(context)!.unknownValue
                  : status!.selectedModel,
            ),
            style: theme.textTheme.bodySmall,
          ),
          if (status!.detail.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              status!.detail,
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (status!.endpoint?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)!.endpointValueLabel(status!.endpoint!),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedStatusPill extends StatefulWidget {
  const _AnimatedStatusPill({
    required this.label,
    required this.color,
    required this.isPulsing,
  });

  final String label;
  final Color color;
  final bool isPulsing;

  @override
  State<_AnimatedStatusPill> createState() => _AnimatedStatusPillState();
}

class _AnimatedStatusPillState extends State<_AnimatedStatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _opacity = Tween<double>(begin: 0.45, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isPulsing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedStatusPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isPulsing && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: widget.color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        widget.label,
        style: TextStyle(
          color: widget.color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    if (!widget.isPulsing) {
      return child;
    }

    return FadeTransition(opacity: _opacity, child: child);
  }
}

class _ReviewTimeline extends StatelessWidget {
  const _ReviewTimeline({
    required this.submittedLabel,
    required this.aiCheckedLabel,
    required this.gradedLabel,
    this.submittedSubtitle,
    this.aiCheckedSubtitle,
    this.gradedSubtitle,
    required this.submittedDone,
    required this.aiCheckedDone,
    required this.aiChecking,
    required this.gradedDone,
    this.celebrateAiChecked = false,
  });

  final String submittedLabel;
  final String aiCheckedLabel;
  final String gradedLabel;
  final String? submittedSubtitle;
  final String? aiCheckedSubtitle;
  final String? gradedSubtitle;
  final bool submittedDone;
  final bool aiCheckedDone;
  final bool aiChecking;
  final bool gradedDone;
  final bool celebrateAiChecked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: _TimelineStep(
            label: submittedLabel,
            subtitle: submittedSubtitle,
            done: submittedDone,
            active: false,
            color: theme.colorScheme.primary,
          ),
        ),
        _TimelineConnector(done: aiCheckedDone || aiChecking),
        Expanded(
          child: _TimelineStep(
            label: aiCheckedLabel,
            subtitle: aiCheckedSubtitle,
            done: aiCheckedDone,
            active: aiChecking,
            color: theme.colorScheme.secondary,
            celebrate: celebrateAiChecked,
          ),
        ),
        _TimelineConnector(done: gradedDone),
        Expanded(
          child: _TimelineStep(
            label: gradedLabel,
            subtitle: gradedSubtitle,
            done: gradedDone,
            active: false,
            color: Colors.green,
          ),
        ),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.label,
    this.subtitle,
    required this.done,
    required this.active,
    required this.color,
    this.celebrate = false,
  });

  final String label;
  final String? subtitle;
  final bool done;
  final bool active;
  final Color color;
  final bool celebrate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedColor =
        done || active ? color : theme.colorScheme.outline.withValues(alpha: 0.45);
    final node = Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: done ? resolvedColor : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: resolvedColor, width: 2),
      ),
      child: done
          ? const Icon(Icons.check, size: 9, color: Colors.white)
          : null,
    );

    final timelineNode = _TimelineNode(
      isPulsing: active,
      child: node,
    );

    return Column(
      children: [
        if (celebrate && !active)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.82, end: 1),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: timelineNode,
          )
        else
          timelineNode,
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: done || active ? FontWeight.w700 : FontWeight.w500,
            color: resolvedColor,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ],
    );
  }
}

class _TimelineNode extends StatefulWidget {
  const _TimelineNode({
    required this.child,
    required this.isPulsing,
  });

  final Widget child;
  final bool isPulsing;

  @override
  State<_TimelineNode> createState() => _TimelineNodeState();
}

class _TimelineNodeState extends State<_TimelineNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scale = Tween<double>(begin: 1, end: 1.18).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isPulsing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _TimelineNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isPulsing && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPulsing) {
      return widget.child;
    }

    return ScaleTransition(scale: _scale, child: widget.child);
  }
}

class _TimelineConnector extends StatelessWidget {
  const _TimelineConnector({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18),
        color: done
            ? theme.colorScheme.primary.withValues(alpha: 0.45)
            : theme.colorScheme.outline.withValues(alpha: 0.18),
      ),
    );
  }
}

class _ReviewPlaceholder extends StatelessWidget {
  const _ReviewPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
        ),
      ),
    );
  }
}

class _ReviewPanel extends StatelessWidget {
  const _ReviewPanel({
    required this.title,
    required this.accentColor,
    required this.gradeLabel,
    required this.grade,
    required this.feedbackLabel,
    required this.feedback,
    this.footer,
  });

  final String title;
  final Color accentColor;
  final String gradeLabel;
  final int? grade;
  final String feedbackLabel;
  final String? feedback;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
          if (grade != null) ...[
            const SizedBox(height: 8),
            Text(
              '$gradeLabel: $grade',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (feedback?.isNotEmpty ?? false) ...[
            const SizedBox(height: 6),
            Text(
              '$feedbackLabel: $feedback',
              style: theme.textTheme.bodyMedium,
            ),
          ],
          if (footer != null) ...[
            const SizedBox(height: 8),
            Text(
              footer!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AiListPanel extends StatelessWidget {
  const _AiListPanel({
    required this.title,
    required this.accentColor,
    required this.items,
  });

  final String title;
  final Color accentColor;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: accentColor)),
                  Expanded(child: Text(item, style: theme.textTheme.bodyMedium)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiRubricPanel extends StatelessWidget {
  const _AiRubricPanel({required this.items});

  final List<AiRubricItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.aiRubricTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.criterion,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '${item.score}/${item.maxScore}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: item.maxScore == 0 ? 0 : item.score / item.maxScore,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  if (item.comment?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.comment!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiNextTaskPanel extends StatelessWidget {
  const _AiNextTaskPanel({required this.suggestion});

  final AiNextTaskSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.suggestedNextTaskTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            suggestion.title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            suggestion.prompt,
            style: theme.textTheme.bodyMedium,
          ),
          if (suggestion.focusReason?.isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            Text(
              suggestion.focusReason!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(
                icon: Icons.bolt_outlined,
                label: l10n.difficultyLevelLabel(suggestion.difficultyLevel),
              ),
              if (suggestion.estimatedTimeMinutes != null)
                _MetaChip(
                  icon: Icons.timer_outlined,
                  label: l10n.shortMinutesLabel(
                    suggestion.estimatedTimeMinutes!,
                  ),
                ),
            ],
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
