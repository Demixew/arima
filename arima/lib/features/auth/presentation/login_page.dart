import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/api_exception.dart';
import '../application/auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with TickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roleController = TextEditingController(text: 'student');

  bool _isLoading = false;
  bool _isRegister = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  String? _emailError;
  String? _passwordError;
  String? _nameError;

  late final AnimationController _fadeController;
  late final AnimationController _shakeController;
  late final AnimationController _slideController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _shakeAnimation;
  late final Animation<Offset> _slideAnimation;

  final GlobalKey _shakeKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _roleController.dispose();
    _fadeController.dispose();
    _shakeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _clearFieldErrors() {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _nameError = null;
      _errorMessage = null;
    });
  }

  bool _validateFields(AppLocalizations l10n) {
    bool isValid = true;

    if (_emailController.text.trim().isEmpty) {
      setState(() => _emailError = l10n.emailRequired);
      isValid = false;
    } else if (!_emailController.text.contains('@') ||
        !_emailController.text.contains('.')) {
      setState(() => _emailError = l10n.emailInvalid);
      isValid = false;
    } else {
      setState(() => _emailError = null);
    }

    if (_passwordController.text.isEmpty) {
      setState(() => _passwordError = l10n.passwordRequired);
      isValid = false;
    } else if (_passwordController.text.length < 8) {
      setState(() => _passwordError = l10n.passwordTooShort);
      isValid = false;
    } else {
      setState(() => _passwordError = null);
    }

    if (_isRegister) {
      if (_nameController.text.trim().isEmpty) {
        setState(() => _nameError = l10n.fullNameRequired);
        isValid = false;
      } else {
        setState(() => _nameError = null);
      }
    }

    return isValid;
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_validateFields(l10n)) {
      _shakeController.forward(from: 0);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authController = ref.read(authControllerProvider.notifier);

    if (_isRegister) {
      await authController.register(
        email: _emailController.text.trim(),
        fullName: _nameController.text.trim(),
        password: _passwordController.text.trim(),
        role: _roleController.text.trim(),
      );
    } else {
      await authController.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    }

    if (!mounted) return;

    final String? errorText = ref.read(authControllerProvider).whenOrNull(
      error: (Object error, _) => error is ApiException ? error.message : error.toString(),
    );

    if (errorText != null) {
      setState(() {
        if (errorText.contains('Invalid email or password')) {
          _errorMessage = l10n.invalidEmailOrPassword;
          _emailError = l10n.invalidCredentials;
          _passwordError = l10n.invalidCredentials;
          _shakeController.forward(from: 0);
        } else if (errorText.contains('already exists')) {
          _errorMessage = l10n.accountExists;
          _emailError = l10n.accountExists;
        } else {
          _errorMessage = errorText;
        }
      });
    }

    setState(() => _isLoading = false);
  }

  void _toggleMode() {
    _clearFieldErrors();
    setState(() => _isRegister = !_isRegister);
    _slideController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool wide = MediaQuery.sizeOf(context).width >= 600;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.06),
              theme.colorScheme.secondary.withValues(alpha: 0.04),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: wide
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildInfoPanel(theme),
                          const SizedBox(width: 48),
                          SlideTransition(
                            position: _slideAnimation,
                            child: _buildAuthCard(theme),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildInfoPanel(theme),
                          const SizedBox(height: 32),
                          SlideTransition(
                            position: _slideAnimation,
                            child: _buildAuthCard(theme),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPanel(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      constraints: const BoxConstraints(maxWidth: 380),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
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
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                l10n.appTitle,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _isRegister ? l10n.createAccount : l10n.welcomeBack,
              key: ValueKey(_isRegister),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _isRegister
                  ? l10n.addFirstTaskHint
                  : l10n.signIn,
              key: ValueKey('$_isRegister-desc'),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 36),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Wrap(
              key: ValueKey(_isRegister),
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFeatureChip(theme, Icons.assignment_rounded, l10n.tasksTab),
                _buildFeatureChip(theme, Icons.notifications_active_rounded, l10n.notifications),
                _buildFeatureChip(
                  theme,
                  Icons.psychology_rounded,
                  l10n.appFeatureAi,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(ThemeData theme, IconData icon, String label) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthCard(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final shakeOffset = _shakeAnimation.value * 12 *
            ((_shakeAnimation.value * 4).round() % 2 == 0 ? 1 : -1);
        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: child,
        );
      },
      child: Container(
        key: _shakeKey,
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: Text(
                  _isRegister ? l10n.register : l10n.signIn,
                  key: ValueKey(_isRegister),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _isRegister
                      ? l10n.createAccountSubtitle
                      : l10n.signInSubtitle,
                  key: ValueKey('$_isRegister-subtitle'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 28),
              if (_isRegister) ...[
                _buildTextField(
                  theme: theme,
                  controller: _nameController,
                  label: l10n.fullNameLabel,
                  icon: Icons.person_outline_rounded,
                  error: _nameError,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
              ],
              _buildTextField(
                theme: theme,
                controller: _emailController,
                label: l10n.emailLabel,
                icon: Icons.email_outlined,
                error: _emailError,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                theme: theme,
                controller: _passwordController,
                label: l10n.passwordLabel,
                icon: Icons.lock_outline_rounded,
                error: _passwordError,
                obscureText: _obscurePassword,
                textInputAction:
                    _isRegister ? TextInputAction.next : TextInputAction.done,
                onSubmitted: _isRegister ? null : (_) => _submit(),
                suffixIcon: AnimatedRotation(
                  turns: _obscurePassword ? 0 : 0.5,
                  duration: const Duration(milliseconds: 200),
                  child: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
              ),
              if (_isRegister) ...[
                const SizedBox(height: 16),
                _buildRoleSelector(theme),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 20),
                _buildErrorBanner(theme),
              ],
              const SizedBox(height: 28),
              _buildSubmitButton(theme),
              const SizedBox(height: 18),
              _buildToggleButton(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required ThemeData theme,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? error,
    TextInputType? keyboardType,
    bool obscureText = false,
    TextInputAction? textInputAction,
    void Function(String)? onSubmitted,
    Widget? suffixIcon,
  }) {
    final hasError = error != null;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        textInputAction: textInputAction,
        onFieldSubmitted: onSubmitted,
        onChanged: (_) {
          if (hasError) {
            _clearFieldErrors();
          }
        },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              icon,
              color: hasError
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          suffixIcon: suffixIcon,
          errorText: hasError ? error : null,
          filled: true,
          fillColor: hasError
              ? theme.colorScheme.errorContainer.withValues(alpha: 0.25)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: hasError
                  ? theme.colorScheme.error.withValues(alpha: 0.4)
                  : Colors.transparent,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: hasError
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: theme.colorScheme.error),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildRoleSelector(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;

    return DropdownButtonFormField<String>(
      initialValue: _roleController.text,
      decoration: InputDecoration(
        labelText: l10n.roleLabel,
        prefixIcon: const Icon(Icons.badge_outlined),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      ),
      items: [
        DropdownMenuItem(
          value: 'student',
          child: Row(
            children: [
              const Icon(Icons.school_outlined, size: 20),
              const SizedBox(width: 10),
              Text(l10n.roleStudent),
            ],
          ),
        ),
        DropdownMenuItem(
          value: 'teacher',
          child: Row(
            children: [
              const Icon(Icons.cast_for_education_outlined, size: 20),
              const SizedBox(width: 10),
              Text(l10n.roleTeacher),
            ],
          ),
        ),
        DropdownMenuItem(
          value: 'parent',
          child: Row(
            children: [
              const Icon(Icons.family_restroom_outlined, size: 20),
              const SizedBox(width: 10),
              Text(l10n.roleParent),
            ],
          ),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() => _roleController.text = value);
        }
      },
    );
  }

  Widget _buildErrorBanner(ThemeData theme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: (1 - value) * 0.5,
                  child: child,
                );
              },
              child: Icon(
                Icons.error_outline_rounded,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: SizedBox(
        height: 54,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: theme.colorScheme.onPrimary,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isRegister ? l10n.createAccountButton : l10n.signInButton,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildToggleButton(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isRegister ? l10n.alreadyHaveAccount : l10n.dontHaveAccount,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        TextButton(
          onPressed: _toggleMode,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: Text(
            _isRegister ? l10n.signInButton : l10n.register,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
