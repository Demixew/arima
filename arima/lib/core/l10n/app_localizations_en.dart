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
  String get submittingTask => 'Submitting your answer...';
  @override
  String get aiReviewRunningStudent => 'AI is checking your answer now.';
  @override
  String get aiReviewReadyStudent => 'AI review is ready.';
  @override
  String get aiReviewFailedStudent =>
      'Your answer was saved, but AI review could not finish.';
  @override
  String get submissionSavedWaitingForTeacher =>
      'Your answer was saved and is waiting for teacher review.';
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
  String get gamificationTitle => 'Progress Journey';
  @override
  String get levelLabel => 'Level';
  @override
  String get xpLabel => 'XP';
  @override
  String get energyLabel => 'Energy';
  @override
  String get badgesTitle => 'Badges';
  @override
  String get dailyChallengesTitle => 'Daily Missions';
  @override
  String get nextRewardLabel => 'Next Reward';
  @override
  String get noBadgesYet => 'No badges yet. Complete tasks to unlock your first one.';
  @override
  String levelUpMessage(int level) => 'Level up! You reached level $level.';
  @override
  String badgeUnlockedMessage(String badgeTitle) =>
      'Badge unlocked: $badgeTitle';
  @override
  String get streakShieldTitle => 'Protect Your Streak';
  @override
  String streakShieldBody(int streak) =>
      'Complete one task today to keep your $streak-day streak alive.';
  @override
  String get levelUpDialogAction => 'Keep Going';
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
  String get reviewModeLabel => 'Review mode';
  @override
  String get reviewModeTeacherOnly => 'Teacher only';
  @override
  String get reviewModeTeacherAndAi => 'AI + teacher';
  @override
  String get reviewModeAiOnly => 'AI only';
  @override
  String get evaluationCriteriaLabel => 'Evaluation criteria';
  @override
  String get evaluationCriteriaHint =>
      'Example: accuracy, explanation quality, structure.';
  @override
  String get aiSuggestionTitle => 'AI suggestion';
  @override
  String get aiSuggestedGrade => 'AI grade';
  @override
  String get aiSuggestedFeedback => 'AI feedback';
  @override
  String get finalTeacherDecision => 'Teacher final decision';
  @override
  String get runAiReview => 'Run AI review';
  @override
  String get aiReviewCompleted => 'AI review is ready';
  @override
  String get aiReviewNeeded => 'AI review has not been generated yet';
  @override
  String get reviewSummary => 'Review summary';
  @override
  String get noSubmissionText => 'No submission text provided.';
  @override
  String aiCheckedAtLabel(String value) => 'Checked by AI: $value';
  @override
  String get aiReviewCheckingLabel => 'AI checking';
  @override
  String get aiReviewFailedLabel => 'AI failed';
  @override
  String get aiReviewRunningTeacher =>
      'AI review is running. Manual grading is still available.';
  @override
  String aiReviewFailedTeacher(String detail) => 'AI review failed: $detail';
  @override
  String get aiReviewFailedTeacherFallback =>
      'AI review failed. You can still grade this manually.';
  @override
  String get reviewTimelineSubmitted => 'Submitted';
  @override
  String get reviewTimelineAiChecked => 'AI checked';
  @override
  String get reviewTimelineTeacherGraded => 'Teacher graded';
  @override
  String get difficultyLabel => 'Difficulty';
  @override
  String get difficultyHint =>
      'Low is gentle practice, high is a bigger challenge.';
  @override
  String difficultyValue(int value) => 'Level $value';
  @override
  String get estimatedTimeLabel => 'Estimated time';
  @override
  String get estimatedTimeHint => 'How long should this take?';
  @override
  String estimatedTimeMinutes(int minutes) => '$minutes min';
  @override
  String get estimatedTimeRange => 'Enter a time from 1 to 480 minutes';
  @override
  String get minutes => 'min';
  @override
  String get antiFatigueLabel => 'Break-friendly mode';
  @override
  String get antiFatigueHint => 'Show a calmer, chunked workflow for longer tasks.';
  @override
  String get antiFatigueBannerTitle => 'Anti-fatigue plan';
  @override
  String get antiFatigueBannerText =>
      'Try short work sprints with a quick break so the task feels easier to finish.';
  @override
  String get aiHelperTitle => 'AI helper';
  @override
  String get aiHelperSubtitle =>
      'Let AI suggest a calmer title, timing, and difficulty before you assign the task.';
  @override
  String get atRiskRadarTitle => 'At-risk radar';
  @override
  String get atRiskRadarSubtitle => 'See who needs intervention first and why.';
  @override
  String get riskNeedsAttention => 'Needs attention';
  @override
  String get riskWatch => 'Watch';
  @override
  String get riskStable => 'Stable';
  @override
  String riskReasonLabel(String reason) => 'Risk reason: $reason';
  @override
  String get viewTasks => 'View tasks';
  @override
  String get viewSubmissions => 'View submissions';
  @override
  String studentTasksTitle(String name) => '$name tasks';
  @override
  String get noStudentTasksYet => 'No tasks assigned yet.';
  @override
  String get extendDeadline => 'Extend deadline';
  @override
  String get deadlineUpdated => 'Deadline updated';
  @override
  String get weeklyChallengeTitle => 'Weekly challenge';
  @override
  String get weeklyChallengeSubtitle =>
      'Make this assignment feel like a special quest with bonus XP.';
  @override
  String get challengeTitleLabel => 'Challenge title';
  @override
  String get challengeCategoryLabel => 'Challenge category';
  @override
  String get bonusXpLabel => 'Bonus XP';
  @override
  String get challengeCategoryWeeklyGoal => 'Weekly goal';
  @override
  String get challengeCategoryPunctuality => 'Punctuality';
  @override
  String get challengeCategoryWritingQuality => 'Writing quality';
  @override
  String get challengeCategoryFocusTime => 'Focus time';
  @override
  String get challengeCategoryStreak => 'Streak';
  @override
  String get aiStudyPlanTitle => 'AI study plan';
  @override
  String get doNowLabel => 'Do now';
  @override
  String get doNextLabel => 'Do next';
  @override
  String stretchGoalLabel(String value) => 'Stretch goal: $value';
  @override
  String mainSkillToImproveLabel(String value) =>
      'Main skill to improve: $value';
  @override
  String get openFocusTask => 'Open focus task';
  @override
  String get markFirstDone => 'Mark first done';
  @override
  String get deadlineRescuePlanTitle => 'Deadline rescue plan';
  @override
  String rescueApproachLabel(String value) => 'Approach: $value';
  @override
  String rescueRecommendedBlockLabel(String value) =>
      'Recommended block: $value';
  @override
  String get parentActionFeedTitle => 'Parent action feed';
  @override
  String tonightLabel(String value) => 'Tonight: $value';
  @override
  String recommendedActionTonightLabel(String value) =>
      'Recommended action tonight: $value';
  @override
  String get showDetails => 'Show details';
  @override
  String get hideDetails => 'Hide details';
  @override
  String get assignSuggestedTask => 'Assign suggested task';
  @override
  String get suggestedFollowupAssigned => 'Suggested follow-up task assigned';
  @override
  String get reviewSignalsTitle => 'Review signals';
  @override
  String get strengthsTitle => 'Strengths';
  @override
  String get nextStepsTitle => 'Next steps';
  @override
  String get aiRubricTitle => 'AI rubric';
  @override
  String get suggestedNextTaskTitle => 'Suggested next task';
  @override
  String difficultyLevelLabel(int value) => 'Level $value';
  @override
  String shortMinutesLabel(int value) => '$value min';
  @override
  String aiScoreCompactLabel(int value) => 'AI $value/100';
  @override
  String confidenceCompactLabel(int value) => '$value% confident';
  @override
  String aiScoreDetailedLabel(int value) => 'AI score: $value/100';
  @override
  String confidenceDetailedLabel(int value) => 'Confidence: $value%';
  @override
  String sourceLabel(String value) => 'Source: $value';
  @override
  String get rubricTemplatesTitle => 'Rubric templates';
  @override
  String get presetEssay => 'Essay';
  @override
  String get presetShortAnswer => 'Short answer';
  @override
  String get presetMathExplanation => 'Math explanation';
  @override
  String get presetScienceReport => 'Science report';
  @override
  String get presetReadingResponse => 'Reading response';
  @override
  String get presetProjectReflection => 'Project reflection';
  @override
  String highestPriorityLabel(String name, String reason) =>
      'Highest priority: $name • $reason';
  @override
  String challengeXpLabel(String title, int xp) => '$title +$xp XP';
  @override
  String positiveSignalLabel(String value) => 'Positive: $value';
  @override
  String get aiStatusLoading => 'AI status is loading...';
  @override
  String get aiStatusUnavailable => 'AI status is unavailable';
  @override
  String aiReadyStatus(String providerLabel) => '$providerLabel AI is ready';
  @override
  String aiUnavailableStatus(String providerLabel) =>
      '$providerLabel AI is unavailable';
  @override
  String get aiModeExternal => 'External provider';
  @override
  String get aiModeBuiltin => 'Built-in mode';
  @override
  String get aiModeUnavailable => 'Unavailable';
  @override
  String modeLabel(String value) => 'Mode: $value';
  @override
  String providerValueLabel(String value) => 'Provider: $value';
  @override
  String modelValueLabel(String value) => 'Model: $value';
  @override
  String endpointValueLabel(String value) => 'Endpoint: $value';
  @override
  String get unknownValue => 'unknown';

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
