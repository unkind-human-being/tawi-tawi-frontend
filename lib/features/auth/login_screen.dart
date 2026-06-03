import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_provider.dart';
import 'register_screen.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color darkGreen = Color(0xFF064E3B);
  static const Color mainGreen = Color(0xFF0F766E);
  static const Color lightGreen = Color(0xFFEFFAF5);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  DateTime? _lastLoginAttempt;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_refresh);
    _passwordController.addListener(_refresh);
  }

  @override
  void dispose() {
    _emailController.removeListener(_refresh);
    _passwordController.removeListener(_refresh);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {});
  }

  bool get _canLogin {
    return _isValidEmail(_emailController.text.trim()) &&
        _passwordController.text.trim().isNotEmpty;
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final DateTime now = DateTime.now();

    if (_lastLoginAttempt != null &&
        now.difference(_lastLoginAttempt!) < const Duration(seconds: 2)) {
      _showError('Please wait a moment before trying again.');
      return;
    }

    _lastLoginAttempt = now;

    final AuthProvider authProvider = context.read<AuthProvider>();

    final bool success = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      _goToHome();
      return;
    }

    _showError(authProvider.errorMessage ?? 'Login failed. Please try again.');
  }

  Future<void> _loginWithGoogle() async {
    FocusScope.of(context).unfocus();

    final AuthProvider authProvider = context.read<AuthProvider>();

    final bool success = await authProvider.loginWithGoogle();

    if (!mounted) return;

    if (success) {
      _goToHome();
      return;
    }

    _showError(authProvider.errorMessage ?? 'Google login failed.');
  }

  Future<void> _loginWithMeta() async {
    FocusScope.of(context).unfocus();

    final AuthProvider authProvider = context.read<AuthProvider>();

    final bool success = await authProvider.loginWithMeta();

    if (!mounted) return;

    if (success) {
      _goToHome();
      return;
    }

    _showError(authProvider.errorMessage ?? 'Meta login failed.');
  }

  void _goToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
    );
  }

  void _openRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RegisterScreen(),
      ),
    );
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

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider authProvider = context.watch<AuthProvider>();
    final bool isLoading = authProvider.isLoading;

    return Scaffold(
      backgroundColor: lightGreen,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              darkGreen,
              mainGreen,
              lightGreen,
            ],
            stops: <double>[0.0, 0.42, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 460,
                ),
                child: Column(
                  children: <Widget>[
                    const _CompactHeader(),
                    const SizedBox(height: 20),
                    _LoginCard(
                      formKey: _formKey,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      obscurePassword: _obscurePassword,
                      isLoading: isLoading,
                      canLogin: _canLogin,
                      errorMessage: authProvider.errorMessage,
                      onTogglePassword: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      onLogin: _login,
                      onGoogleLogin: _loginWithGoogle,
                      onMetaLogin: _loginWithMeta,
                      onRegister: _openRegister,
                      validateEmail: _validateEmail,
                      validatePassword: _validatePassword,
                    ),
                    const SizedBox(height: 20),
                    const _FooterNote(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactHeader extends StatelessWidget {
  const _CompactHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
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
            Icons.waves_rounded,
            color: Colors.white,
            size: 54,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Tawi-Tawi App',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 31,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Public user access portal',
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

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.canLogin,
    required this.errorMessage,
    required this.onTogglePassword,
    required this.onLogin,
    required this.onGoogleLogin,
    required this.onMetaLogin,
    required this.onRegister,
    required this.validateEmail,
    required this.validatePassword,
  });

  static const Color darkGreen = Color(0xFF064E3B);
  static const Color mainGreen = Color(0xFF0F766E);

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final bool canLogin;
  final String? errorMessage;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;
  final VoidCallback onGoogleLogin;
  final VoidCallback onMetaLogin;
  final VoidCallback onRegister;
  final String? Function(String?) validateEmail;
  final String? Function(String?) validatePassword;

  @override
  Widget build(BuildContext context) {
    final bool submitEnabled = canLogin && !isLoading;

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
                'Welcome Back',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: darkGreen,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Login using your Tawi-Tawi public user account.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
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
                textInputAction: TextInputAction.done,
                autofillHints: const <String>[
                  AutofillHints.password,
                ],
                onFieldSubmitted: (_) {
                  if (submitEnabled) {
                    onLogin();
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(Icons.lock_outline),
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
              if (errorMessage != null && errorMessage!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                _InlineError(message: errorMessage!),
              ],
              const SizedBox(height: 22),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: submitEnabled ? onLogin : null,
                  icon: isLoading
                      ? const SizedBox(
                          width: 21,
                          height: 21,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.login_rounded),
                  label: Text(isLoading ? 'Logging in...' : 'Login'),
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
              const SizedBox(height: 22),
              const _DividerLabel(),
              const SizedBox(height: 18),
              _SocialButton(
                label: 'Login with Google',
                icon: Icons.g_mobiledata_rounded,
                onPressed: isLoading ? null : onGoogleLogin,
              ),
              const SizedBox(height: 12),
              _SocialButton(
                label: 'Login with Meta',
                icon: Icons.facebook_rounded,
                onPressed: isLoading ? null : onMetaLogin,
              ),
              const SizedBox(height: 18),
              TextButton(
                onPressed: isLoading ? null : onRegister,
                child: const Text(
                  'No account yet? Create account',
                  style: TextStyle(
                    color: darkGreen,
                    fontWeight: FontWeight.w800,
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

class _DividerLabel extends StatelessWidget {
  const _DividerLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Divider(
            color: Colors.grey.shade300,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or continue with',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.grey.shade300,
          ),
        ),
      ],
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
              'Your Tawi-Tawi account is separate from the RHU Social Health login inside the Health module.',
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

class _FooterNote extends StatelessWidget {
  const _FooterNote();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Secure authentication powered by the Tawi-Tawi backend',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.9),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  static const Color darkGreen = Color(0xFF064E3B);

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 28,
          color: onPressed == null ? const Color(0xFF94A3B8) : darkGreen,
        ),
        label: Text(label),
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
    );
  }
}