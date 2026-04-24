import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../application/parent_controller.dart';
import '../domain/linked_child.dart';

class ParentHomePage extends ConsumerStatefulWidget {
  const ParentHomePage({super.key});

  @override
  ConsumerState<ParentHomePage> createState() => _ParentHomePageState();
}

class _ParentHomePageState extends ConsumerState<ParentHomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final parentState = ref.watch(parentControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: parentState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('${l10n.somethingWentWrong}: $error')),
        data: (state) => IndexedStack(
          index: _selectedIndex,
          children: [
            _ChildrenTab(
              state: state,
              onViewStats: _selectStatsTab,
            ),
            _AlertsTab(state: state),
            _StatsTab(state: state),
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
            label: l10n.childrenTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.warning_amber_outlined),
            selectedIcon: const Icon(Icons.warning_amber),
            label: l10n.alertsTab,
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
              onPressed: _showLinkChildDialog,
              icon: const Icon(Icons.person_add),
              label: Text(l10n.linkChild),
            )
          : null,
    );
  }

  void _selectStatsTab() {
    setState(() => _selectedIndex = 2);
  }

  void _showLinkChildDialog() {
    final l10n = AppLocalizations.of(context)!;
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.linkChild),
        content: TextField(
          controller: emailController,
          decoration: InputDecoration(
            labelText: l10n.childEmail,
            hintText: l10n.childEmailHint,
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
              if (email.isNotEmpty) {
                Navigator.pop(context);
                await ref.read(parentControllerProvider.notifier).linkChild(email);
              }
            },
            child: Text(l10n.link),
          ),
        ],
      ),
    );
  }
}

class _ChildrenTab extends ConsumerWidget {
  const _ChildrenTab({required this.state, required this.onViewStats});

  final ParentState state;
  final VoidCallback onViewStats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (state.children.isEmpty) {
      return _buildEmptyState(context, theme);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.children.length,
      itemBuilder: (context, index) {
        final child = state.children[index];
        return _ChildCard(
          child: child,
          onViewStats: onViewStats,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: theme.colorScheme.primary.withAlpha(100)),
          const SizedBox(height: 16),
          Text(
            l10n.noChildrenLinkedYet,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.tapToLinkChild,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(153),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildCard extends ConsumerWidget {
  const _ChildCard({required this.child, required this.onViewStats});

  final LinkedChild child;
  final VoidCallback onViewStats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final metrics = child.metrics;

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
                    child.childName.substring(0, 1).toUpperCase(),
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
                        child.childName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        child.childEmail,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(153),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(child.linkStatus, theme).withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _localizedStatus(child.linkStatus, l10n).toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(child.linkStatus, theme),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (metrics != null) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    icon: Icons.assignment_outlined,
                    label: l10n.tasks,
                    value: metrics.totalTasksCreated.toString(),
                    color: theme.colorScheme.primary,
                  ),
                  _StatItem(
                    icon: Icons.check_circle_outline,
                    label: l10n.done,
                    value: metrics.totalTasksCompleted.toString(),
                    color: Colors.green,
                  ),
                  _StatItem(
                    icon: Icons.local_fire_department,
                    label: l10n.streak,
                    value: metrics.currentStreak.toString(),
                    color: Colors.orange,
                  ),
                  _StatItem(
                    icon: Icons.trending_up,
                    label: l10n.rate,
                    value: '${metrics.completionRate}%',
                    color: Colors.blue,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref.read(parentControllerProvider.notifier).selectChild(child.childId);
                      onViewStats();
                    },
                    icon: const Icon(Icons.bar_chart, size: 18),
                    label: Text(l10n.viewStats),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showUnlinkDialog(context, ref, child),
                  icon: Icon(Icons.link_off, color: theme.colorScheme.error),
                  tooltip: l10n.unlink,
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

  String _localizedStatus(String status, AppLocalizations l10n) {
    switch (status.toLowerCase()) {
      case 'active':
        return l10n.statusActive;
      case 'inactive':
        return l10n.statusInactive;
      default:
        return status;
    }
  }

  void _showUnlinkDialog(BuildContext context, WidgetRef ref, LinkedChild child) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.unlinkChild),
        content: Text('${l10n.confirmUnlink} ${child.childName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(parentControllerProvider.notifier).unlinkChild(child.childId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(l10n.unlink),
          ),
        ],
      ),
    );
  }
}

class _AlertsTab extends StatelessWidget {
  const _AlertsTab({required this.state});

  final ParentState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final escalatedTasks = state.escalatedTasks;

    if (escalatedTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.green.withAlpha(100)),
            const SizedBox(height: 16),
            Text(
              l10n.noAlerts,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.childrenOnTrack,
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
      itemCount: escalatedTasks.length,
      itemBuilder: (context, index) {
        final task = escalatedTasks[index];
        return _EscalatedTaskCard(task: task);
      },
    );
  }
}

class _EscalatedTaskCard extends StatelessWidget {
  const _EscalatedTaskCard({required this.task});

  final Map<String, dynamic> task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.red.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task['title'] as String? ?? l10n.untitledTask,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade900,
                        ),
                      ),
                      Text(
                        l10n.childLabel(
                          task['child_name'] as String? ?? '-',
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.priority_high, color: Colors.red.shade800, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task['reminder']?['parent_alert_message'] as String? ??
                          l10n.immediateAttention,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.red.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (task['status'] != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _localizedStatus(
                        task['status'] as String,
                        l10n,
                      ).toUpperCase(),
                      style: TextStyle(
                        color: Colors.red.shade800,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (task['due_at'] != null)
                    Text(
                      l10n.dueLabel(_formatDate(task['due_at'] as String)),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.red.shade700,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    final dt = DateTime.parse(isoDate);
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _localizedStatus(String status, AppLocalizations l10n) {
    switch (status.toLowerCase()) {
      case 'active':
        return l10n.statusActive;
      case 'inactive':
        return l10n.statusInactive;
      case 'pending':
        return l10n.statusPending;
      case 'in_progress':
        return l10n.statusInProgress;
      case 'completed':
        return l10n.statusCompleted;
      case 'overdue':
        return l10n.statusOverdue;
      default:
        return status;
    }
  }
}

class _StatsTab extends ConsumerWidget {
  const _StatsTab({required this.state});

  final ParentState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (state.selectedChildId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_outlined, size: 80, color: theme.colorScheme.primary.withAlpha(100)),
            const SizedBox(height: 16),
            Text(
              l10n.selectChild,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.goToChildrenTab,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(153),
              ),
            ),
          ],
        ),
      );
    }

    final stats = state.selectedChildStats;
    final child = state.children.firstWhere(
      (c) => c.childId == state.selectedChildId,
      orElse: () => state.children.first,
    );

    if (stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  child.childName.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.childName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    l10n.statisticsOverview,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(153),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _MetricCard(
            icon: Icons.assignment,
            label: l10n.totalTasks,
            value: stats.totalTasks.toString(),
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          _MetricCard(
            icon: Icons.check_circle,
            label: l10n.completed,
            value: stats.completedTasks.toString(),
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _MetricCard(
            icon: Icons.warning,
            label: l10n.overdue,
            value: stats.overdueTasks.toString(),
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          _MetricCard(
            icon: Icons.local_fire_department,
            label: l10n.currentStreak,
            value: '${stats.currentStreak} ${l10n.days}',
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _MetricCard(
            icon: Icons.trending_up,
            label: l10n.completionRate,
            value: '${stats.completionRate}%',
            color: Colors.blue,
          ),
        ],
      ),
    );
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
