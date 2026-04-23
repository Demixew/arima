enum AppRole {
  student,
  teacher,
  parent;

  String get label {
    switch (this) {
      case AppRole.student:
        return 'Student';
      case AppRole.teacher:
        return 'Teacher';
      case AppRole.parent:
        return 'Parent';
    }
  }
}
