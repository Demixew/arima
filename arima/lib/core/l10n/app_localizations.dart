import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

abstract class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static List<LocalizationsDelegate<dynamic>> get localizationsDelegates => [
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('ru'),
    Locale('en'),
  ];

  String get appTitle;
  String get welcomeBack;
  String get createAccount;
  String get signIn;
  String get register;
  String get emailLabel;
  String get passwordLabel;
  String get fullNameLabel;
  String get roleLabel;
  String get signInButton;
  String get createAccountButton;
  String get alreadyHaveAccount;
  String get dontHaveAccount;
  String get emailRequired;
  String get emailInvalid;
  String get passwordRequired;
  String get passwordTooShort;
  String get fullNameRequired;
  String get invalidCredentials;
  String get accountExists;
  String get somethingWentWrong;
  String get invalidEmailOrPassword;
  String get signInSubtitle;
  String get createAccountSubtitle;
  String get appFeatureAi;

  String get roleStudent;
  String get roleTeacher;
  String get roleParent;

  String get tasksTab;
  String get profileTab;
  String get statsTab;
  String get addTask;
  String get noTasksYet;
  String get addFirstTaskHint;
  String get somethingWentWrongRetry;
  String get retry;
  String get refresh;
  String get logout;
  String get hello;
  String get submitTask;
  String get cancel;
  String get deleteTask;
  String get deleteTaskConfirm;
  String get yourSubmission;
  String get enterSubmissionHint;
  String get taskSubmittedSuccess;
  String get submittingTask => 'Submitting your answer...';
  String get aiReviewRunningStudent => 'AI is checking your answer now.';
  String get aiReviewReadyStudent => 'AI review is ready.';
  String get aiReviewFailedStudent =>
      'Your answer was saved, but AI review could not finish.';
  String get submissionSavedWaitingForTeacher =>
      'Your answer was saved and is waiting for teacher review.';
  String get graded;
  String get submitted;
  String get gradeLabel;
  String get teacherFeedback;
  String get yourAnswer;
  String get today;
  String get tomorrow;
  String get escalatedToParent;
  String get parentAlerted;
  String get updated;
  String get createFirstTask;
  String get filterAll;
  String get filterActive;

  String get editProfile;
  String get notifications;
  String get privacySecurity;
  String get helpSupport;
  String get notLoggedIn;
  String get errorLoadingProfile;
  String get language;
  String get languageRussian;
  String get languageEnglish;

  String get yourProgress;
  String get completionRate;
  String get completed;
  String get remaining;
  String get taskOverview;
  String get gamificationTitle;
  String get levelLabel;
  String get xpLabel;
  String get energyLabel;
  String get badgesTitle;
  String get dailyChallengesTitle;
  String get nextRewardLabel;
  String get noBadgesYet;
  String levelUpMessage(int level);
  String badgeUnlockedMessage(String badgeTitle);
  String get streakShieldTitle;
  String streakShieldBody(int streak);
  String get levelUpDialogAction;
  String get total;
  String get inProgress;
  String get pending;
  String get overdue;

  String get studentsTab;
  String get assignTab;
  String get submissionsTab;
  String get childrenTab;
  String get alertsTab;

  String get editTask;
  String get newTask;
  String get updateTaskDetails;
  String get createNewTask;
  String get taskTitle;
  String get taskTitleHint;
  String get titleRequired;
  String get descriptionOptional;
  String get descriptionHint;
  String get status;
  String get deadline;
  String get noDeadlineSet;
  String get smartReminders;
  String get remindEvery;
  String get hours;
  String get escalateAfter;
  String get misses;
  String get reminderInfo;
  String get createTask;
  String get updateTask;
  String get reminderHoursRange;
  String get reminderMissesRange;

  String get statusPending;
  String get statusInProgress;
  String get statusCompleted;
  String get statusOverdue;
  String get statusActive;
  String get statusInactive;

  String get linkStudent;
  String get studentEmail;
  String get studentEmailHint;
  String get taskAssignedSuccess;
  String get assigned;
  String get linkStudentsFirst;
  String get assignNewTask;
  String get createTaskForStudent;
  String get selectStudent;
  String get dueDateOptional;
  String get requiresSubmission;
  String get studentMustSubmit;
  String get assignTask;
  String get noPendingSubmissions;
  String get studentSubmissionsWillAppearHere;
  String get task;
  String get submission;
  String get gradeRange;
  String get selectGrade;
  String get feedbackOptional;
  String get enterFeedback;
  String get submitGrade;
  String get noMetricsAvailable;
  String get teacherDashboard;
  String get totalStudents;
  String get assignedTasks;
  String get submissionsReceived;
  String get pendingGrading;
  String get averageGrade;
  String get noStudentsLinkedYet;
  String get tapToLinkStudent;
  String get unknownStudent;
  String get justNow;
  String get yesterday;
  String hoursAgo(int count);
  String daysAgo(int count);
  String gradeForStudent(String studentName);
  String get aiAssistant;
  String get aiTaskPromptLabel;
  String get aiTaskPromptHint;
  String get generateWithAi;
  String get generatingDraft;
  String get applyAiDraft;
  String get aiDraftReady;
  String get aiPromptRequired;
  String aiModelLabel(String model);
  String get reviewModeLabel;
  String get reviewModeTeacherOnly;
  String get reviewModeTeacherAndAi;
  String get reviewModeAiOnly;
  String get evaluationCriteriaLabel;
  String get evaluationCriteriaHint;
  String get aiSuggestionTitle;
  String get aiSuggestedGrade;
  String get aiSuggestedFeedback;
  String get finalTeacherDecision;
  String get runAiReview;
  String get aiReviewCompleted;
  String get aiReviewNeeded;
  String get reviewSummary;
  String get noSubmissionText;
  String aiCheckedAtLabel(String value);
  String get aiReviewCheckingLabel => 'AI checking';
  String get aiReviewFailedLabel => 'AI failed';
  String get aiReviewRunningTeacher =>
      'AI review is running. Manual grading is still available.';
  String aiReviewFailedTeacher(String detail) => 'AI review failed: $detail';
  String get aiReviewFailedTeacherFallback =>
      'AI review failed. You can still grade this manually.';
  String get reviewTimelineSubmitted => 'Submitted';
  String get reviewTimelineAiChecked => 'AI checked';
  String get reviewTimelineTeacherGraded => 'Teacher graded';
  String get difficultyLabel;
  String get difficultyHint;
  String difficultyValue(int value);
  String get estimatedTimeLabel;
  String get estimatedTimeHint;
  String estimatedTimeMinutes(int minutes);
  String get estimatedTimeRange;
  String get minutes;
  String get antiFatigueLabel;
  String get antiFatigueHint;
  String get antiFatigueBannerTitle;
  String get antiFatigueBannerText;
  String get aiHelperTitle;
  String get aiHelperSubtitle;
  String get atRiskRadarTitle;
  String get atRiskRadarSubtitle;
  String get riskNeedsAttention;
  String get riskWatch;
  String get riskStable;
  String riskReasonLabel(String reason);
  String get viewTasks;
  String get viewSubmissions;
  String studentTasksTitle(String name);
  String get noStudentTasksYet;
  String get extendDeadline;
  String get deadlineUpdated;
  String get weeklyChallengeTitle;
  String get weeklyChallengeSubtitle;
  String get challengeTitleLabel;
  String get challengeCategoryLabel;
  String get bonusXpLabel;
  String get challengeCategoryWeeklyGoal;
  String get challengeCategoryPunctuality;
  String get challengeCategoryWritingQuality;
  String get challengeCategoryFocusTime;
  String get challengeCategoryStreak;
  String get aiStudyPlanTitle;
  String get doNowLabel;
  String get doNextLabel;
  String stretchGoalLabel(String value);
  String mainSkillToImproveLabel(String value);
  String get openFocusTask;
  String get markFirstDone;
  String get deadlineRescuePlanTitle;
  String rescueApproachLabel(String value);
  String rescueRecommendedBlockLabel(String value);
  String get parentActionFeedTitle;
  String tonightLabel(String value);
  String recommendedActionTonightLabel(String value);
  String get showDetails;
  String get hideDetails;
  String get assignSuggestedTask;
  String get suggestedFollowupAssigned;
  String get reviewSignalsTitle;
  String get strengthsTitle;
  String get nextStepsTitle;
  String get aiRubricTitle;
  String get suggestedNextTaskTitle;
  String difficultyLevelLabel(int value);
  String shortMinutesLabel(int value);
  String aiScoreCompactLabel(int value);
  String confidenceCompactLabel(int value);
  String aiScoreDetailedLabel(int value);
  String confidenceDetailedLabel(int value);
  String sourceLabel(String value);
  String get rubricTemplatesTitle;
  String get presetEssay;
  String get presetShortAnswer;
  String get presetMathExplanation;
  String get presetScienceReport;
  String get presetReadingResponse;
  String get presetProjectReflection;
  String highestPriorityLabel(String name, String reason);
  String challengeXpLabel(String title, int xp);
  String positiveSignalLabel(String value);
  String get aiStatusLoading;
  String get aiStatusUnavailable;
  String aiReadyStatus(String providerLabel);
  String aiUnavailableStatus(String providerLabel);
  String get aiModeExternal;
  String get aiModeBuiltin;
  String get aiModeUnavailable;
  String modeLabel(String value);
  String providerValueLabel(String value);
  String modelValueLabel(String value);
  String endpointValueLabel(String value);
  String get unknownValue;

  String get linkChild;
  String get childEmail;
  String get childEmailHint;

  String get deleteTaskTitle;
  String get submitTaskTitle;
  String get link;

  String get errorLoadingStats;
  String get taskSyncedSuccess;

  String get tasksSectionTitle;
  String get tasksSectionSubtitle;
  String get refreshTasks;
  String get totalTasks;
  String get activeNow;
  String get completedTasks;
  String get escalations;
  String get noTasksInThisView;
  String get switchFilterOrCreate;
  String get showAllTasks;
  String get noDescriptionYet;
  String get parentEscalationTriggered;
  String get edit;
  String get remindersPaused;
  String noDeadlineValue();
  String updatedAtLabel(String value);
  String reminderProgress(int missedCount, int maxMissedCount);
  String reminderEscalated(int missedCount);
  String reminderSchedule(int hours, int misses);
  String get selectDate;
  String get selectTime;
  String get clearDate;
  String get reminderEnabled;
  String get reminderInterval;
  String get maxMissesBeforeEscalation;
  String get studentWorkspace;
  String get taskActionFailed;
  String get connectionTimeout;
  String get cannotReachBackend;
  String get unexpectedNetworkError;
  String get deleteCannotBeUndone;
  String deleteTaskMessage(String title);
  String gradeValue(int grade);
  String yourAnswerValue(String answer);
  String teacherFeedbackValue(String feedback);

  String get noChildrenLinkedYet;
  String get tapToLinkChild;
  String get tasks;
  String get done;
  String get streak;
  String get rate;
  String get viewStats;
  String get unlinkChild;
  String get confirmUnlink;
  String get unlink;
  String get noAlerts;
  String get childrenOnTrack;
  String get selectChild;
  String get goToChildrenTab;
  String get statisticsOverview;
  String get currentStreak;
  String get days;
  String childLabel(String childName);
  String dueLabel(String date);
  String get untitledTask;
  String get immediateAttention;
  String get preparingWorkspace;
  String get restoringSession;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return <String>['ru', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'ru':
        return AppLocalizationsRu();
      case 'en':
        return AppLocalizationsEn();
      default:
        return AppLocalizationsRu();
    }
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
