import 'package:flutter/material.dart';

import 'app_localizations.dart';

class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu() : super(const Locale('ru'));

  @override
  String get appTitle => 'Арима';
  @override
  String get welcomeBack => 'С возвращением!';
  @override
  String get createAccount => 'Создайте аккаунт';
  @override
  String get signIn => 'Вход';
  @override
  String get register => 'Регистрация';
  @override
  String get emailLabel => 'Электронная почта';
  @override
  String get passwordLabel => 'Пароль';
  @override
  String get fullNameLabel => 'Полное имя';
  @override
  String get roleLabel => 'Я...';
  @override
  String get signInButton => 'Войти';
  @override
  String get createAccountButton => 'Создать аккаунт';
  @override
  String get alreadyHaveAccount => 'Уже есть аккаунт?';
  @override
  String get dontHaveAccount => 'Нет аккаунта?';
  @override
  String get emailRequired => 'Укажите email';
  @override
  String get emailInvalid => 'Введите корректный email';
  @override
  String get passwordRequired => 'Введите пароль';
  @override
  String get passwordTooShort => 'Минимум 8 символов';
  @override
  String get fullNameRequired => 'Укажите имя';
  @override
  String get invalidCredentials => 'Неверные данные';
  @override
  String get accountExists => 'Пользователь уже зарегистрирован';
  @override
  String get somethingWentWrong =>
      'Что-то пошло не так. Попробуйте снова.';
  @override
  String get invalidEmailOrPassword =>
      'Неверный email или пароль. Попробуйте снова.';
  @override
  String get signInSubtitle =>
      'Войдите, чтобы продолжить обучение и отслеживание прогресса.';
  @override
  String get createAccountSubtitle =>
      'Создайте аккаунт, чтобы управлять заданиями и прогрессом.';
  @override
  String get appFeatureAi => 'ИИ';

  @override
  String get roleStudent => 'Ученик';
  @override
  String get roleTeacher => 'Учитель';
  @override
  String get roleParent => 'Родитель';

  @override
  String get tasksTab => 'Задания';
  @override
  String get profileTab => 'Профиль';
  @override
  String get statsTab => 'Статистика';
  @override
  String get addTask => 'Добавить задание';
  @override
  String get noTasksYet => 'Пока нет заданий';
  @override
  String get addFirstTaskHint =>
      'Нажмите +, чтобы добавить первое задание\nи начать отслеживать прогресс';
  @override
  String get somethingWentWrongRetry => 'Что-то пошло не так';
  @override
  String get retry => 'Повторить';
  @override
  String get refresh => 'Обновить';
  @override
  String get logout => 'Выйти';
  @override
  String get hello => 'Привет';
  @override
  String get submitTask => 'Сдать задание';
  @override
  String get cancel => 'Отмена';
  @override
  String get deleteTask => 'Удалить задание';
  @override
  String get deleteTaskConfirm => 'Вы уверены, что хотите удалить';
  @override
  String get yourSubmission => 'Ваш ответ';
  @override
  String get enterSubmissionHint => 'Введите ваш ответ...';
  @override
  String get taskSubmittedSuccess => 'Задание успешно отправлено!';
  @override
  String get graded => 'Оценено';
  @override
  String get submitted => 'Отправлено';
  @override
  String get gradeLabel => 'Оценка';
  @override
  String get teacherFeedback => 'Комментарий учителя';
  @override
  String get yourAnswer => 'Ваш ответ';
  @override
  String get today => 'Сегодня';
  @override
  String get tomorrow => 'Завтра';
  @override
  String get escalatedToParent => 'Эскалация выполнена!';
  @override
  String get parentAlerted => 'Родитель уведомлен!';
  @override
  String get updated => 'Обновлено';
  @override
  String get createFirstTask => 'Создать первое задание';
  @override
  String get filterAll => 'Все';
  @override
  String get filterActive => 'Активные';

  @override
  String get editProfile => 'Редактировать профиль';
  @override
  String get notifications => 'Уведомления';
  @override
  String get privacySecurity => 'Приватность и безопасность';
  @override
  String get helpSupport => 'Помощь и поддержка';
  @override
  String get notLoggedIn => 'Не авторизован';
  @override
  String get errorLoadingProfile => 'Ошибка загрузки профиля';
  @override
  String get language => 'Язык';
  @override
  String get languageRussian => 'Русский';
  @override
  String get languageEnglish => 'English';

  @override
  String get yourProgress => 'Ваш прогресс';
  @override
  String get completionRate => 'Процент выполнения';
  @override
  String get completed => 'Выполнено';
  @override
  String get remaining => 'Осталось';
  @override
  String get taskOverview => 'Обзор заданий';
  @override
  String get gamificationTitle => 'Путь прогресса';
  @override
  String get levelLabel => 'Уровень';
  @override
  String get xpLabel => 'XP';
  @override
  String get energyLabel => 'Энергия';
  @override
  String get badgesTitle => 'Награды';
  @override
  String get dailyChallengesTitle => 'Задания дня';
  @override
  String get nextRewardLabel => 'Следующая награда';
  @override
  String get noBadgesYet => 'Пока нет наград. Выполните задания, чтобы открыть первую.';
  @override
  String levelUpMessage(int level) => 'Новый уровень! Вы достигли уровня $level.';
  @override
  String badgeUnlockedMessage(String badgeTitle) =>
      'Новая награда: $badgeTitle';
  @override
  String get streakShieldTitle => 'Защитите серию';
  @override
  String streakShieldBody(int streak) =>
      'Выполните хотя бы одно задание сегодня, чтобы сохранить серию в $streak дн.';
  @override
  String get levelUpDialogAction => 'Продолжить';
  @override
  String get total => 'Всего';
  @override
  String get inProgress => 'В процессе';
  @override
  String get pending => 'В ожидании';
  @override
  String get overdue => 'Просрочено';

  @override
  String get studentsTab => 'Ученики';
  @override
  String get assignTab => 'Назначить';
  @override
  String get submissionsTab => 'Ответы';
  @override
  String get childrenTab => 'Дети';
  @override
  String get alertsTab => 'Оповещения';

  @override
  String get editTask => 'Редактировать задание';
  @override
  String get newTask => 'Новое задание';
  @override
  String get updateTaskDetails => 'Обновите детали задания';
  @override
  String get createNewTask => 'Создайте новое задание для отслеживания';
  @override
  String get taskTitle => 'Название задания';
  @override
  String get taskTitleHint => 'Что нужно сделать?';
  @override
  String get titleRequired => 'Введите название';
  @override
  String get descriptionOptional => 'Описание (необязательно)';
  @override
  String get descriptionHint => 'Добавьте подробности...';
  @override
  String get status => 'Статус';
  @override
  String get deadline => 'Дедлайн';
  @override
  String get noDeadlineSet => 'Дедлайн не установлен';
  @override
  String get smartReminders => 'Умные напоминания';
  @override
  String get remindEvery => 'Напоминать каждые';
  @override
  String get hours => 'часов';
  @override
  String get escalateAfter => 'Эскалировать после';
  @override
  String get misses => 'пропусков';
  @override
  String get reminderInfo =>
      'После максимального числа пропусков будет отправлено уведомление родителю';
  @override
  String get createTask => 'Создать задание';
  @override
  String get updateTask => 'Обновить задание';
  @override
  String get reminderHoursRange => 'Введите значение от 1 до 72 часов';
  @override
  String get reminderMissesRange => 'Введите значение от 1 до 20';

  @override
  String get statusPending => 'В ожидании';
  @override
  String get statusInProgress => 'В процессе';
  @override
  String get statusCompleted => 'Выполнено';
  @override
  String get statusOverdue => 'Просрочено';
  @override
  String get statusActive => 'Активен';
  @override
  String get statusInactive => 'Неактивен';

  @override
  String get linkStudent => 'Привязать ученика';
  @override
  String get studentEmail => 'Email ученика';
  @override
  String get studentEmailHint => 'student@example.com';
  @override
  String get taskAssignedSuccess => 'Задание успешно назначено!';
  @override
  String get assigned => 'Назначено';
  @override
  String get linkStudentsFirst => 'Сначала привяжите учеников';
  @override
  String get assignNewTask => 'Назначить новое задание';
  @override
  String get createTaskForStudent =>
      'Создайте новое задание для одного из ваших учеников.';
  @override
  String get selectStudent => 'Выберите ученика';
  @override
  String get dueDateOptional => 'Срок выполнения (необязательно)';
  @override
  String get requiresSubmission => 'Требуется сдача';
  @override
  String get studentMustSubmit =>
      'Ученик должен отправить ответ, чтобы завершить задание.';
  @override
  String get assignTask => 'Назначить задание';
  @override
  String get noPendingSubmissions => 'Нет ожидающих ответов';
  @override
  String get studentSubmissionsWillAppearHere =>
      'Ответы учеников будут появляться здесь для проверки.';
  @override
  String get task => 'Задание';
  @override
  String get submission => 'Ответ';
  @override
  String get gradeRange => 'Оценка (1-5)';
  @override
  String get selectGrade => 'Выберите оценку';
  @override
  String get feedbackOptional => 'Комментарий (необязательно)';
  @override
  String get enterFeedback => 'Введите комментарий для ученика...';
  @override
  String get submitGrade => 'Отправить оценку';
  @override
  String get noMetricsAvailable => 'Метрики пока недоступны.';
  @override
  String get teacherDashboard => 'Панель учителя';
  @override
  String get totalStudents => 'Всего учеников';
  @override
  String get assignedTasks => 'Назначено заданий';
  @override
  String get submissionsReceived => 'Получено ответов';
  @override
  String get pendingGrading => 'Ожидают проверки';
  @override
  String get averageGrade => 'Средняя оценка';
  @override
  String get noStudentsLinkedYet => 'Пока нет привязанных учеников';
  @override
  String get tapToLinkStudent => 'Нажмите +, чтобы привязать ученика';
  @override
  String get unknownStudent => 'Неизвестный ученик';
  @override
  String get justNow => 'только что';
  @override
  String get yesterday => 'вчера';
  @override
  String hoursAgo(int count) => '$count ч назад';
  @override
  String daysAgo(int count) => '$count дн. назад';
  @override
  String gradeForStudent(String studentName) => 'Оценить: $studentName';
  @override
  String get aiAssistant => 'ИИ-помощник';
  @override
  String get aiTaskPromptLabel => 'Какое задание нужно создать?';
  @override
  String get aiTaskPromptHint =>
      'Например: Создай мягкое задание по математике на дроби на завтра.';
  @override
  String get generateWithAi => 'Сгенерировать с ИИ';
  @override
  String get generatingDraft => 'Генерируем черновик...';
  @override
  String get applyAiDraft => 'Применить черновик';
  @override
  String get aiDraftReady => 'ИИ подготовил черновик';
  @override
  String get aiPromptRequired => 'Введите короткий запрос для ИИ';
  @override
  String aiModelLabel(String model) => 'Модель: $model';
  @override
  String get reviewModeLabel => 'Режим проверки';
  @override
  String get reviewModeTeacherOnly => 'Только учитель';
  @override
  String get reviewModeTeacherAndAi => 'ИИ и учитель';
  @override
  String get reviewModeAiOnly => 'Только ИИ';
  @override
  String get evaluationCriteriaLabel => 'Критерии оценки';
  @override
  String get evaluationCriteriaHint =>
      'Например: точность, логика решения, аккуратность ответа.';
  @override
  String get aiSuggestionTitle => 'Подсказка ИИ';
  @override
  String get aiSuggestedGrade => 'Оценка ИИ';
  @override
  String get aiSuggestedFeedback => 'Комментарий ИИ';
  @override
  String get finalTeacherDecision => 'Итоговое решение учителя';
  @override
  String get runAiReview => 'Запустить проверку ИИ';
  @override
  String get aiReviewCompleted => 'Проверка ИИ готова';
  @override
  String get aiReviewNeeded => 'Проверка ИИ еще не выполнена';
  @override
  String get reviewSummary => 'Сводка проверки';
  @override
  String get noSubmissionText => 'Текст ответа не добавлен.';
  @override
  String aiCheckedAtLabel(String value) => 'Проверено ИИ: $value';
  @override
  String get difficultyLabel => 'Сложность';
  @override
  String get difficultyHint =>
      'Низкий уровень — мягкая практика, высокий — более серьезный вызов.';
  @override
  String difficultyValue(int value) => 'Уровень $value';
  @override
  String get estimatedTimeLabel => 'Оценка времени';
  @override
  String get estimatedTimeHint => 'Сколько времени займет задание?';
  @override
  String estimatedTimeMinutes(int minutes) => '$minutes мин';
  @override
  String get estimatedTimeRange => 'Введите время от 1 до 480 минут';
  @override
  String get minutes => 'мин';
  @override
  String get antiFatigueLabel => 'Режим без усталости';
  @override
  String get antiFatigueHint =>
      'Показывает более спокойный, разбитый на части сценарий для длинных задач.';
  @override
  String get antiFatigueBannerTitle => 'План без усталости';
  @override
  String get antiFatigueBannerText =>
      'Лучше работать короткими отрезками с перерывом, чтобы задание не утомляло.';
  @override
  String get aiHelperTitle => 'ИИ-помощник';
  @override
  String get aiHelperSubtitle =>
      'Пусть ИИ предложит более мягкие сроки, сложность и формулировку задания.';

  @override
  String get linkChild => 'Привязать ребенка';
  @override
  String get childEmail => 'Email ребенка';
  @override
  String get childEmailHint => 'student@example.com';

  @override
  String get deleteTaskTitle => 'Удалить задание';
  @override
  String get submitTaskTitle => 'Сдать задание';
  @override
  String get link => 'Привязать';

  @override
  String get errorLoadingStats => 'Ошибка загрузки статистики';
  @override
  String get taskSyncedSuccess => 'Список заданий успешно синхронизирован.';

  @override
  String get tasksSectionTitle => 'Задания';
  @override
  String get tasksSectionSubtitle => 'Все задания в одном месте';
  @override
  String get refreshTasks => 'Обновить задания';
  @override
  String get totalTasks => 'Всего заданий';
  @override
  String get activeNow => 'Активные';
  @override
  String get completedTasks => 'Выполненные';
  @override
  String get escalations => 'Эскалации';
  @override
  String get noTasksInThisView => 'В этом разделе нет заданий';
  @override
  String get switchFilterOrCreate =>
      'Смените фильтр или создайте новое задание';
  @override
  String get showAllTasks => 'Показать все задания';
  @override
  String get noDescriptionYet => 'Описание пока не добавлено.';
  @override
  String get parentEscalationTriggered => 'Эскалация родителю выполнена.';
  @override
  String get edit => 'Редактировать';
  @override
  String get remindersPaused => 'Напоминания выключены';
  @override
  String noDeadlineValue() => 'Без дедлайна';
  @override
  String updatedAtLabel(String value) => 'Обновлено: $value';
  @override
  String reminderProgress(int missedCount, int maxMissedCount) =>
      '$missedCount/$maxMissedCount пропусков';
  @override
  String reminderEscalated(int missedCount) =>
      'Эскалация после $missedCount пропусков';
  @override
  String reminderSchedule(int hours, int misses) =>
      'Каждые $hours ч, после $misses пропусков эскалация';
  @override
  String get selectDate => 'Выбрать дату';
  @override
  String get selectTime => 'Выбрать время';
  @override
  String get clearDate => 'Очистить дату';
  @override
  String get reminderEnabled => 'Напоминание включено';
  @override
  String get reminderInterval => 'Интервал напоминаний (в часах)';
  @override
  String get maxMissesBeforeEscalation =>
      'Макс. пропусков до эскалации';
  @override
  String get studentWorkspace => 'Рабочее пространство ученика';
  @override
  String get taskActionFailed => 'Не удалось выполнить действие с заданием';
  @override
  String get connectionTimeout => 'Время ожидания соединения истекло';
  @override
  String get cannotReachBackend => 'Не удается подключиться к серверу';
  @override
  String get unexpectedNetworkError => 'Непредвиденная сетевая ошибка';
  @override
  String get deleteCannotBeUndone => 'Это действие нельзя отменить';
  @override
  String deleteTaskMessage(String title) =>
      'Удалить "$title"? Это действие нельзя отменить.';
  @override
  String gradeValue(int grade) => 'Оценка: $grade';
  @override
  String yourAnswerValue(String answer) => 'Ваш ответ: $answer';
  @override
  String teacherFeedbackValue(String feedback) =>
      'Комментарий учителя: $feedback';

  @override
  String get noChildrenLinkedYet => 'Пока нет привязанных детей';
  @override
  String get tapToLinkChild =>
      'Нажмите, чтобы привязать первого ребенка';
  @override
  String get tasks => 'Задания';
  @override
  String get done => 'Выполнено';
  @override
  String get streak => 'Серия';
  @override
  String get rate => 'Процент';
  @override
  String get viewStats => 'Посмотреть статистику';
  @override
  String get unlinkChild => 'Отвязать ребенка';
  @override
  String get confirmUnlink => 'Вы уверены, что хотите отвязать ребенка';
  @override
  String get unlink => 'Отвязать';
  @override
  String get noAlerts => 'Нет оповещений';
  @override
  String get childrenOnTrack => 'У всех детей все в порядке';
  @override
  String get selectChild => 'Выберите ребенка для просмотра статистики';
  @override
  String get goToChildrenTab =>
      'Перейдите на вкладку "Дети", чтобы привязать ребенка';
  @override
  String get statisticsOverview => 'Обзор статистики';
  @override
  String get currentStreak => 'Текущая серия';
  @override
  String get days => 'дн.';
  @override
  String childLabel(String childName) => 'Ребенок: $childName';
  @override
  String dueLabel(String date) => 'Срок: $date';
  @override
  String get untitledTask => 'Задание без названия';
  @override
  String get immediateAttention =>
      'Это задание требует немедленного внимания!';
  @override
  String get preparingWorkspace => 'Подготавливаем рабочее пространство';
  @override
  String get restoringSession =>
      'Восстанавливаем сессию и подключаемся к серверу.';
  @override
  String get aiReviewCheckingLabel => '\u0418\u0418 \u043f\u0440\u043e\u0432\u0435\u0440\u044f\u0435\u0442';
  @override
  String get aiReviewFailedLabel => '\u0418\u0418 \u043d\u0435 \u0441\u043f\u0440\u0430\u0432\u0438\u043b\u0441\u044f';
  @override
  String get aiReviewRunningTeacher =>
      '\u0418\u0418 \u0441\u0435\u0439\u0447\u0430\u0441 \u043f\u0440\u043e\u0432\u0435\u0440\u044f\u0435\u0442 \u0440\u0430\u0431\u043e\u0442\u0443. \u0420\u0443\u0447\u043d\u0430\u044f \u043e\u0446\u0435\u043d\u043a\u0430 \u0432\u0441\u0435 \u0435\u0449\u0435 \u0434\u043e\u0441\u0442\u0443\u043f\u043d\u0430.';
  @override
  String aiReviewFailedTeacher(String detail) =>
      '\u0418\u0418 \u043d\u0435 \u0441\u043c\u043e\u0433 \u0437\u0430\u0432\u0435\u0440\u0448\u0438\u0442\u044c \u043f\u0440\u043e\u0432\u0435\u0440\u043a\u0443: $detail';
  @override
  String get aiReviewFailedTeacherFallback =>
      '\u0418\u0418 \u043d\u0435 \u0441\u043c\u043e\u0433 \u0437\u0430\u0432\u0435\u0440\u0448\u0438\u0442\u044c \u043f\u0440\u043e\u0432\u0435\u0440\u043a\u0443. \u0412\u044b \u0432\u0441\u0435 \u0435\u0449\u0435 \u043c\u043e\u0436\u0435\u0442\u0435 \u043e\u0446\u0435\u043d\u0438\u0442\u044c \u0440\u0430\u0431\u043e\u0442\u0443 \u0432\u0440\u0443\u0447\u043d\u0443\u044e.';
  @override
  String get reviewTimelineSubmitted => '\u041e\u0442\u043f\u0440\u0430\u0432\u043b\u0435\u043d\u043e';
  @override
  String get reviewTimelineAiChecked => '\u0418\u0418 \u043f\u0440\u043e\u0432\u0435\u0440\u0438\u043b';
  @override
  String get reviewTimelineTeacherGraded => '\u0423\u0447\u0438\u0442\u0435\u043b\u044c \u043e\u0446\u0435\u043d\u0438\u043b';
  @override
  String get atRiskRadarTitle => '\u0420\u0430\u0434\u0430\u0440 \u0440\u0438\u0441\u043a\u0430';
  @override
  String get atRiskRadarSubtitle => '\u0421\u0440\u0430\u0437\u0443 \u0432\u0438\u0434\u043d\u043e, \u043a\u043e\u043c\u0443 \u043d\u0443\u0436\u043d\u0430 \u043f\u043e\u043c\u043e\u0449\u044c \u0438 \u043f\u043e\u0447\u0435\u043c\u0443.';
  @override
  String get riskNeedsAttention => '\u041d\u0443\u0436\u043d\u043e \u0432\u043d\u0438\u043c\u0430\u043d\u0438\u0435';
  @override
  String get riskWatch => '\u041f\u043e\u0434 \u043d\u0430\u0431\u043b\u044e\u0434\u0435\u043d\u0438\u0435\u043c';
  @override
  String get riskStable => '\u0421\u0442\u0430\u0431\u0438\u043b\u044c\u043d\u043e';
  @override
  String riskReasonLabel(String reason) => '\u041f\u0440\u0438\u0447\u0438\u043d\u0430 \u0440\u0438\u0441\u043a\u0430: $reason';
  @override
  String get viewTasks => '\u0417\u0430\u0434\u0430\u043d\u0438\u044f';
  @override
  String get viewSubmissions => '\u041e\u0442\u0432\u0435\u0442\u044b';
  @override
  String studentTasksTitle(String name) => '\u0417\u0430\u0434\u0430\u043d\u0438\u044f: $name';
  @override
  String get noStudentTasksYet => '\u041f\u043e\u043a\u0430 \u043d\u0435\u0442 \u043d\u0430\u0437\u043d\u0430\u0447\u0435\u043d\u043d\u044b\u0445 \u0437\u0430\u0434\u0430\u043d\u0438\u0439.';
  @override
  String get extendDeadline => '\u041f\u0440\u043e\u0434\u043b\u0438\u0442\u044c \u0434\u0435\u0434\u043b\u0430\u0439\u043d';
  @override
  String get deadlineUpdated => '\u0414\u0435\u0434\u043b\u0430\u0439\u043d \u043e\u0431\u043d\u043e\u0432\u043b\u0435\u043d';
  @override
  String get weeklyChallengeTitle => '\u041d\u0435\u0434\u0435\u043b\u044c\u043d\u044b\u0439 \u0447\u0435\u043b\u043b\u0435\u043d\u0434\u0436';
  @override
  String get weeklyChallengeSubtitle => '\u0421\u0434\u0435\u043b\u0430\u0439\u0442\u0435 \u0437\u0430\u0434\u0430\u043d\u0438\u0435 \u043e\u0441\u043e\u0431\u043e\u0439 \u043c\u0438\u0441\u0441\u0438\u0435\u0439 \u0441 \u0431\u043e\u043d\u0443\u0441\u043d\u044b\u043c XP.';
  @override
  String get challengeTitleLabel => '\u041d\u0430\u0437\u0432\u0430\u043d\u0438\u0435 \u0447\u0435\u043b\u043b\u0435\u043d\u0434\u0436\u0430';
  @override
  String get challengeCategoryLabel => '\u041a\u0430\u0442\u0435\u0433\u043e\u0440\u0438\u044f \u0447\u0435\u043b\u043b\u0435\u043d\u0434\u0436\u0430';
  @override
  String get bonusXpLabel => '\u0411\u043e\u043d\u0443\u0441 XP';
  @override
  String get challengeCategoryWeeklyGoal => '\u0426\u0435\u043b\u044c \u043d\u0435\u0434\u0435\u043b\u0438';
  @override
  String get challengeCategoryPunctuality => '\u041f\u0443\u043d\u043a\u0442\u0443\u0430\u043b\u044c\u043d\u043e\u0441\u0442\u044c';
  @override
  String get challengeCategoryWritingQuality => '\u041a\u0430\u0447\u0435\u0441\u0442\u0432\u043e \u043f\u0438\u0441\u044c\u043c\u0430';
  @override
  String get challengeCategoryFocusTime => '\u0412\u0440\u0435\u043c\u044f \u0444\u043e\u043a\u0443\u0441\u0430';
  @override
  String get challengeCategoryStreak => '\u0421\u0435\u0440\u0438\u044f';
  @override
  String get aiStudyPlanTitle => '\u0418\u0418-\u043f\u043b\u0430\u043d \u043d\u0430 \u0441\u0435\u0433\u043e\u0434\u043d\u044f';
  @override
  String get doNowLabel => '\u0421\u0434\u0435\u043b\u0430\u0442\u044c \u0441\u0435\u0439\u0447\u0430\u0441';
  @override
  String get doNextLabel => '\u0421\u0434\u0435\u043b\u0430\u0442\u044c \u043f\u043e\u0442\u043e\u043c';
  @override
  String stretchGoalLabel(String value) => '\u0414\u043e\u043f. \u0446\u0435\u043b\u044c: $value';
  @override
  String mainSkillToImproveLabel(String value) => '\u0413\u043b\u0430\u0432\u043d\u044b\u0439 \u0444\u043e\u043a\u0443\u0441: $value';
  @override
  String get openFocusTask => '\u041e\u0442\u043a\u0440\u044b\u0442\u044c \u0433\u043b\u0430\u0432\u043d\u043e\u0435 \u0437\u0430\u0434\u0430\u043d\u0438\u0435';
  @override
  String get markFirstDone => '\u041e\u0442\u043c\u0435\u0442\u0438\u0442\u044c \u043f\u0435\u0440\u0432\u044b\u043c \u0432\u044b\u043f\u043e\u043b\u043d\u0435\u043d\u043d\u044b\u043c';
  @override
  String get deadlineRescuePlanTitle => '\u041f\u043b\u0430\u043d \u0441\u043f\u0430\u0441\u0435\u043d\u0438\u044f \u0434\u0435\u0434\u043b\u0430\u0439\u043d\u0430';
  @override
  String rescueApproachLabel(String value) => '\u041f\u043e\u0434\u0445\u043e\u0434: $value';
  @override
  String rescueRecommendedBlockLabel(String value) => '\u0420\u0435\u043a\u043e\u043c\u0435\u043d\u0434\u043e\u0432\u0430\u043d\u043d\u044b\u0439 \u0431\u043b\u043e\u043a: $value';
  @override
  String get parentActionFeedTitle => '\u041f\u043e\u0434\u0441\u043a\u0430\u0437\u043a\u0430 \u0434\u043b\u044f \u0440\u043e\u0434\u0438\u0442\u0435\u043b\u044f';
  @override
  String tonightLabel(String value) => '\u0421\u0435\u0433\u043e\u0434\u043d\u044f \u0432\u0435\u0447\u0435\u0440\u043e\u043c: $value';
  @override
  String recommendedActionTonightLabel(String value) => '\u0420\u0435\u043a\u043e\u043c\u0435\u043d\u0434\u043e\u0432\u0430\u043d\u043d\u043e\u0435 \u0434\u0435\u0439\u0441\u0442\u0432\u0438\u0435 \u043d\u0430 \u0432\u0435\u0447\u0435\u0440: $value';
  @override
  String get showDetails => '\u041f\u043e\u043a\u0430\u0437\u0430\u0442\u044c \u0434\u0435\u0442\u0430\u043b\u0438';
  @override
  String get hideDetails => '\u0421\u043a\u0440\u044b\u0442\u044c \u0434\u0435\u0442\u0430\u043b\u0438';
  @override
  String get assignSuggestedTask => '\u041d\u0430\u0437\u043d\u0430\u0447\u0438\u0442\u044c \u043f\u0440\u0435\u0434\u043b\u043e\u0436\u0435\u043d\u043d\u043e\u0435 \u0437\u0430\u0434\u0430\u043d\u0438\u0435';
  @override
  String get suggestedFollowupAssigned => '\u041f\u0440\u0435\u0434\u043b\u043e\u0436\u0435\u043d\u043d\u043e\u0435 \u0437\u0430\u0434\u0430\u043d\u0438\u0435 \u043d\u0430\u0437\u043d\u0430\u0447\u0435\u043d\u043e';
  @override
  String get reviewSignalsTitle => '\u0421\u0438\u0433\u043d\u0430\u043b\u044b \u043f\u0440\u043e\u0432\u0435\u0440\u043a\u0438';
  @override
  String get strengthsTitle => '\u0421\u0438\u043b\u044c\u043d\u044b\u0435 \u0441\u0442\u043e\u0440\u043e\u043d\u044b';
  @override
  String get nextStepsTitle => '\u0421\u043b\u0435\u0434\u0443\u044e\u0449\u0438\u0435 \u0448\u0430\u0433\u0438';
  @override
  String get aiRubricTitle => '\u0418\u0418-\u0440\u0443\u0431\u0440\u0438\u043a\u0430';
  @override
  String get suggestedNextTaskTitle => '\u0421\u043b\u0435\u0434\u0443\u044e\u0449\u0435\u0435 \u0437\u0430\u0434\u0430\u043d\u0438\u0435';
  @override
  String difficultyLevelLabel(int value) => '\u0423\u0440\u043e\u0432\u0435\u043d\u044c $value';
  @override
  String shortMinutesLabel(int value) => '$value \u043c\u0438\u043d';
  @override
  String aiScoreCompactLabel(int value) => '\u0418\u0418 $value/100';
  @override
  String confidenceCompactLabel(int value) => '\u0443\u0432\u0435\u0440\u0435\u043d\u043d\u043e\u0441\u0442\u044c $value%';
  @override
  String aiScoreDetailedLabel(int value) => '\u041e\u0446\u0435\u043d\u043a\u0430 \u0418\u0418: $value/100';
  @override
  String confidenceDetailedLabel(int value) => '\u0423\u0432\u0435\u0440\u0435\u043d\u043d\u043e\u0441\u0442\u044c: $value%';
  @override
  String sourceLabel(String value) => '\u0418\u0441\u0442\u043e\u0447\u043d\u0438\u043a: $value';
  @override
  String get rubricTemplatesTitle => '\u0428\u0430\u0431\u043b\u043e\u043d\u044b \u0440\u0443\u0431\u0440\u0438\u043a';
  @override
  String get presetEssay => '\u042d\u0441\u0441\u0435';
  @override
  String get presetShortAnswer => '\u041a\u043e\u0440\u043e\u0442\u043a\u0438\u0439 \u043e\u0442\u0432\u0435\u0442';
  @override
  String get presetMathExplanation => '\u041e\u0431\u044a\u044f\u0441\u043d\u0435\u043d\u0438\u0435 \u043f\u043e \u043c\u0430\u0442\u0435\u043c\u0430\u0442\u0438\u043a\u0435';
  @override
  String get presetScienceReport => '\u041d\u0430\u0443\u0447\u043d\u044b\u0439 \u043e\u0442\u0447\u0435\u0442';
  @override
  String get presetReadingResponse => '\u041e\u0442\u043a\u043b\u0438\u043a \u043d\u0430 \u0442\u0435\u043a\u0441\u0442';
  @override
  String get presetProjectReflection => '\u0420\u0435\u0444\u043b\u0435\u043a\u0441\u0438\u044f \u043f\u043e \u043f\u0440\u043e\u0435\u043a\u0442\u0443';
  @override
  String highestPriorityLabel(String name, String reason) =>
      '\u0413\u043b\u0430\u0432\u043d\u044b\u0439 \u043f\u0440\u0438\u043e\u0440\u0438\u0442\u0435\u0442: $name • $reason';
  @override
  String challengeXpLabel(String title, int xp) => '$title +$xp XP';
  @override
  String positiveSignalLabel(String value) => '\u041f\u043e\u0437\u0438\u0442\u0438\u0432: $value';
  @override
  String get aiStatusLoading => '\u0421\u0442\u0430\u0442\u0443\u0441 \u0418\u0418 \u0437\u0430\u0433\u0440\u0443\u0436\u0430\u0435\u0442\u0441\u044f...';
  @override
  String get aiStatusUnavailable => '\u0421\u0442\u0430\u0442\u0443\u0441 \u0418\u0418 \u043d\u0435\u0434\u043e\u0441\u0442\u0443\u043f\u0435\u043d';
  @override
  String aiReadyStatus(String providerLabel) => '\u0418\u0418 $providerLabel \u0433\u043e\u0442\u043e\u0432';
  @override
  String aiUnavailableStatus(String providerLabel) =>
      '\u0418\u0418 $providerLabel \u043d\u0435\u0434\u043e\u0441\u0442\u0443\u043f\u0435\u043d';
  @override
  String get aiModeExternal => '\u0412\u043d\u0435\u0448\u043d\u0438\u0439 \u043f\u0440\u043e\u0432\u0430\u0439\u0434\u0435\u0440';
  @override
  String get aiModeBuiltin => '\u0412\u0441\u0442\u0440\u043e\u0435\u043d\u043d\u044b\u0439 \u0440\u0435\u0436\u0438\u043c';
  @override
  String get aiModeUnavailable => '\u041d\u0435\u0434\u043e\u0441\u0442\u0443\u043f\u043d\u043e';
  @override
  String modeLabel(String value) => '\u0420\u0435\u0436\u0438\u043c: $value';
  @override
  String providerValueLabel(String value) => '\u041f\u0440\u043e\u0432\u0430\u0439\u0434\u0435\u0440: $value';
  @override
  String modelValueLabel(String value) => '\u041c\u043e\u0434\u0435\u043b\u044c: $value';
  @override
  String endpointValueLabel(String value) => '\u042d\u043d\u0434\u043f\u043e\u0438\u043d\u0442: $value';
  @override
  String get unknownValue => '\u043d\u0435\u0438\u0437\u0432\u0435\u0441\u0442\u043d\u043e';
}
