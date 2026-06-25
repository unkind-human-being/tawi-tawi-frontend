import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../config/app_config.dart';
import '../../theme/app_theme.dart';
import '../../widgets/aurora_background.dart';
import '../../widgets/glass.dart';
import '../../widgets/app_logo.dart';

class LoginScreen extends StatefulWidget {
  /// Pre-fills the sign-in email (e.g. when a host user is sent here to sign in
  /// with their existing TDLF-Educ account).
  final String? prefillEmail;
  const LoginScreen({super.key, this.prefillEmail});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _emailCtrl;
  late TextEditingController _passwordCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _signupEmailCtrl;
  late TextEditingController _signupPasswordCtrl;
  late TextEditingController _fullNameCtrl;
  late TextEditingController _studentIdCtrl;
  bool _isSignUp = false;
  bool _showPassword = false;
  bool _showSignupPassword = false;
  String _selectedRole = AppConfig.userRoles[0];
  String _selectedCourse = AppConfig.courses[0];
  String _selectedGrade = AppConfig.gradeLevels[0];

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.prefillEmail ?? '');
    _passwordCtrl = TextEditingController();
    _usernameCtrl = TextEditingController();
    _signupEmailCtrl = TextEditingController();
    _signupPasswordCtrl = TextEditingController();
    _fullNameCtrl = TextEditingController();
    _studentIdCtrl = TextEditingController();
    // Load the live course list (anon-readable) so the teacher "Course You
    // Teach" picker stays in sync with the courses managed in Books.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().fetchCourses();
    });
  }

  /// Live course titles (falls back to the built-in defaults until loaded).
  List<String> _courseTitles(BuildContext context) => context
      .watch<CourseProvider>()
      .courses
      .map((c) => (c['title'] ?? '').toString())
      .where((t) => t.isNotEmpty)
      .toList();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _usernameCtrl.dispose();
    _signupEmailCtrl.dispose();
    _signupPasswordCtrl.dispose();
    _fullNameCtrl.dispose();
    _studentIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.signIn(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    if (success && mounted) {
      // If this screen was pushed on top of another route, pop so the app
      // underneath rebuilds as the now-signed-in user; otherwise go to home.
      final nav = Navigator.of(context);
      if (nav.canPop()) {
        nav.pop();
      } else {
        nav.pushReplacementNamed('/home');
      }
    }
  }

  Future<void> _handleSignUp() async {
    final auth = context.read<AuthProvider>();
    final isStudent = _selectedRole == 'Student';
    // Resolve to a course that actually exists in the live list, so what gets
    // saved matches what's shown (and what Books/Quizzes use).
    final titles = context
        .read<CourseProvider>()
        .courses
        .map((c) => (c['title'] ?? '').toString())
        .where((t) => t.isNotEmpty)
        .toList();
    final teacherCourse = titles.contains(_selectedCourse)
        ? _selectedCourse
        : (titles.isNotEmpty ? titles.first : '');
    final success = await auth.signUp(
      username: _usernameCtrl.text.trim(),
      email: _signupEmailCtrl.text.trim(),
      password: _signupPasswordCtrl.text,
      role: _selectedRole,
      course: _selectedRole == 'Teacher' ? teacherCourse : '',
      fullName: _fullNameCtrl.text.trim(),
      studentId: isStudent ? _studentIdCtrl.text.trim() : '',
      gradeLevel: isStudent ? _selectedGrade : '',
    );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created! Please sign in.')),
      );
      _emailCtrl.text = _signupEmailCtrl.text;
      _usernameCtrl.clear();
      _signupEmailCtrl.clear();
      _signupPasswordCtrl.clear();
      _fullNameCtrl.clear();
      _studentIdCtrl.clear();
      setState(() => _isSignUp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 32, 22, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 30),
                    _buildCard(context),
                    const SizedBox(height: 22),
                    _buildFooter(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final decor = AppDecoration.of(context);
    return Column(
      children: [
        const AppLogo(size: 84),
        const SizedBox(height: 20),
        ShaderMask(
          shaderCallback: (rect) => decor.brand.createShader(rect),
          child: const Text(
            'TDLF-Educ',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.8,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Learn smarter — anytime, offline.',
          style: TextStyle(
            fontSize: 14,
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GlassCard(
      strong: true,
      radius: 28,
      blur: 22,
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _isSignUp
                ? _buildSignUpForm(context, auth, cs)
                : _buildSignInForm(context, auth, cs),
          );
        },
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      'Your learning companion · v${AppConfig.appVersion}',
      style: TextStyle(
        fontSize: 12,
        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
      ),
    );
  }

  // ── Sign In ────────────────────────────────────────────────────────────────

  Widget _buildSignInForm(
      BuildContext context, AuthProvider auth, ColorScheme cs) {
    return Column(
      key: const ValueKey('signin'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Welcome back',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Sign in to continue learning',
          style: TextStyle(fontSize: 13.5, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 22),
        if (auth.errorMessage != null) ...[
          _ErrorBanner(message: auth.errorMessage!),
          const SizedBox(height: 16),
        ],
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.alternate_email_rounded),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _passwordCtrl,
          obscureText: !_showPassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => auth.isLoading ? null : _handleSignIn(),
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(_showPassword
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
        ),
        const SizedBox(height: 26),
        GradientButton(
          label: 'Sign In',
          icon: Icons.arrow_forward_rounded,
          loading: auth.isLoading,
          onPressed: auth.isLoading ? null : _handleSignIn,
        ),
        const SizedBox(height: 18),
        _SwitchRow(
          prompt: "Don't have an account?",
          action: 'Sign Up',
          onTap: () => setState(() => _isSignUp = true),
        ),
      ],
    );
  }

  // ── Sign Up ────────────────────────────────────────────────────────────────

  Widget _buildSignUpForm(
      BuildContext context, AuthProvider auth, ColorScheme cs) {
    return Column(
      key: const ValueKey('signup'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Create account',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Join TDLF-Educ today',
          style: TextStyle(fontSize: 13.5, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 22),
        if (auth.errorMessage != null) ...[
          _ErrorBanner(message: auth.errorMessage!),
          const SizedBox(height: 16),
        ],
        TextField(
          controller: _usernameCtrl,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Username',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _fullNameCtrl,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _signupEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.alternate_email_rounded),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _signupPasswordCtrl,
          obscureText: !_showSignupPassword,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(_showSignupPassword
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded),
              onPressed: () =>
                  setState(() => _showSignupPassword = !_showSignupPassword),
            ),
          ),
        ),
        // In the embedded host app only Students can sign up (teachers create
        // their account in the main app, then sign in here). So hide the role
        // picker and keep the role as Student.
        if (!auth.isEmbedded) ...[
          const SizedBox(height: 14),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Role',
              prefixIcon: Icon(Icons.verified_user_outlined),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedRole,
                isDense: true,
                isExpanded: true,
                borderRadius: BorderRadius.circular(16),
                items: AppConfig.userRoles
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedRole = v);
                },
              ),
            ),
          ),
        ],
        if (_selectedRole == 'Teacher') ...[
          const SizedBox(height: 14),
          Builder(builder: (context) {
            final titles = _courseTitles(context);
            // Always keep the dropdown's value among its items to avoid the
            // "value not in items" assertion that would break the form.
            final value = titles.contains(_selectedCourse)
                ? _selectedCourse
                : (titles.isNotEmpty ? titles.first : null);
            return InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Course You Teach',
                prefixIcon: Icon(Icons.class_outlined),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  isDense: true,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(16),
                  hint: const Text('Select a course'),
                  items: titles
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedCourse = v);
                  },
                ),
              ),
            );
          }),
        ],
        if (_selectedRole == 'Student') ...[
          const SizedBox(height: 14),
          TextField(
            controller: _studentIdCtrl,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Student ID',
              prefixIcon: Icon(Icons.badge_rounded),
            ),
          ),
          const SizedBox(height: 14),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Grade Level',
              prefixIcon: Icon(Icons.grade_outlined),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedGrade,
                isDense: true,
                isExpanded: true,
                borderRadius: BorderRadius.circular(16),
                items: AppConfig.gradeLevels
                    .map((g) => DropdownMenuItem(
                          value: g,
                          child: Text(g, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedGrade = v);
                },
              ),
            ),
          ),
        ],
        const SizedBox(height: 26),
        GradientButton(
          label: 'Create Account',
          icon: Icons.auto_awesome_rounded,
          loading: auth.isLoading,
          onPressed: auth.isLoading ? null : _handleSignUp,
        ),
        const SizedBox(height: 18),
        _SwitchRow(
          prompt: 'Already have an account?',
          action: 'Sign In',
          onTap: () => setState(() => _isSignUp = false),
        ),
      ],
    );
  }
}

// ── Shared bits ───────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: cs.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: cs.onErrorContainer,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String prompt;
  final String action;
  final VoidCallback onTap;

  const _SwitchRow({
    required this.prompt,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$prompt ',
          style: TextStyle(fontSize: 13.5, color: cs.onSurfaceVariant),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            action,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: cs.primary,
            ),
          ),
        ),
      ],
    );
  }
}
