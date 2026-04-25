import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/language_selector.dart';
import '../../auth/application/auth_controller.dart';
import '../../metrics/application/student_metrics_controller.dart';
import '../../metrics/domain/gamification_profile.dart';
import '../../metrics/domain/user_metrics.dart';
import '../../tasks/application/task_list_controller.dart';
import '../../tasks/application/task_mutation_controller.dart';
import '../../tasks/application/study_plan_controller.dart';
import '../../tasks/domain/task_item.dart';
import '../../tasks/domain/task_review_mode.dart';
import '../../tasks/domain/task_status.dart';
import '../../tasks/domain/study_plan.dart';
import '../../tasks/presentation/task_form_dialog.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({this.title, super.key});

  final String? title;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;

  late final AnimationController _fabController;
  late final Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    );
    _fabController.forward();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.scaffoldBackgroundColor,
              Colors.white,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -40,
              child: _BackgroundGlow(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                size: 280,
              ),
            ),
            Positioned(
              top: 180,
              left: -70,
              child: _BackgroundGlow(
                color: theme.colorScheme.secondary.withValues(alpha: 0.10),
                size: 220,
              ),
            ),
            SafeArea(
              child: _buildBody(theme),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildNavigationBar(theme),
      floatingActionButton: _selectedIndex == 0
          ? ScaleTransition(
              scale: _fabAnimation,
              child: FloatingActionButton.extended(
                onPressed: _showAddTaskDialog,
                icon: const Icon(Icons.add),
                label: Text(l10n.addTask),
                elevation: 4,
              ),
            )
          : null,
    );
  }

  Widget _buildNavigationBar(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: _selectedIndex,
        backgroundColor: Colors.transparent,
        elevation: 0,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.checklist_outlined),
            selectedIcon:
                Icon(Icons.checklist, color: theme.colorScheme.primary),
            label: l10n.tasksTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: theme.colorScheme.primary),
            label: l10n.profileTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon:
                Icon(Icons.bar_chart, color: theme.colorScheme.primary),
            label: l10n.statsTab,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final tasksAsync = ref.watch(taskListControllerProvider);
    final metricsAsync = ref.watch(studentMetricsControllerProvider);
    final studyPlanAsync = ref.watch(studyPlanControllerProvider);

    return CustomScrollView(
      slivers: [
        _buildAppBar(theme),
        switch (_selectedIndex) {
          0 => tasksAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SliverFillRemaining(
                child: _buildErrorState(theme, error),
              ),
              data: (tasks) => _buildDashboardSliver(
                theme,
                tasks: tasks,
                metrics: metricsAsync.valueOrNull,
                studyPlan: studyPlanAsync.valueOrNull,
              ),
            ),
          1 => SliverFillRemaining(
              child: _buildProfile(theme, metricsAsync.valueOrNull),
            ),
          2 => tasksAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => SliverFillRemaining(
                child: Center(child: Text(l10n.errorLoadingStats)),
              ),
              data: (tasks) =>
                  SliverFillRemaining(
                    child: _buildStats(theme, tasks, metricsAsync.valueOrNull),
                  ),
            ),
          _ => const SliverFillRemaining(child: SizedBox.shrink()),
        },
      ],
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final session = ref.watch(authControllerProvider).valueOrNull;
    final userName = session?.user.fullName.split(' ').first ?? l10n.roleStudent;

    return SliverAppBar(
      expandedHeight: 88,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 20,
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title ?? l10n.appTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${l10n.hello}, $userName',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.language_outlined),
          onPressed: _showLanguageDialog,
          tooltip: l10n.language,
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            ref.read(taskListControllerProvider.notifier).refresh();
            ref.read(studentMetricsControllerProvider.notifier).refresh();
            ref.read(studyPlanControllerProvider.notifier).refresh();
          },
          tooltip: l10n.refresh,
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          tooltip: l10n.logout,
        ),
      ],
    );
  }

  Widget _buildErrorState(ThemeData theme, Object error) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.somethingWentWrongRetry,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () =>
                ref.read(taskListControllerProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            label: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.task_alt,
                size: 80,
                color: theme.colorScheme.primary.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            l10n.noTasksYet,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.addFirstTaskHint,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(ThemeData theme, TaskItem task, int index) {
    final l10n = AppLocalizations.of(context)!;
    final isCompleted = task.status == TaskStatus.completed;
    final isOverdue = task.dueAt != null &&
        task.dueAt!.isBefore(DateTime.now()) &&
        !isCompleted;

    final statusColor = isCompleted
        ? Colors.green
        : isOverdue
            ? Colors.red
            : theme.colorScheme.primary;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Dismissible(
        key: Key('task-${task.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) => _confirmDelete(task),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.error,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(
            Icons.delete_outline,
            color: Colors.white,
            size: 28,
          ),
        ),
        child: Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: statusColor.withValues(alpha: 0.12),
            ),
          ),
          child: InkWell(
            onTap: () => _showTaskDetails(task),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildStatusCheckbox(task, isCompleted),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: isCompleted
                                    ? theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5)
                                    : null,
                              ),
                            ),
                            if (task.description != null &&
                                task.description!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                task.description!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.64),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      _buildStatusBadge(theme, task.status, statusColor, l10n),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatusMetaChip(
                        icon: Icons.bolt_rounded,
                        label: l10n.difficultyValue(task.difficultyLevel),
                      ),
                      if (task.estimatedTimeMinutes != null)
                        _StatusMetaChip(
                          icon: Icons.timer_outlined,
                          label: l10n.estimatedTimeMinutes(task.estimatedTimeMinutes!),
                        ),
                      if (task.antiFatigueEnabled)
                        _StatusMetaChip(
                          icon: Icons.self_improvement_rounded,
                          label: l10n.antiFatigueLabel,
                        ),
                      if (task.isChallenge)
                        _StatusMetaChip(
                          icon: Icons.emoji_events_outlined,
                          label: l10n.challengeXpLabel(
                            task.challengeTitle ?? l10n.weeklyChallengeTitle,
                            task.challengeBonusXp,
                          ),
                        ),
                    ],
                  ),
                  if (task.rescuePlan != null && isOverdue) ...[
                    const SizedBox(height: 12),
                    _buildRescuePlanCard(theme, task),
                  ],
                  if (task.requiresSubmission &&
                      !isCompleted &&
                      task.submission == null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _showSubmitDialog(task),
                        icon: const Icon(Icons.send),
                        label: Text(l10n.submitTask),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary,
                          foregroundColor: theme.colorScheme.onSecondary,
                        ),
                      ),
                    ),
                  ],
                  if (task.submission != null) ...[
                    const SizedBox(height: 12),
                    _buildSubmissionStatus(theme, task),
                  ],
                  if (task.dueAt != null || task.reminder != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      height: 1,
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    ),
                    const SizedBox(height: 12),
                  if (task.reminder?.escalatedToParent == true) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                size: 18, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                task.reminder?.parentAlertMessage ??
                                    l10n.parentAlerted,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (task.antiFatigueEnabled) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.self_improvement_rounded,
                              size: 18,
                              color: theme.colorScheme.tertiary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${l10n.antiFatigueBannerTitle}: ${l10n.antiFatigueBannerText}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        if (task.dueAt != null) ...[
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: isOverdue
                                ? Colors.red
                                : theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatDateTime(task.dueAt!, l10n),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isOverdue
                                  ? Colors.red
                                  : theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        if (task.reminder != null &&
                            task.reminder!.isEnabled) ...[
                          Icon(
                            Icons.notifications_active,
                            size: 14,
                            color: task.reminder!.escalatedToParent
                                ? Colors.red
                                : theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            task.reminder!.escalatedToParent
                                ? l10n.escalatedToParent
                                : l10n.reminderProgress(
                                    task.reminder!.missedCount,
                                    task.reminder!.maxMissedCount,
                                  ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: task.reminder!.escalatedToParent
                                  ? Colors.red
                                  : theme.colorScheme.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const Spacer(),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCheckbox(TaskItem task, bool isCompleted) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Checkbox(
        value: isCompleted,
        onChanged: (value) => _toggleTaskComplete(task, value ?? false),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(
      ThemeData theme, TaskStatus status, Color color, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Text(
        status.label(l10n),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildProfile(ThemeData theme, UserMetrics? metrics) {
    final authSession = ref.watch(authControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return authSession.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(child: Text(l10n.errorLoadingProfile)),
      data: (session) {
        if (session == null) {
          return Center(child: Text(l10n.notLoggedIn));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 56,
                    backgroundColor: theme.colorScheme.surface,
                    child: Text(
                      session.user.fullName.substring(0, 1).toUpperCase(),
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                session.user.fullName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                session.user.email,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getRoleIcon(session.user.role.name),
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _roleLabel(session.user.role.name, l10n),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (metrics?.gamification != null) ...[
                const SizedBox(height: 24),
                _buildGamificationHero(theme, metrics!.gamification!),
                const SizedBox(height: 16),
                _buildBadgeSection(theme, metrics.gamification!),
              ],
              const SizedBox(height: 48),
              _buildProfileMenuItem(
                theme,
                Icons.language_outlined,
                l10n.language,
                _showLanguageDialog,
              ),
              _buildProfileMenuItem(
                theme,
                Icons.person_outline,
                l10n.editProfile,
                () {},
              ),
              _buildProfileMenuItem(
                theme,
                Icons.notifications_outlined,
                l10n.notifications,
                () {},
              ),
              _buildProfileMenuItem(
                theme,
                Icons.lock_outline,
                l10n.privacySecurity,
                () {},
              ),
              _buildProfileMenuItem(
                theme,
                Icons.help_outline,
                l10n.helpSupport,
                () {},
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'student':
        return Icons.school_outlined;
      case 'teacher':
        return Icons.cast_for_education_outlined;
      case 'parent':
        return Icons.family_restroom_outlined;
      default:
        return Icons.person_outline;
    }
  }

  Widget _buildProfileMenuItem(
      ThemeData theme, IconData icon, String label, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildStats(ThemeData theme, List<TaskItem> tasks, UserMetrics? metrics) {
    final l10n = AppLocalizations.of(context)!;
    final completed =
        tasks.where((t) => t.status == TaskStatus.completed).length;
    final total = tasks.length;
    final inProgress =
        tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final pending = tasks.where((t) => t.status == TaskStatus.pending).length;
    final overdue = tasks
        .where((t) =>
            t.dueAt != null &&
            t.dueAt!.isBefore(DateTime.now()) &&
            t.status != TaskStatus.completed)
        .length;

    final completionRate = total > 0 ? (completed / total * 100).round() : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.yourProgress,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildProgressCard(theme, completionRate, completed, total),
          if (metrics?.gamification != null) ...[
            const SizedBox(height: 24),
            _buildGamificationHero(theme, metrics!.gamification!, compact: true),
            const SizedBox(height: 16),
            _buildChallengesSection(theme, metrics.gamification!),
            const SizedBox(height: 16),
            _buildBadgeSection(theme, metrics.gamification!, compact: true),
          ],
          const SizedBox(height: 24),
          Text(
            l10n.taskOverview,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(
                  theme,
                  l10n.total,
                  total.toString(),
                  Icons.list_alt,
                  theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(
                  theme,
                  l10n.completed,
                  completed.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(
                  theme,
                  l10n.inProgress,
                  inProgress.toString(),
                  Icons.pending,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(
                  theme,
                  l10n.pending,
                  pending.toString(),
                  Icons.hourglass_empty,
                  Colors.blue,
                ),
              ),
            ],
          ),
          if (metrics != null) ...[
            const SizedBox(height: 12),
            _buildStatTile(
              theme,
              l10n.minutes,
              metrics.totalFocusTimeMinutes.toString(),
              Icons.timer_outlined,
              Colors.teal,
              fullWidth: true,
            ),
          ],
          const SizedBox(height: 12),
          _buildStatTile(
            theme,
            l10n.overdue,
            overdue.toString(),
            Icons.warning,
            Colors.red,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStudyPlanCard(
    ThemeData theme,
    StudyPlan studyPlan,
    List<TaskItem> tasks,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final firstTaskRef = studyPlan.doNow.isNotEmpty
        ? studyPlan.doNow.first
        : studyPlan.doNext.isNotEmpty
            ? studyPlan.doNext.first
            : null;
    TaskItem? linkedTask;
    if (firstTaskRef != null) {
      for (final task in tasks) {
        if (task.id == firstTaskRef.id) {
          linkedTask = task;
          break;
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.secondaryContainer,
            theme.colorScheme.primaryContainer.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.aiStudyPlanTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (studyPlan.estimatedTotalMinutes > 0)
                _StatusMetaChip(
                  icon: Icons.timer_outlined,
                  label: l10n.shortMinutesLabel(
                    studyPlan.estimatedTotalMinutes,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            studyPlan.focusMessage,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.35,
            ),
          ),
          if (studyPlan.mainSkillToImprove?.isNotEmpty ?? false) ...[
            const SizedBox(height: 10),
            _StatusMetaChip(
              icon: Icons.psychology_alt_outlined,
              label: l10n.mainSkillToImproveLabel(studyPlan.mainSkillToImprove!),
            ),
          ],
          if (studyPlan.doNow.isNotEmpty) ...[
            const SizedBox(height: 14),
            _PlanSection(
              title: l10n.doNowLabel,
              items: studyPlan.doNow,
            ),
          ],
          if (studyPlan.doNext.isNotEmpty) ...[
            const SizedBox(height: 10),
            _PlanSection(
              title: l10n.doNextLabel,
              items: studyPlan.doNext,
            ),
          ],
          if (studyPlan.stretchGoal?.isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            Text(
              l10n.stretchGoalLabel(studyPlan.stretchGoal!),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (studyPlan.weeklyNarrative != null) ...[
            const SizedBox(height: 14),
            _InsightPanel(
              title: studyPlan.weeklyNarrative!.headline,
              summary: studyPlan.weeklyNarrative!.summary,
              nextFocus: studyPlan.weeklyNarrative!.nextFocus,
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(studyPlanControllerProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(l10n.refresh),
              ),
              if (linkedTask != null)
                FilledButton.icon(
                  onPressed: () => _showTaskDetails(linkedTask!),
                  icon: const Icon(Icons.launch, size: 18),
                  label: Text(l10n.openFocusTask),
                ),
              if (linkedTask != null &&
                  linkedTask.status != TaskStatus.completed)
                TextButton.icon(
                  onPressed: () => _toggleTaskComplete(linkedTask!, true),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(l10n.markFirstDone),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRescuePlanCard(ThemeData theme, TaskItem task) {
    final rescue = task.rescuePlan!;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.health_and_safety_outlined, color: Colors.orange.shade800),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.deadlineRescuePlanTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (rescue.difficultyTone?.isNotEmpty ?? false)
            Text(
              l10n.rescueApproachLabel(rescue.difficultyTone!),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange.shade900,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (rescue.recommendedNewTimeBlock?.isNotEmpty ?? false) ...[
            const SizedBox(height: 6),
            Text(
              l10n.rescueRecommendedBlockLabel(
                rescue.recommendedNewTimeBlock!,
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange.shade900,
              ),
            ),
          ],
          if (rescue.miniSteps.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...rescue.miniSteps.map(
              (step) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.arrow_right_alt, size: 18, color: Colors.orange.shade800),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        step,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGamificationHero(
    ThemeData theme,
    GamificationProfile profile, {
    bool compact = false,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF102A43),
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.gamificationTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      profile.rankTitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.84),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${l10n.levelLabel} ${profile.level}',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _HeroStatPill(label: l10n.xpLabel, value: '${profile.totalXp}'),
              _HeroStatPill(label: l10n.energyLabel, value: '${profile.energy}%'),
              _HeroStatPill(
                label: l10n.badgesTitle,
                value: '${profile.unlockedBadges.length}',
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: profile.progressPercent / 100,
              minHeight: 12,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${profile.currentLevelXp}/${profile.nextLevelXp} ${l10n.xpLabel}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.86),
                ),
              ),
              if (!compact && profile.nextUnlockHint?.isNotEmpty == true)
                Flexible(
                  child: Text(
                    '${l10n.nextRewardLabel}: ${profile.nextUnlockHint!}',
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.86),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeSection(
    ThemeData theme,
    GamificationProfile profile, {
    bool compact = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final badges = profile.unlockedBadges.take(compact ? 4 : 6).toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.badgesTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (badges.isEmpty)
              Text(
                l10n.noBadgesYet,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: badges
                    .map((badge) => _BadgeChip(badge: badge))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengesSection(ThemeData theme, GamificationProfile profile) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.dailyChallengesTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...profile.dailyChallenges.map(
              (challenge) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ChallengeTile(challenge: challenge),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _shouldShowStreakWarning(UserMetrics metrics) {
    if (metrics.currentStreak <= 0 || metrics.lastCompletedAt == null) {
      return false;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = metrics.lastCompletedAt!.toLocal();
    final lastDay = DateTime(last.year, last.month, last.day);
    return lastDay.isBefore(today);
  }

  Widget _buildStreakShieldBanner(ThemeData theme, UserMetrics metrics) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF97316),
            Color(0xFFFB7185),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF97316).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.streakShieldTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.streakShieldBody(metrics.currentStreak),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(
      ThemeData theme, int percentage, int completed, int total) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.completionRate,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$percentage%',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: percentage / 100),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 12,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        valueColor:
                            AlwaysStoppedAnimation(theme.colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$completed ${l10n.completed}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${total - completed} ${l10n.remaining}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color, {
    bool fullWidth = false,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dueDay = DateTime(dt.year, dt.month, dt.day);

    String dayStr;
    if (dueDay == today) {
      dayStr = l10n.today;
    } else if (dueDay == tomorrow) {
      dayStr = l10n.tomorrow;
    } else {
      dayStr = '${dt.day}/${dt.month}';
    }

    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$dayStr $timeStr';
  }

  void _toggleTaskComplete(TaskItem task, bool completed) {
    _handleTaskCompletionToggle(task, completed);
  }

  Future<void> _handleTaskCompletionToggle(TaskItem task, bool completed) async {
    final l10n = AppLocalizations.of(context)!;
    final beforeProfile =
        ref.read(studentMetricsControllerProvider).valueOrNull?.gamification;
    final newStatus = completed ? TaskStatus.completed : TaskStatus.pending;

    try {
      final controller = ref.read(taskMutationControllerProvider.notifier);
      await controller.updateTask(
            id: task.id,
            title: task.title,
            description: task.description,
            status: newStatus,
            dueAt: task.dueAt,
            reminderEnabled: task.reminder?.isEnabled ?? true,
            remindAfterHours: task.reminder?.remindAfterHours ?? 6,
            maxMissedCount: task.reminder?.maxMissedCount ?? 3,
            difficultyLevel: task.difficultyLevel,
            estimatedTimeMinutes: task.estimatedTimeMinutes,
            antiFatigueEnabled: task.antiFatigueEnabled,
          );

      final mutationError = controller.errorMessage();
      if (mutationError != null) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mutationError)),
        );
        return;
      }

      if (!mounted || !completed) {
        return;
      }

      final afterProfile =
          ref.read(studentMetricsControllerProvider).valueOrNull?.gamification;
      await _showGamificationCelebration(
        before: beforeProfile,
        after: afterProfile,
        l10n: l10n,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is ApiException
          ? error.message
          : '${l10n.somethingWentWrong}: $error';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _showGamificationCelebration({
    required GamificationProfile? before,
    required GamificationProfile? after,
    required AppLocalizations l10n,
  }) async {
    if (!mounted || after == null) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final beforeBadgeIds = before?.unlockedBadges.map((badge) => badge.id).toSet() ?? <String>{};
    final newlyUnlocked = after.unlockedBadges
        .where((badge) => !beforeBadgeIds.contains(badge.id))
        .toList();

    if (before != null && after.level > before.level) {
      await _showLevelUpDialog(after, l10n);
    }

    for (final badge in newlyUnlocked.take(2)) {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(Icons.workspace_premium, color: Colors.amber),
              const SizedBox(width: 12),
              Expanded(child: Text(l10n.badgeUnlockedMessage(badge.title))),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _showLevelUpDialog(
    GamificationProfile profile,
    AppLocalizations l10n,
  ) async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final theme = Theme.of(context);
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                  const Color(0xFFFB7185),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.levelUpMessage(profile.level),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  profile.rankTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  '${profile.totalXp} ${l10n.xpLabel}',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.levelUpDialogAction),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddTaskDialog() {
    showDialog<TaskFormResult>(
      context: context,
      builder: (context) => const TaskFormDialog(),
    ).then((result) {
      if (result != null) {
        ref.read(taskMutationControllerProvider.notifier).createTask(
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
    });
  }

  void _showTaskDetails(TaskItem task) {
    showDialog<TaskFormResult>(
      context: context,
      builder: (context) => TaskFormDialog(initialTask: task),
    ).then((result) {
      if (result != null) {
        ref.read(taskMutationControllerProvider.notifier).updateTask(
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
    });
  }

  void _showSubmitDialog(TaskItem task) {
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController controller = TextEditingController();
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${l10n.submitTaskTitle}: ${task.title}'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.yourSubmission,
            hintText: l10n.enterSubmissionHint,
            border: const OutlineInputBorder(),
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.submitTask),
          ),
        ],
      ),
    ).then((result) async {
      if (result == true && controller.text.trim().isNotEmpty) {
        if (!mounted) {
          controller.dispose();
          return;
        }

        final navigator = Navigator.of(context, rootNavigator: true);
        final messenger = ScaffoldMessenger.of(context);

        try {
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (context) => _SubmissionProgressDialog(
              title: l10n.submittingTask,
              message: task.reviewMode == TaskReviewMode.teacherOnly
                  ? l10n.submissionSavedWaitingForTeacher
                  : l10n.aiReviewRunningStudent,
            ),
          );

          await ref.read(taskMutationControllerProvider.notifier).submitTask(
                taskId: task.id,
                submissionText: controller.text.trim(),
              );

          if (navigator.mounted) {
            navigator.pop();
          }
          messenger.showSnackBar(
            SnackBar(content: Text(_submissionSuccessMessage(task, l10n))),
          );
        } catch (e) {
          if (navigator.mounted && navigator.canPop()) {
            navigator.pop();
          }
          messenger.showSnackBar(
            SnackBar(content: Text('${l10n.somethingWentWrong}: $e')),
          );
        }
      }
      controller.dispose();
    });
  }

  Future<bool> _confirmDelete(TaskItem task) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.deleteTaskTitle),
          content: Text(l10n.deleteTaskMessage(task.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(l10n.deleteTask),
          ),
        ],
      ),
    );
    if (result == true) {
      ref.read(taskMutationControllerProvider.notifier).deleteTask(task.id);
    }
    return false;
  }

  Widget _buildSubmissionStatus(ThemeData theme, TaskItem task) {
    final l10n = AppLocalizations.of(context)!;
    final submission = task.submission!;
    final isGraded = submission.isGraded;
    final aiStatus = submission.aiReviewStatus ?? 'not_requested';
    final hasAiReview =
        submission.aiGrade != null || (submission.aiFeedback?.isNotEmpty ?? false);
    final isAiPending = aiStatus == 'pending';
    final isAiFailed = aiStatus == 'failed';
    final isAiReady = aiStatus == 'ready' && hasAiReview;
    final cardColor = isGraded
        ? Colors.green
        : isAiFailed
            ? Colors.red
            : isAiPending
                ? theme.colorScheme.secondary
                : isAiReady
                    ? theme.colorScheme.primary
                    : Colors.orange;
    final statusIcon = isGraded
        ? Icons.check_circle
        : isAiFailed
            ? Icons.error_outline
            : isAiPending
                ? Icons.auto_awesome
                : isAiReady
                    ? Icons.auto_awesome
                    : Icons.pending;
    final statusLabel = isGraded
        ? l10n.graded
        : isAiFailed
            ? l10n.aiReviewFailedStudent
            : isAiPending
                ? l10n.aiReviewRunningStudent
                : isAiReady
                    ? l10n.aiReviewReadyStudent
                    : l10n.submitted;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cardColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AnimatedStatusPill(
                label: statusLabel,
                color: cardColor,
                icon: statusIcon,
                isPulsing: isAiPending,
              ),
              if (isGraded && submission.grade != null) ...[
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l10n.gradeValue(submission.grade!),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (!isGraded) ...[
            const SizedBox(height: 8),
            Text(
              task.reviewMode == TaskReviewMode.teacherOnly
                  ? l10n.submissionSavedWaitingForTeacher
                  : isAiPending
                      ? l10n.aiReviewRunningStudent
                      : isAiFailed
                          ? (submission.aiReviewError?.isNotEmpty ?? false)
                              ? submission.aiReviewError!
                              : l10n.aiReviewFailedStudent
                          : isAiReady
                              ? l10n.aiReviewReadyStudent
                              : l10n.submissionSavedWaitingForTeacher,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
          ],
          const SizedBox(height: 10),
          _ReviewTimeline(
            submittedLabel: l10n.reviewTimelineSubmitted,
            aiCheckedLabel: l10n.reviewTimelineAiChecked,
            gradedLabel: l10n.reviewTimelineTeacherGraded,
            submittedSubtitle: _formatDateTime(submission.submittedAt, l10n),
            aiCheckedSubtitle: submission.aiCheckedAt == null
                ? null
                : _formatDateTime(submission.aiCheckedAt!, l10n),
            gradedSubtitle: submission.gradedAt == null
                ? null
                : _formatDateTime(submission.gradedAt!, l10n),
            submittedDone: true,
            aiCheckedDone: isAiReady || isAiFailed || isGraded,
            aiChecking: isAiPending,
            gradedDone: isGraded,
            celebrateAiChecked: isAiReady,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusMetaChip(
                icon: Icons.rule_folder_outlined,
                label:
                    '${l10n.reviewModeLabel}: ${task.reviewMode.label(l10n)}',
              ),
              if (task.evaluationCriteria?.isNotEmpty ?? false)
                _StatusMetaChip(
                  icon: Icons.fact_check_outlined,
                  label:
                      '${l10n.evaluationCriteriaLabel}: ${task.evaluationCriteria!}',
                ),
            ],
          ),
          if (submission.submissionText != null &&
              submission.submissionText!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              l10n.yourAnswerValue(submission.submissionText!),
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
          if (isGraded &&
              submission.feedback != null &&
              submission.feedback!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.comment,
                      size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.teacherFeedbackValue(submission.feedback!),
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (hasAiReview) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.aiSuggestionTitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  if (submission.aiGrade != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.aiSuggestedGrade}: ${submission.aiGrade}',
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                  if (submission.aiFeedback?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.aiSuggestedFeedback}: ${submission.aiFeedback!}',
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                  if (submission.aiCheckedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.aiCheckedAtLabel(
                        _formatDateTime(submission.aiCheckedAt!, l10n),
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (submission.aiScorePercent != null ||
                submission.aiConfidence != null ||
                submission.aiRatingLabel?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (submission.aiScorePercent != null)
                    _StatusMetaChip(
                      icon: Icons.speed_outlined,
                      label: l10n.aiScoreCompactLabel(
                        submission.aiScorePercent!,
                      ),
                    ),
                  if (submission.aiConfidence != null)
                    _StatusMetaChip(
                      icon: Icons.verified_outlined,
                      label: l10n.confidenceCompactLabel(
                        submission.aiConfidence!,
                      ),
                    ),
                  if (submission.aiRatingLabel?.isNotEmpty == true)
                    _StatusMetaChip(
                      icon: Icons.workspace_premium_outlined,
                      label: submission.aiRatingLabel!,
                    ),
                ],
              ),
            ],
            if (submission.aiStrengths.isNotEmpty) ...[
              const SizedBox(height: 8),
              _AiListSummary(
                title: l10n.strengthsTitle,
                color: Colors.green,
                items: submission.aiStrengths,
              ),
            ],
            if (submission.aiImprovements.isNotEmpty) ...[
              const SizedBox(height: 8),
              _AiListSummary(
                title: l10n.nextStepsTitle,
                color: Colors.orange,
                items: submission.aiImprovements,
              ),
            ],
            if (submission.aiRiskFlags.isNotEmpty) ...[
              const SizedBox(height: 8),
              _AiListSummary(
                title: l10n.reviewSignalsTitle,
                color: Colors.red,
                items: submission.aiRiskFlags,
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _submissionSuccessMessage(TaskItem task, AppLocalizations l10n) {
    switch (task.reviewMode) {
      case TaskReviewMode.aiOnly:
        return l10n.aiReviewReadyStudent;
      case TaskReviewMode.teacherAndAi:
        return l10n.aiReviewRunningStudent;
      case TaskReviewMode.teacherOnly:
        return l10n.taskSubmittedSuccess;
    }
  }

  String _roleLabel(String role, AppLocalizations l10n) {
    switch (role) {
      case 'student':
        return l10n.roleStudent;
      case 'teacher':
        return l10n.roleTeacher;
      case 'parent':
        return l10n.roleParent;
      default:
        return role;
    }
  }

  void _showLanguageDialog() {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.language),
        content: const SizedBox(
          width: double.maxFinite,
          child: LanguageSelector(
            showLabel: false,
            padding: EdgeInsets.zero,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardSliver(
    ThemeData theme, {
    required List<TaskItem> tasks,
    required UserMetrics? metrics,
    required StudyPlan? studyPlan,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final session = ref.watch(authControllerProvider).valueOrNull;
    final firstName = session?.user.fullName.split(' ').first ?? l10n.roleStudent;
    final now = DateTime.now();
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final dateLabel = DateFormat('EEEE, d MMMM', localeTag).format(now);
    final activeTasks =
        tasks.where((task) => task.status != TaskStatus.completed).toList();
    final dueSoonTasks = activeTasks.where((task) => task.dueAt != null).toList()
      ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));
    final completedToday = tasks.where((task) {
      if (task.status != TaskStatus.completed) {
        return false;
      }
      final updated = task.updatedAt.toLocal();
      return updated.year == now.year &&
          updated.month == now.month &&
          updated.day == now.day;
    }).length;
    final overdueCount = activeTasks
        .where((task) => task.dueAt != null && task.dueAt!.isBefore(now))
        .length;
    final completionRate = metrics?.completionRate ??
        (tasks.isEmpty
            ? 0
            : ((tasks
                            .where(
                              (task) => task.status == TaskStatus.completed,
                            )
                            .length /
                        tasks.length) *
                    100)
                .round());

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      sliver: SliverToBoxAdapter(
        child: Column(
          children: [
            _buildDashboardHero(
              theme,
              firstName: firstName,
              dateLabel: dateLabel,
              activeTasks: activeTasks.length,
              completedToday: completedToday,
              streak: metrics?.currentStreak ?? 0,
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 980;
                final leftPane = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (metrics != null && _shouldShowStreakWarning(metrics))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _buildStreakShieldBanner(theme, metrics),
                      ),
                    _buildSummaryRow(
                      theme,
                      activeTasks: activeTasks.length,
                      completionRate: completionRate,
                      streak: metrics?.currentStreak ?? 0,
                      overdueCount: overdueCount,
                    ),
                    const SizedBox(height: 18),
                    _buildAgendaSection(theme, activeTasks),
                  ],
                );
                final sidePane = Column(
                  children: [
                    if (metrics?.gamification != null)
                      _buildGamificationHero(
                        theme,
                        metrics!.gamification!,
                        compact: true,
                      ),
                    if (metrics?.gamification != null) const SizedBox(height: 16),
                    if (studyPlan != null)
                      _buildStudyPlanCard(theme, studyPlan, tasks),
                    if (studyPlan != null) const SizedBox(height: 16),
                    _buildUpcomingPanel(theme, dueSoonTasks.take(4).toList()),
                  ],
                );

                if (!wide) {
                  return Column(
                    children: [
                      leftPane,
                      const SizedBox(height: 18),
                      sidePane,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: leftPane),
                    const SizedBox(width: 20),
                    SizedBox(
                      width: constraints.maxWidth.clamp(0.0, 1180.0) * 0.31,
                      child: sidePane,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardHero(
    ThemeData theme, {
    required String firstName,
    required String dateLabel,
    required int activeTasks,
    required int completedToday,
    required int streak,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFEEF1FF),
            Colors.white,
            theme.colorScheme.secondary.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final headline = compact
              ? '${l10n.hello}, $firstName'
              : '${l10n.hello}, $firstName!';

          return Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: compact ? constraints.maxWidth : 520,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _capitalize(dateLabel),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.64),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      activeTasks == 0
                          ? l10n.addFirstTaskHint
                          : '$activeTasks ${l10n.tasksTab.toLowerCase()} in focus. $completedToday ${l10n.completed.toLowerCase()} today.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.82),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          onPressed: _showAddTaskDialog,
                          icon: const Icon(Icons.add_task),
                          label: Text(l10n.addTask),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => ref
                              .read(studyPlanControllerProvider.notifier)
                              .refresh(),
                          icon: const Icon(Icons.auto_awesome_outlined),
                          label: Text(l10n.aiStudyPlanTitle),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: compact ? double.infinity : 250,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      Color.alphaBlend(
                        theme.colorScheme.secondary.withValues(alpha: 0.24),
                        theme.colorScheme.primary,
                      ),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.levelLabel} ${ref.read(studentMetricsControllerProvider).valueOrNull?.gamification?.level ?? 1}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      streak > 0
                          ? '${l10n.streak}: $streak ${l10n.days.toLowerCase()}'
                          : l10n.createFirstTask,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: ((completedToday + 1) /
                                (activeTasks + completedToday + 1).clamp(1, 6))
                            .clamp(0, 1)
                            .toDouble(),
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      activeTasks > 0
                          ? '$completedToday ${l10n.completed.toLowerCase()}, $activeTasks ${l10n.remaining.toLowerCase()}'
                          : l10n.createFirstTask,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.86),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(
    ThemeData theme, {
    required int activeTasks,
    required int completionRate,
    required int streak,
    required int overdueCount,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final items = [
          _DashboardMetricData(
            title: l10n.tasksTab,
            value: '$activeTasks',
            subtitle: activeTasks == 1 ? l10n.task : l10n.assigned,
            color: theme.colorScheme.primary,
            icon: Icons.checklist_rounded,
          ),
          _DashboardMetricData(
            title: l10n.completionRate,
            value: '$completionRate%',
            subtitle: l10n.updated,
            color: theme.colorScheme.secondary,
            icon: Icons.trending_up_rounded,
          ),
          _DashboardMetricData(
            title: l10n.streak,
            value: '$streak',
            subtitle: overdueCount > 0 ? l10n.overdue : l10n.activeNow,
            color: const Color(0xFFFF7A1A),
            icon: Icons.local_fire_department_outlined,
          ),
        ];

        final wide = constraints.maxWidth >= 760;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: items
              .map(
                (item) => SizedBox(
                  width:
                      wide ? (constraints.maxWidth - 28) / 3 : constraints.maxWidth,
                  child: _DashboardMetricCard(theme: theme, data: item),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildAgendaSection(ThemeData theme, List<TaskItem> activeTasks) {
    final l10n = AppLocalizations.of(context)!;
    final prioritized = [...activeTasks]
      ..sort((a, b) {
        final aDue = a.dueAt ?? DateTime.now().add(const Duration(days: 999));
        final bDue = b.dueAt ?? DateTime.now().add(const Duration(days: 999));
        return aDue.compareTo(bDue);
      });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.tasksSectionTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.tasksSectionSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () =>
                    ref.read(taskListControllerProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(l10n.refreshTasks),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (prioritized.isEmpty)
            _buildEmptyState(theme)
          else
            ...List<Widget>.generate(
              prioritized.length,
              (index) => _buildTaskCard(theme, prioritized[index], index),
            ),
        ],
      ),
    );
  }

  Widget _buildUpcomingPanel(ThemeData theme, List<TaskItem> tasks) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.deadline,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.taskOverview,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 14),
          if (tasks.isEmpty)
            Text(
              l10n.noTasksInThisView,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            )
          else
            ...tasks.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _UpcomingTaskTile(
                  task: task,
                  formatDate: _formatDateTime,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusMetaChip extends StatelessWidget {
  const _StatusMetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _AiListSummary extends StatelessWidget {
  const _AiListSummary({
    required this.title,
    required this.color,
    required this.items,
  });

  final String title;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          ...items.take(3).map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $item',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanSection extends StatelessWidget {
  const _PlanSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<StudyPlanTaskRef> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.task_alt, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (item.estimatedTimeMinutes != null)
                  Text(
                    AppLocalizations.of(context)!.shortMinutesLabel(
                      item.estimatedTimeMinutes!,
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InsightPanel extends StatelessWidget {
  const _InsightPanel({
    required this.title,
    required this.summary,
    this.nextFocus,
  });

  final String title;
  final String summary;
  final String? nextFocus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(summary, style: theme.textTheme.bodySmall),
          if (nextFocus?.isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            Text(
              nextFocus!,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubmissionProgressDialog extends StatelessWidget {
  const _SubmissionProgressDialog({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
              ],
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
    required this.icon,
    required this.isPulsing,
  });

  final String label;
  final Color color;
  final IconData icon;
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 14, color: widget.color),
          const SizedBox(width: 6),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: widget.color,
            ),
          ),
        ],
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

class _HeroStatPill extends StatelessWidget {
  const _HeroStatPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badge});

  final GamificationBadge badge;

  @override
  Widget build(BuildContext context) {
    final color = _hexToColor(badge.accentColor);

    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconFromToken(badge.icon), color: color, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badge.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  badge.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.65),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeTile extends StatelessWidget {
  const _ChallengeTile({required this.challenge});

  final DailyChallenge challenge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress =
        challenge.target == 0 ? 0.0 : (challenge.current / challenge.target).clamp(0, 1).toDouble();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: challenge.completed
            ? Colors.green.withValues(alpha: 0.08)
            : theme.colorScheme.primaryContainer.withValues(alpha: 0.26),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                challenge.completed ? Icons.check_circle : Icons.flag_outlined,
                size: 18,
                color: challenge.completed ? Colors.green : theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  challenge.title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '+${challenge.rewardXp} ${AppLocalizations.of(context)!.xpLabel}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            challenge.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                challenge.completed ? Colors.green : theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${challenge.current}/${challenge.target}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  const _BackgroundGlow({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardMetricData {
  const _DashboardMetricData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;
}

class _DashboardMetricCard extends StatelessWidget {
  const _DashboardMetricCard({
    required this.theme,
    required this.data,
  });

  final ThemeData theme;
  final _DashboardMetricData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: data.color.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: data.color.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(data.icon, color: data.color, size: 18),
              ),
              const Spacer(),
              Text(
                data.title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.56),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            data.value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingTaskTile extends StatelessWidget {
  const _UpcomingTaskTile({
    required this.task,
    required this.formatDate,
  });

  final TaskItem task;
  final String Function(DateTime, AppLocalizations) formatDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final due = task.dueAt;
    final overdue = due != null && due.isBefore(DateTime.now());
    final accent = overdue ? const Color(0xFFFF7A1A) : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  due == null ? l10n.noDeadlineSet : formatDate(due, l10n),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(Icons.arrow_outward_rounded, size: 18, color: accent),
        ],
      ),
    );
  }
}

String _capitalize(String value) {
  if (value.isEmpty) {
    return value;
  }
  return value[0].toUpperCase() + value.substring(1);
}

Color _hexToColor(String hex) {
  final sanitized = hex.replaceAll('#', '');
  final normalized = sanitized.length == 6 ? 'FF$sanitized' : sanitized;
  return Color(int.parse(normalized, radix: 16));
}

IconData _iconFromToken(String token) {
  switch (token) {
    case 'bolt':
      return Icons.bolt_rounded;
    case 'check_circle':
      return Icons.check_circle;
    case 'local_fire_department':
      return Icons.local_fire_department;
    case 'trending_up':
      return Icons.trending_up;
    case 'military_tech':
      return Icons.military_tech;
    case 'hourglass_bottom':
      return Icons.hourglass_bottom;
    case 'workspace_premium':
      return Icons.workspace_premium;
    case 'auto_awesome':
      return Icons.auto_awesome;
    default:
      return Icons.stars_rounded;
  }
}
