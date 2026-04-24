import '../../../core/l10n/app_localizations.dart';

enum AppRole {
  student,
  teacher,
  parent;

  String label(AppLocalizations l10n) {
    switch (this) {
      case AppRole.student:
        return l10n.roleStudent;
      case AppRole.teacher:
        return l10n.roleTeacher;
      case AppRole.parent:
        return l10n.roleParent;
    }
  }
}
