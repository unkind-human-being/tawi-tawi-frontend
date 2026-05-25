import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_provider.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const Color darkGreen = Color(0xFF064E3B);
  static const Color mainGreen = Color(0xFF0F766E);
  static const Color softGreen = Color(0xFFEFFAF5);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _confirmedInfo = false;
  DateTime? _lastRegisterAttempt;

  @override
  void initState() {
    super.initState();

    _fullNameController.addListener(_refresh);
    _emailController.addListener(_refresh);
    _passwordController.addListener(_refresh);
    _confirmPasswordController.addListener(_refresh);
  }

  @override
  void dispose() {
    _fullNameController.removeListener(_refresh);
    _emailController.removeListener(_refresh);
    _passwordController.removeListener(_refresh);
    _confirmPasswordController.removeListener(_refresh);

    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {});
  }

  bool get _canSubmit {
    return _fullNameController.text.trim().length >= 2 &&
        _isValidEmail(_emailController.text.trim()) &&
        _passwordController.text.trim().length >= 8 &&
        _confirmPasswordController.text.trim() ==
            _passwordController.text.trim() &&
        _confirmedInfo;
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_confirmedInfo) {
      _showError('Please confirm that your information is correct.');
      return;
    }

    final DateTime now = DateTime.now();

    if (_lastRegisterAttempt != null &&
        now.difference(_lastRegisterAttempt!) < const Duration(seconds: 2)) {
      _showError('Please wait a moment before trying again.');
      return;
    }

    _lastRegisterAttempt = now;

    final AuthProvider authProvider = context.read<AuthProvider>();

    final bool success = await authProvider.register(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully.'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
        (_) => false,
      );

      return;
    }

    _showError(authProvider.errorMessage ?? 'Registration failed.');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDC2626),
      ),
    );
  }

  static bool _isValidEmail(String value) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
  }

  String? _validateFullName(String? value) {
    final String fullName = value?.trim() ?? '';

    if (fullName.isEmpty) {
      return 'Full name is required.';
    }

    if (fullName.length < 2) {
      return 'Full name must be at least 2 characters.';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final String email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Email is required.';
    }

    if (!_isValidEmail(email)) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final String password = value?.trim() ?? '';

    if (password.isEmpty) {
      return 'Password is required.';
    }

    if (password.length < 8) {
      return 'Password must be at least 8 characters.';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final String confirmPassword = value?.trim() ?? '';

    if (confirmPassword.isEmpty) {
      return 'Please confirm your password.';
    }

    if (confirmPassword != _passwordController.text.trim()) {
      return 'Passwords do not match.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider authProvider = context.watch<AuthProvider>();
    final bool isLoading = authProvider.isLoading;
    final bool submitEnabled = _canSubmit && !isLoading;

    return Scaffold(
      backgroundColor: softGreen,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              darkGreen,
              mainGreen,
              softGreen,
            ],
            stops: <double>[0.0, 0.38, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool isWide = constraints.maxWidth >= 850;

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWide ? 980 : 470,
                    ),
                    child: isWide
                        ? Row(
                            children: <Widget>[
                              const Expanded(
                                child: _RegisterHeroPanel(),
                              ),
                              const SizedBox(width: 28),
                              Expanded(
                                child: _RegisterCard(
                                  formKey: _formKey,
                                  fullNameController: _fullNameController,
                                  emailController: _emailController,
                                  passwordController: _passwordController,
                                  confirmPasswordController:
                                      _confirmPasswordController,
                                  obscurePassword: _obscurePassword,
                                  obscureConfirmPassword:
                                      _obscureConfirmPassword,
                                  confirmedInfo: _confirmedInfo,
                                  isLoading: isLoading,
                                  submitEnabled: submitEnabled,
                                  errorMessage: authProvider.errorMessage,
                                  onBack: () => Navigator.of(context).pop(),
                                  onTogglePassword: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  onToggleConfirmPassword: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                  },
                                  onConfirmChanged: (bool? value) {
                                    setState(() {
                                      _confirmedInfo = value ?? false;
                                    });
                                  },
                                  onRegister: _register,
                                  validateFullName: _validateFullName,
                                  validateEmail: _validateEmail,
                                  validatePassword: _validatePassword,
                                  validateConfirmPassword:
                                      _validateConfirmPassword,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: <Widget>[
                              _MobileHeader(
                                onBack: () => Navigator.of(context).pop(),
                              ),
                              const SizedBox(height: 20),
                              _RegisterCard(
                                formKey: _formKey,
                                fullNameController: _fullNameController,
                                emailController: _emailController,
                                passwordController: _passwordController,
                                confirmPasswordController:
                                    _confirmPasswordController,
                                obscurePassword: _obscurePassword,
                                obscureConfirmPassword:
                                    _obscureConfirmPassword,
                                confirmedInfo: _confirmedInfo,
                                isLoading: isLoading,
                                submitEnabled: submitEnabled,
                                errorMessage: authProvider.errorMessage,
                                onBack: () => Navigator.of(context).pop(),
                                onTogglePassword: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                onToggleConfirmPassword: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                                onConfirmChanged: (bool? value) {
                                  setState(() {
                                    _confirmedInfo = value ?? false;
                                  });
                                },
                                onRegister: _register,
                                validateFullName: _validateFullName,
                                validateEmail: _validateEmail,
                                validatePassword: _validatePassword,
                                validateConfirmPassword:
                                    _validateConfirmPassword,
                              ),
                              const SizedBox(height: 20),
                              const _FooterNote(),
                            ],
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader({
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
          child: const Icon(
            Icons.person_add_alt_1_rounded,
            color: Colors.white,
            size: 52,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Create Account',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 31,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Register as a public user',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.88),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RegisterHeroPanel extends StatelessWidget {
  const _RegisterHeroPanel();

  static const Color darkGreen = Color(0xFF064E3B);
  static const Color mainGreen = Color(0xFF0F766E);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            darkGreen,
            mainGreen,
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 34,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _PortalBadge(),
          const SizedBox(height: 34),
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.24),
              ),
            ),
            child: const Icon(
              Icons.person_add_alt_1_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Create your Tawi-Tawi public account.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              height: 1.12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Use one account to enter the Tawi-Tawi public portal, view local services, and access integrated public modules.',
            style: TextStyle(
              color: Color(0xFFD1FAE5),
              fontSize: 16,
              height: 1.55,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 28),
          const _HeroFeature(
            icon: Icons.verified_user_rounded,
            text: 'Secure account creation',
          ),
          const SizedBox(height: 12),
          const _HeroFeature(
            icon: Icons.map_rounded,
            text: 'Access local Tawi-Tawi services',
          ),
          const SizedBox(height: 12),
          const _HeroFeature(
            icon: Icons.health_and_safety_rounded,
            text: 'Separate RHU Social Health login inside Health',
          ),
          const SizedBox(height: 26),
          const _FooterNote(),
        ],
      ),
    );
  }
}

class _RegisterCard extends StatelessWidget {
  const _RegisterCard({
    required this.formKey,
    required this.fullNameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.confirmedInfo,
    required this.isLoading,
    required this.submitEnabled,
    required this.errorMessage,
    required this.onBack,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onConfirmChanged,
    required this.onRegister,
    required this.validateFullName,
    required this.validateEmail,
    required this.validatePassword,
    required this.validateConfirmPassword,
  });

  static const Color darkGreen = Color(0xFF064E3B);
  static const Color mainGreen = Color(0xFF0F766E);

  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final bool confirmedInfo;
  final bool isLoading;
  final bool submitEnabled;
  final String? errorMessage;
  final VoidCallback onBack;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final ValueChanged<bool?> onConfirmChanged;
  final VoidCallback onRegister;
  final String? Function(String?) validateFullName;
  final String? Function(String?) validateEmail;
  final String? Function(String?) validatePassword;
  final String? Function(String?) validateConfirmPassword;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: AutofillGroup(
        child: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Register',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: darkGreen,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Create your Tawi-Tawi public user account.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: fullNameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const <String>[
                  AutofillHints.name,
                ],
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Example: Juan Dela Cruz',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: validateFullName,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const <String>[
                  AutofillHints.email,
                ],
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'example@email.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: validateEmail,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: obscurePassword,
                textInputAction: TextInputAction.next,
                autofillHints: const <String>[
                  AutofillHints.newPassword,
                ],
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Minimum 8 characters',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: onTogglePassword,
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: validatePassword,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: obscureConfirmPassword,
                textInputAction: TextInputAction.done,
                autofillHints: const <String>[
                  AutofillHints.newPassword,
                ],
                onFieldSubmitted: (_) {
                  if (submitEnabled) {
                    onRegister();
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: 'Re-enter your password',
                  prefixIcon: const Icon(Icons.lock_reset_rounded),
                  suffixIcon: IconButton(
                    onPressed: onToggleConfirmPassword,
                    icon: Icon(
                      obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: validateConfirmPassword,
              ),
              const SizedBox(height: 18),
              _ConfirmBox(
                value: confirmedInfo,
                onChanged: isLoading ? null : onConfirmChanged,
              ),
              if (errorMessage != null && errorMessage!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                _InlineError(message: errorMessage!),
              ],
              const SizedBox(height: 22),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: submitEnabled ? onRegister : null,
                  icon: isLoading
                      ? const SizedBox(
                          width: 21,
                          height: 21,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.person_add_alt_1_rounded),
                  label: Text(
                    isLoading ? 'Creating Account...' : 'Create Account',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: submitEnabled
                        ? mainGreen
                        : const Color(0xFF94A3B8),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: isLoading ? null : onBack,
                icon: const Icon(Icons.login_rounded),
                label: const Text('Already have an account? Login'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: darkGreen,
                  side: const BorderSide(
                    color: Color(0xFFCBD5E1),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const _SecurityNote(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmBox extends StatelessWidget {
  const _ConfirmBox({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: value ? const Color(0xFFEFFAF5) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: value ? const Color(0xFF16A34A) : const Color(0xFFE5E7EB),
        ),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
        title: const Text(
          'I confirm my information is correct.',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: const Text(
          'This account is for the main Tawi-Tawi public portal.',
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFECACA),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF991B1B),
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.security_rounded,
            color: Color(0xFF0F766E),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your Tawi-Tawi account is separate from the RHU Social Health account inside the Health module.',
              style: TextStyle(
                color: Color(0xFF64748B),
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PortalBadge extends StatelessWidget {
  const _PortalBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
        ),
      ),
      child: const Text(
        'TAWI-TAWI PUBLIC PORTAL',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          letterSpacing: 0.7,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _HeroFeature extends StatelessWidget {
  const _HeroFeature({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _FooterNote extends StatelessWidget {
  const _FooterNote();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Secure registration powered by the Tawi-Tawi backend',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.9),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}