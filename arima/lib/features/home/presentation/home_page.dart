import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/widgets/language_selector.dart';
import '../../auth/application/auth_controller.dart';
import '../../tasks/application/task_list_controller.dart';
import '../../tasks/application/task_mutation_controller.dart';
import '../../tasks/data/task_repository.dart';
import '../../tasks/domain/task_item.dart';
import '../../tasks/domain/task_status.dart';
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.03),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: _buildBody(theme),
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

    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() => _selectedIndex = index);
      },
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.checklist_outlined),
          selectedIcon: Icon(Icons.checklist, color: theme.colorScheme.primary),
          label: l10n.tasksTab,
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person, color: theme.colorScheme.primary),
          label: l10n.profileTab,
        ),
        NavigationDestination(
          icon: const Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart, color: theme.colorScheme.primary),
          label: l10n.statsTab,
        ),
      ],
    );
  }

  Widget _buildBody(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final tasksAsync = ref.watch(taskListControllerProvider);

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
              data: (tasks) => tasks.isEmpty
                  ? SliverFillRemaining(child: _buildEmptyState(theme))
                  : SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _buildTaskCard(theme, tasks[index], index),
                          childCount: tasks.length,
                        ),
                      ),
                    ),
            ),
          1 => SliverFillRemaining(child: _buildProfile(theme)),
          2 => tasksAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => SliverFillRemaining(
                child: Center(child: Text(l10n.errorLoadingStats)),
              ),
              data: (tasks) =>
                  SliverFillRemaining(child: _buildStats(theme, tasks)),
            ),
          _ => const SliverFillRemaining(child: SizedBox.shrink()),
        },
      ],
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final authSession = ref.watch(authControllerProvider);
    final userName =
        authSession.valueOrNull?.user.fullName ?? l10n.roleStudent;

    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: theme.colorScheme.surface,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title ?? l10n.studentWorkspace,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            ),
            Text(
              '${l10n.hello}, ${userName.split(' ').first}!',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () =>
              ref.read(taskListControllerProvider.notifier).refresh(),
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
            borderRadius: BorderRadius.circular(16),
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
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: InkWell(
            onTap: () => _showTaskDetails(task),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                                fontWeight: FontWeight.w600,
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
                              const SizedBox(height: 4),
                              Text(
                                task.description!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
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
                    const Divider(height: 1),
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

  Widget _buildProfile(ThemeData theme) {
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

  Widget _buildStats(ThemeData theme, List<TaskItem> tasks) {
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
    final newStatus = completed ? TaskStatus.completed : TaskStatus.pending;
    ref.read(taskMutationControllerProvider.notifier).updateTask(
          id: task.id,
          title: task.title,
          description: task.description,
          status: newStatus,
          dueAt: task.dueAt,
          reminderEnabled: task.reminder?.isEnabled ?? true,
          remindAfterHours: task.reminder?.remindAfterHours ?? 6,
          maxMissedCount: task.reminder?.maxMissedCount ?? 3,
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
        try {
          await ref.read(taskRepositoryProvider).submitTask(
                taskId: task.id,
                submissionText: controller.text.trim(),
              );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.taskSubmittedSuccess)),
            );
          }
          ref.read(taskListControllerProvider.notifier).refresh();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${l10n.somethingWentWrong}: $e')),
            );
          }
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isGraded
            ? Colors.green.withValues(alpha: 0.08)
            : Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGraded
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isGraded ? Icons.check_circle : Icons.pending,
                size: 16,
                color: isGraded ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                isGraded ? l10n.graded : l10n.submitted,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isGraded ? Colors.green : Colors.orange,
                ),
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
        ],
      ),
    );
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
}
