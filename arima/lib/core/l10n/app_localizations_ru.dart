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
}
