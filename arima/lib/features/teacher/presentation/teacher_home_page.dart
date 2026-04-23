import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/teacher_controller.dart';
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

    return Scaffold(
      body: teacherState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (state) => IndexedStack(
          index: _selectedIndex,
          children: [
            _StudentsTab(state: state),
            _AssignTaskTab(students: state.students),
            _SubmissionsTab(submissions: state.pendingSubmissions, students: state.students),
            _StatsTab(metrics: state.metrics),
          ],
        ),

      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Students',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_add),
            selectedIcon: Icon(Icons.assignment_add),
            label: 'Assign',
          ),
          NavigationDestination(
            icon: Icon(Icons.inbox_outlined),
            selectedIcon: Icon(Icons.inbox),
            label: 'Submissions',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
        ],

      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _showLinkStudentDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('Link Student'),
            )
          : null,
    );
  }

  void _showLinkStudentDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Link Student'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Student Email',
            hintText: 'student@example.com',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isNotEmpty) {
                Navigator.pop(context);
                await ref.read(teacherControllerProvider.notifier).linkStudent(email);
              }
            },
            child: const Text('Link'),
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

    if (state.students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: theme.colorScheme.primary.withAlpha(100)),
            const SizedBox(height: 16),
            Text(
              'No students linked yet',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to link a student',
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(student.linkStatus, theme).withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    student.linkStatus.toUpperCase(),
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
                  label: 'Assigned',
                  value: student.assignedTasksCount.toString(),
                  color: theme.colorScheme.primary,
                ),
                _StatItem(
                  icon: Icons.check_circle_outline,
                  label: 'Submitted',
                  value: student.submittedCount.toString(),
                  color: Colors.green,
                ),
                _StatItem(
                  icon: Icons.grade_outlined,
                  label: 'Graded',
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
  int? _selectedStudentId;
  DateTime? _dueAt;
  bool _requiresSubmission = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.students.isEmpty) {
      return Center(
        child: Text(
          'Link students first to assign tasks',
          style: theme.textTheme.titleMedium,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Assign New Task',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a task for your student',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(153),
            ),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<int>(
            initialValue: _selectedStudentId,
            decoration: InputDecoration(
              labelText: 'Select Student',
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            items: widget.students.map((student) {
              return DropdownMenuItem(
                value: student.studentId,
                child: Text(student.studentName),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedStudentId = value),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Task Title',
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
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
              labelText: 'Description (optional)',
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
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
                labelText: 'Due Date (optional)',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    _dueAt == null
                        ? 'Select date'
                        : '${_dueAt!.day}/${_dueAt!.month}/${_dueAt!.year} ${_dueAt!.hour.toString().padLeft(2, '0')}:${_dueAt!.minute.toString().padLeft(2, '0')}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Requires Submission'),
            subtitle: const Text('Student must submit text or file'),
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
              onPressed: _isLoading || _selectedStudentId == null || _titleController.text.trim().isEmpty
                  ? null
                  : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Assign Task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        SizedBox(width: 8),
                        Icon(Icons.send),
                      ],
                    ),
            ),
          ),
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
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null || !mounted) return;

    setState(() {
      _dueAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    await ref.read(teacherControllerProvider.notifier).assignTask(
      studentId: _selectedStudentId!,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      dueAt: _dueAt,
      requiresSubmission: _requiresSubmission,
    );
    if (mounted) {
      setState(() {
        _isLoading = false;
        _titleController.clear();
        _descriptionController.clear();
        _dueAt = null;
        _requiresSubmission = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task assigned successfully!')),
      );
    }
  }
}

class _SubmissionsTab extends StatelessWidget {
  const _SubmissionsTab({
    required this.submissions,
    required this.students,
  });

  final List<TaskSubmission> submissions;
  final List<LinkedStudent> students;

  String _getStudentName(int studentId) {
    try {
      return students.firstWhere((s) => s.studentId == studentId).studentName;
    } catch (_) {
      return 'Unknown Student';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              'No pending submissions',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Student submissions will appear here',
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
          studentName: _getStudentName(submission.studentId),
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

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) return 'just now';
      return '${diff.inHours}h ago';
    }
    if (diff.inDays == 1) return 'yesterday';
    return '${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                        'Task #${submission.taskId}',
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
                    color: Colors.orange.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'PENDING',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (submission.submissionText != null && submission.submissionText!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Text(
                'Submission:',
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
                  'Submitted ${_formatDate(submission.submittedAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(153),
                  ),
                ),
                Consumer(
                  builder: (context, ref, child) {
                    return FilledButton.icon(
                      onPressed: () => _showGradeDialog(context, ref, submission),
                      icon: const Icon(Icons.grade, size: 18),
                      label: const Text('Grade'),
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

  void _showGradeDialog(BuildContext context, WidgetRef ref, TaskSubmission submission) {
    final gradeController = TextEditingController();
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Grade $studentName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          DropdownButtonFormField<int>(
            initialValue: int.tryParse(gradeController.text),
            decoration: const InputDecoration(

              labelText: 'Grade (1-5)',
              hintText: 'Select grade',
            ),
            items: [1, 2, 3, 4, 5].map((grade) {
              return DropdownMenuItem(
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
              decoration: const InputDecoration(
                labelText: 'Feedback (optional)',
                hintText: 'Enter feedback',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final grade = int.tryParse(gradeController.text);
              if (grade != null && grade >= 1 && grade <= 5) {

                Navigator.pop(context);
                await ref.read(teacherControllerProvider.notifier).gradeSubmission(
                  submissionId: submission.id,
                  grade: grade,
                  feedback: feedbackController.text.trim().isEmpty ? null : feedbackController.text.trim(),
                );
              }
            },
            child: const Text('Submit Grade'),
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

    if (metrics == null) {
      return const Center(child: Text('No metrics available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Teacher Dashboard',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _MetricCard(
            icon: Icons.people,
            label: 'Total Students',
            value: metrics!.totalStudents.toString(),
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          _MetricCard(
            icon: Icons.assignment,
            label: 'Assigned Tasks',
            value: metrics!.totalAssignedTasks.toString(),
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _MetricCard(
            icon: Icons.check_circle,
            label: 'Submissions Received',
            value: metrics!.totalSubmissions.toString(),
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _MetricCard(
            icon: Icons.pending_actions,
            label: 'Pending Grading',
            value: metrics!.pendingGrading.toString(),
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _MetricCard(
            icon: Icons.grade,
            label: 'Average Grade',
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
