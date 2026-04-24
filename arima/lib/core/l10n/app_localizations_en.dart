import 'package:flutter/material.dart';

import 'app_localizations.dart';

class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn() : super(const Locale('en'));

  @override
  String get appTitle => 'Arima';
  @override
  String get welcomeBack => 'Welcome back!';
  @override
  String get createAccount => 'Create your account';
  @override
  String get signIn => 'Sign In';
  @override
  String get register => 'Register';
  @override
  String get emailLabel => 'Email';
  @override
  String get passwordLabel => 'Password';
  @override
  String get fullNameLabel => 'Full Name';
  @override
  String get roleLabel => 'I am a...';
  @override
  String get signInButton => 'Sign In';
  @override
  String get createAccountButton => 'Create Account';
  @override
  String get alreadyHaveAccount => 'Already have an account?';
  @override
  String get dontHaveAccount => "Don't have an account?";
  @override
  String get emailRequired => 'Email is required';
  @override
  String get emailInvalid => 'Enter a valid email';
  @override
  String get passwordRequired => 'Password is required';
  @override
  String get passwordTooShort => 'Password must be at least 8 characters';
  @override
  String get fullNameRequired => 'Full name is required';
  @override
  String get invalidCredentials => 'Invalid credentials';
  @override
  String get accountExists => 'Already registered';
  @override
  String get somethingWentWrong => 'Something went wrong. Please try again.';
  @override
  String get invalidEmailOrPassword =>
      'Invalid email or password. Please try again.';
  @override
  String get signInSubtitle => 'Sign in to continue learning and tracking.';
  @override
  String get createAccountSubtitle =>
      'Create an account to organize tasks and progress.';
  @override
  String get appFeatureAi => 'AI';

  @override
  String get roleStudent => 'Student';
  @override
  String get roleTeacher => 'Teacher';
  @override
  String get roleParent => 'Parent';

  @override
  String get tasksTab => 'Tasks';
  @override
  String get profileTab => 'Profile';
  @override
  String get statsTab => 'Stats';
  @override
  String get addTask => 'Add Task';
  @override
  String get noTasksYet => 'No tasks yet';
  @override
  String get addFirstTaskHint =>
      'Tap + to add your first task\nand start tracking your progress';
  @override
  String get somethingWentWrongRetry => 'Something went wrong';
  @override
  String get retry => 'Retry';
  @override
  String get refresh => 'Refresh';
  @override
  String get logout => 'Logout';
  @override
  String get hello => 'Hello';
  @override
  String get submitTask => 'Submit Task';
  @override
  String get cancel => 'Cancel';
  @override
  String get deleteTask => 'Delete Task';
  @override
  String get deleteTaskConfirm => 'Are you sure you want to delete';
  @override
  String get yourSubmission => 'Your submission';
  @override
  String get enterSubmissionHint => 'Enter your answer or submission text...';
  @override
  String get taskSubmittedSuccess => 'Task submitted successfully!';
  @override
  String get graded => 'Graded';
  @override
  String get submitted => 'Submitted';
  @override
  String get gradeLabel => 'Grade';
  @override
  String get teacherFeedback => 'Teacher feedback';
  @override
  String get yourAnswer => 'Your answer';
  @override
  String get today => 'Today';
  @override
  String get tomorrow => 'Tomorrow';
  @override
  String get escalatedToParent => 'Escalated!';
  @override
  String get parentAlerted => 'Parent has been alerted!';
  @override
  String get updated => 'Updated';
  @override
  String get createFirstTask => 'Create first task';
  @override
  String get filterAll => 'All';
  @override
  String get filterActive => 'Active';

  @override
  String get editProfile => 'Edit Profile';
  @override
  String get notifications => 'Notifications';
  @override
  String get privacySecurity => 'Privacy & Security';
  @override
  String get helpSupport => 'Help & Support';
  @override
  String get notLoggedIn => 'Not logged in';
  @override
  String get errorLoadingProfile => 'Error loading profile';
  @override
  String get language => 'Language';
  @override
  String get languageRussian => 'Russian';
  @override
  String get languageEnglish => 'English';

  @override
  String get yourProgress => 'Your Progress';
  @override
  String get completionRate => 'Completion Rate';
  @override
  String get completed => 'Completed';
  @override
  String get remaining => 'Remaining';
  @override
  String get taskOverview => 'Task Overview';
  @override
  String get total => 'Total';
  @override
  String get inProgress => 'In Progress';
  @override
  String get pending => 'Pending';
  @override
  String get overdue => 'Overdue';

  @override
  String get studentsTab => 'Students';
  @override
  String get assignTab => 'Assign';
  @override
  String get submissionsTab => 'Submissions';
  @override
  String get childrenTab => 'Children';
  @override
  String get alertsTab => 'Alerts';

  @override
  String get editTask => 'Edit Task';
  @override
  String get newTask => 'New Task';
  @override
  String get updateTaskDetails => 'Update task details';
  @override
  String get createNewTask => 'Create a new task to track';
  @override
  String get taskTitle => 'Task Title';
  @override
  String get taskTitleHint => 'What needs to be done?';
  @override
  String get titleRequired => 'Please enter a title';
  @override
  String get descriptionOptional => 'Description (optional)';
  @override
  String get descriptionHint => 'Add more details...';
  @override
  String get status => 'Status';
  @override
  String get deadline => 'Deadline';
  @override
  String get noDeadlineSet => 'No deadline set';
  @override
  String get smartReminders => 'Smart Reminders';
  @override
  String get remindEvery => 'Remind every';
  @override
  String get hours => 'hours';
  @override
  String get escalateAfter => 'Escalate after';
  @override
  String get misses => 'misses';
  @override
  String get reminderInfo =>
      'After max misses, a parent alert will be triggered';
  @override
  String get createTask => 'Create Task';
  @override
  String get updateTask => 'Update Task';
  @override
  String get reminderHoursRange => 'Enter a value from 1 to 72 hours';
  @override
  String get reminderMissesRange => 'Enter a value from 1 to 20';

  @override
  String get statusPending => 'Pending';
  @override
  String get statusInProgress => 'In Progress';
  @override
  String get statusCompleted => 'Completed';
  @override
  String get statusOverdue => 'Overdue';
  @override
  String get statusActive => 'Active';
  @override
  String get statusInactive => 'Inactive';

  @override
  String get linkStudent => 'Link Student';
  @override
  String get studentEmail => 'Student Email';
  @override
  String get studentEmailHint => 'student@example.com';
  @override
  String get taskAssignedSuccess => 'Task assigned successfully!';
  @override
  String get assigned => 'Assigned';
  @override
  String get linkStudentsFirst => 'Please link students first';
  @override
  String get assignNewTask => 'Assign New Task';
  @override
  String get createTaskForStudent =>
      'Create a new task for one of your students.';
  @override
  String get selectStudent => 'Select Student';
  @override
  String get dueDateOptional => 'Due Date (optional)';
  @override
  String get requiresSubmission => 'Requires Submission';
  @override
  String get studentMustSubmit =>
      'Student must submit a response to complete the task.';
  @override
  String get assignTask => 'Assign Task';
  @override
  String get noPendingSubmissions => 'No pending submissions';
  @override
  String get studentSubmissionsWillAppearHere =>
      'Student submissions will appear here for you to grade.';
  @override
  String get task => 'Task';
  @override
  String get submission => 'Submission';
  @override
  String get gradeRange => 'Grade (1-5)';
  @override
  String get selectGrade => 'Select a grade';
  @override
  String get feedbackOptional => 'Feedback (optional)';
  @override
  String get enterFeedback => 'Enter feedback for the student...';
  @override
  String get submitGrade => 'Submit Grade';
  @override
  String get noMetricsAvailable => 'No metrics available yet.';
  @override
  String get teacherDashboard => 'Teacher Dashboard';
  @override
  String get totalStudents => 'Total Students';
  @override
  String get assignedTasks => 'Assigned Tasks';
  @override
  String get submissionsReceived => 'Submissions Received';
  @override
  String get pendingGrading => 'Pending Grading';
  @override
  String get averageGrade => 'Average Grade';
  @override
  String get noStudentsLinkedYet => 'No students linked yet';
  @override
  String get tapToLinkStudent => 'Tap + to link a student';
  @override
  String get unknownStudent => 'Unknown Student';
  @override
  String get justNow => 'just now';
  @override
  String get yesterday => 'yesterday';
  @override
  String hoursAgo(int count) => '$count h ago';
  @override
  String daysAgo(int count) => '$count days ago';
  @override
  String gradeForStudent(String studentName) => 'Grade $studentName';
  @override
  String get aiAssistant => 'AI Assistant';
  @override
  String get aiTaskPromptLabel => 'What task do you want to create?';
  @override
  String get aiTaskPromptHint =>
      'Example: Create a gentle math practice task on fractions for tomorrow.';
  @override
  String get generateWithAi => 'Generate with AI';
  @override
  String get generatingDraft => 'Generating draft...';
  @override
  String get applyAiDraft => 'Apply AI draft';
  @override
  String get aiDraftReady => 'AI draft is ready';
  @override
  String get aiPromptRequired => 'Enter a short task request for AI';
  @override
  String aiModelLabel(String model) => 'Model: $model';

  @override
  String get linkChild => 'Link Child';
  @override
  String get childEmail => 'Child Email';
  @override
  String get childEmailHint => 'student@example.com';

  @override
  String get deleteTaskTitle => 'Delete Task';
  @override
  String get submitTaskTitle => 'Submit Task';
  @override
  String get link => 'Link';

  @override
  String get errorLoadingStats => 'Error loading stats';
  @override
  String get taskSyncedSuccess => 'Task list synced successfully.';

  @override
  String get tasksSectionTitle => 'Tasks';
  @override
  String get tasksSectionSubtitle => 'All tasks at a glance';
  @override
  String get refreshTasks => 'Refresh tasks';
  @override
  String get totalTasks => 'Total tasks';
  @override
  String get activeNow => 'Active now';
  @override
  String get completedTasks => 'Completed';
  @override
  String get escalations => 'Escalations';
  @override
  String get noTasksInThisView => 'No tasks in this view';
  @override
  String get switchFilterOrCreate => 'Switch the filter or create a new task';
  @override
  String get showAllTasks => 'Show all tasks';
  @override
  String get noDescriptionYet => 'No description yet.';
  @override
  String get parentEscalationTriggered => 'Parent escalation triggered.';
  @override
  String get edit => 'Edit';
  @override
  String get remindersPaused => 'Reminders paused';
  @override
  String noDeadlineValue() => 'No deadline';
  @override
  String updatedAtLabel(String value) => 'Updated $value';
  @override
  String reminderProgress(int missedCount, int maxMissedCount) =>
      '$missedCount/$maxMissedCount misses';
  @override
  String reminderEscalated(int missedCount) =>
      'Escalated after $missedCount misses';
  @override
  String reminderSchedule(int hours, int misses) =>
      'Every ${hours}h, miss $misses -> escalate';
  @override
  String get selectDate => 'Select date';
  @override
  String get selectTime => 'Select time';
  @override
  String get clearDate => 'Clear date';
  @override
  String get reminderEnabled => 'Reminder enabled';
  @override
  String get reminderInterval => 'Reminder interval (in hours)';
  @override
  String get maxMissesBeforeEscalation => 'Max misses before escalation';
  @override
  String get studentWorkspace => 'Student Workspace';
  @override
  String get taskActionFailed => 'Task action failed';
  @override
  String get connectionTimeout => 'Connection timeout';
  @override
  String get cannotReachBackend => 'Cannot reach backend';
  @override
  String get unexpectedNetworkError => 'Unexpected network error';
  @override
  String get deleteCannotBeUndone => 'This action cannot be undone';
  @override
  String deleteTaskMessage(String title) =>
      'Delete "$title"? This action cannot be undone.';
  @override
  String gradeValue(int grade) => 'Grade: $grade';
  @override
  String yourAnswerValue(String answer) => 'Your answer: $answer';
  @override
  String teacherFeedbackValue(String feedback) =>
      'Teacher feedback: $feedback';

  @override
  String get noChildrenLinkedYet => 'No children linked yet';
  @override
  String get tapToLinkChild => 'Tap to link your first child';
  @override
  String get tasks => 'Tasks';
  @override
  String get done => 'Done';
  @override
  String get streak => 'Streak';
  @override
  String get rate => 'Rate';
  @override
  String get viewStats => 'View Stats';
  @override
  String get unlinkChild => 'Unlink Child';
  @override
  String get confirmUnlink => 'Are you sure you want to unlink this child';
  @override
  String get unlink => 'Unlink';
  @override
  String get noAlerts => 'No alerts';
  @override
  String get childrenOnTrack => 'All children are on track';
  @override
  String get selectChild => 'Select a child to view their stats';
  @override
  String get goToChildrenTab => 'Go to Children tab to link a child';
  @override
  String get statisticsOverview => 'Statistics Overview';
  @override
  String get currentStreak => 'Current Streak';
  @override
  String get days => 'days';
  @override
  String childLabel(String childName) => 'Child: $childName';
  @override
  String dueLabel(String date) => 'Due: $date';
  @override
  String get untitledTask => 'Untitled Task';
  @override
  String get immediateAttention => 'This task requires immediate attention!';
  @override
  String get preparingWorkspace => 'Preparing your workspace';
  @override
  String get restoringSession =>
      'Restoring session and connecting to the backend.';
}
