import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/book_provider.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Map<String, dynamic>> _allTeachers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.currentUser != null) {
        context.read<QuizProvider>().loadQuizHistory(auth.currentUser!['id'] as String);
      }
      _loadTeachers();
    });
  }

  Future<void> _loadTeachers() async {
    final teachers = await context.read<AuthProvider>().getAllTeachers();
    if (mounted) setState(() => _allTeachers = teachers);
  }

  void _showEditDialog(BuildContext context, Map<String, dynamic> user) {
    final nameCtrl = TextEditingController(text: user['username'] as String? ?? '');
    final emailCtrl = TextEditingController(text: user['email'] as String? ?? '');
    final fullNameCtrl = TextEditingController(text: user['full_name'] as String? ?? '');
    final studentIdCtrl = TextEditingController(text: user['student_id'] as String? ?? '');
    final isTeacher = user['role'] == 'Teacher';
    final isStudent = user['role'] == 'Student';
    final rawCourse = user['course'] as String? ?? '';
    String selectedCourse = AppConfig.courses.contains(rawCourse) ? rawCourse : AppConfig.courses[0];
    final rawGrade = user['grade_level'] as String? ?? '';
    String selectedGrade =
        AppConfig.gradeLevels.contains(rawGrade) ? rawGrade : AppConfig.gradeLevels[0];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: fullNameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                if (isStudent) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: studentIdCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Student ID',
                      prefixIcon: Icon(Icons.badge_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Grade Level',
                      prefixIcon: Icon(Icons.grade_outlined),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedGrade,
                        isDense: true,
                        isExpanded: true,
                        items: AppConfig.gradeLevels
                            .map((g) => DropdownMenuItem(
                                  value: g,
                                  child: Text(g, overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setDialogState(() => selectedGrade = v);
                        },
                      ),
                    ),
                  ),
                ],
                if (isTeacher) ...[
                  const SizedBox(height: 12),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Course You Teach',
                      prefixIcon: Icon(Icons.class_outlined),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCourse,
                        isDense: true,
                        items: AppConfig.courses
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c, overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setDialogState(() => selectedCourse = v);
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final auth = context.read<AuthProvider>();
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                final data = <String, dynamic>{
                  'username': nameCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  'full_name': fullNameCtrl.text.trim(),
                  if (isTeacher) 'course': selectedCourse,
                  if (isStudent) 'student_id': studentIdCtrl.text.trim(),
                  if (isStudent) 'grade_level': selectedGrade,
                };
                final ok = await auth.updateCurrentUser(data);
                if (mounted) {
                  _loadTeachers();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(ok ? 'Profile updated!' : 'Update failed — email may already be in use.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.currentUser;
        if (user == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final isTeacher = user['role'] == 'Teacher';
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Edit Profile',
                onPressed: () => _showEditDialog(context, user),
              ),
            ],
          ),
          body: isTeacher
              ? _buildTeacherProfile(context, user)
              : _buildStudentProfile(context, user),
        );
      },
    );
  }

  // ─── Teacher Profile ────────────────────────────────────────────────────────

  Widget _buildTeacherProfile(BuildContext context, Map<String, dynamic> user) {
    final cs = Theme.of(context).colorScheme;
    final currentUserId = user['id'] as String;

    return RefreshIndicator(
      onRefresh: _loadTeachers,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TeacherHeaderCard(user: user, cs: cs),
            const SizedBox(height: 24),
            Row(children: [
              Icon(Icons.groups_rounded, size: 20, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                'Faculty Directory',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            if (_allTeachers.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(children: [
                    Icon(Icons.people_outline_rounded, size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                    const SizedBox(height: 8),
                    Text('No teachers found', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                  ]),
                ),
              )
            else
              ..._allTeachers.map(
                (t) => _FacultyCard(
                  teacher: t,
                  cs: cs,
                  isMe: (t['id'] as String?) == currentUserId,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Student Profile ────────────────────────────────────────────────────────

  Widget _buildStudentProfile(BuildContext context, Map<String, dynamic> user) {
    final cs = Theme.of(context).colorScheme;
    return Consumer2<QuizProvider, BookProvider>(
      builder: (context, quiz, books, _) {
        final history = quiz.quizHistory;
        final total = history.length;
        final correct = history.where((a) => a['is_correct'] == 1).length;
        final accuracy = total > 0 ? (correct / total) * 100 : 0.0;
        final downloadedCount = books.downloadedBooks.length;
        final rawDate = (user['created_at'] as String? ?? '').split('T')[0];
        final joinDate = rawDate.isNotEmpty ? rawDate : 'Unknown';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StudentHeaderCard(user: user, cs: cs, joinDate: joinDate),
              const SizedBox(height: 16),
              _PersonalInfoCard(user: user, cs: cs),
              const SizedBox(height: 20),
              _AccuracyRing(accuracy: accuracy, cs: cs),
              const SizedBox(height: 20),
              _StatsGrid2(
                total: total,
                correct: correct,
                downloads: downloadedCount,
                cs: cs,
              ),
              const SizedBox(height: 24),
              Row(children: [
                Icon(Icons.emoji_events_rounded, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'Achievements',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface),
                ),
              ]),
              const SizedBox(height: 12),
              _AchievementsGrid(total: total, accuracy: accuracy, downloads: downloadedCount, cs: cs),
              if (history.isNotEmpty) ...[
                const SizedBox(height: 24),
                Row(children: [
                  Icon(Icons.history_rounded, size: 20, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Recent Activity',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface),
                  ),
                ]),
                const SizedBox(height: 12),
                _RecentHistory(history: history.reversed.take(8).toList(), cs: cs),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

// ─── Teacher Header Card ──────────────────────────────────────────────────────

class _TeacherHeaderCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final ColorScheme cs;

  const _TeacherHeaderCard({required this.user, required this.cs});

  @override
  Widget build(BuildContext context) {
    final name = user['username'] as String? ?? 'Teacher';
    final email = user['email'] as String? ?? '';
    final course = user['course'] as String? ?? '';
    final rawDate = (user['created_at'] as String? ?? '').split('T')[0];
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'T';

    final decor = AppDecoration.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: decor.hero,
        borderRadius: BorderRadius.circular(26),
        boxShadow: decor.glow(0.4),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.star_rounded, color: Colors.white, size: 13),
                SizedBox(width: 4),
                Text('You', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 4)),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: cs.primary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(email, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          if (course.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.school_rounded, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(course, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add_rounded, color: Colors.white70, size: 14),
                SizedBox(width: 6),
                Text('Tap edit to add your course', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ]),
            ),
          ],
          if (rawDate.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Member since $rawDate', style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ],
      ),
    );
  }
}

// ─── Faculty Card ─────────────────────────────────────────────────────────────

class _FacultyCard extends StatelessWidget {
  final Map<String, dynamic> teacher;
  final ColorScheme cs;
  final bool isMe;

  const _FacultyCard({required this.teacher, required this.cs, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final name = teacher['username'] as String? ?? 'Unknown';
    final email = teacher['email'] as String? ?? '';
    final course = teacher['course'] as String? ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isMe ? cs.primaryContainer : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isMe
              ? cs.primary.withValues(alpha: 0.5)
              : cs.outlineVariant,
          width: isMe ? 1.5 : 1,
        ),
        boxShadow: AppDecoration.of(context).softShadow,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: isMe ? cs.primary : cs.secondaryContainer,
            child: Text(
              initial,
              style: TextStyle(
                color: isMe ? cs.onPrimary : cs.onSecondaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isMe ? cs.onPrimaryContainer : cs.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('You',
                          style: TextStyle(color: cs.onPrimary, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ]),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (course.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: isMe ? cs.primary.withValues(alpha: 0.15) : cs.secondaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _shortCourse(course),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isMe ? cs.primary : cs.onSecondaryContainer,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('—', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
            ),
        ],
      ),
    );
  }

  String _shortCourse(String course) {
    const map = {
      'Computer Fundamentals': 'Comp. Fund.',
      'Basic Mathematics': 'Mathematics',
      'Science and Technology': 'Sci & Tech',
      'English Communication': 'English',
    };
    return map[course] ?? course;
  }
}

// ─── Student Header Card ──────────────────────────────────────────────────────

class _StudentHeaderCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final ColorScheme cs;
  final String joinDate;

  const _StudentHeaderCard({required this.user, required this.cs, required this.joinDate});

  @override
  Widget build(BuildContext context) {
    final name = user['username'] as String? ?? 'Student';
    final email = user['email'] as String? ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';

    const studentGradient = LinearGradient(
      colors: [Color(0xFF6366F1), Color(0xFF22D3EE)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: studentGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22D3EE).withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 4)),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.person_rounded, color: Colors.white, size: 12),
              SizedBox(width: 5),
              Text('Student', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(email, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.calendar_today_rounded, color: Colors.white54, size: 12),
            const SizedBox(width: 4),
            Text('Member since $joinDate', style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ]),
        ],
      ),
    );
  }
}

// ─── Personal Info Card ───────────────────────────────────────────────────────

class _PersonalInfoCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final ColorScheme cs;

  const _PersonalInfoCard({required this.user, required this.cs});

  @override
  Widget build(BuildContext context) {
    final fullName = (user['full_name'] as String? ?? '').trim();
    final studentId = (user['student_id'] as String? ?? '').trim();
    final grade = (user['grade_level'] as String? ?? '').trim();
    final email = (user['email'] as String? ?? '').trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: AppDecoration.of(context).softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.contact_page_rounded, size: 20, color: cs.primary),
            const SizedBox(width: 8),
            Text(
              'Personal Info',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
          ]),
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.badge_outlined, label: 'Full Name', value: fullName, cs: cs),
          _InfoRow(icon: Icons.tag_rounded, label: 'Student ID', value: studentId, cs: cs),
          _InfoRow(icon: Icons.school_outlined, label: 'Grade Level', value: grade, cs: cs),
          _InfoRow(icon: Icons.email_outlined, label: 'Email', value: email, cs: cs),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme cs;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 1),
                Text(
                  hasValue ? value : 'Not set',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: hasValue
                        ? cs.onSurface
                        : cs.onSurfaceVariant.withValues(alpha: 0.6),
                    fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Accuracy Ring ────────────────────────────────────────────────────────────

class _AccuracyRing extends StatelessWidget {
  final double accuracy;
  final ColorScheme cs;

  const _AccuracyRing({required this.accuracy, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: accuracy / 100,
                    strokeWidth: 12,
                    backgroundColor: cs.surfaceContainerHighest,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  ShaderMask(
                    shaderCallback: (rect) =>
                        AppDecoration.of(context).brand.createShader(rect),
                    child: Text(
                      '${accuracy.toStringAsFixed(1)}%',
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.8),
                    ),
                  ),
                  Text('Accuracy', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _motivationalMessage(accuracy),
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _motivationalMessage(double acc) {
    if (acc == 0) return 'Take a quiz to start your journey!';
    if (acc < 50) return 'Keep going — every attempt builds knowledge!';
    if (acc < 75) return "Good progress! You're getting there.";
    if (acc < 90) return "Great work! You're above the passing mark.";
    return "Outstanding! You're a top performer!";
  }
}

// ─── Stats Grid ───────────────────────────────────────────────────────────────

class _StatsGrid2 extends StatelessWidget {
  final int total;
  final int correct;
  final int downloads;
  final ColorScheme cs;

  const _StatsGrid2({
    required this.total,
    required this.correct,
    required this.downloads,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final wrong = total - correct;
    return Column(children: [
      Row(children: [
        _StatTile(icon: Icons.quiz_rounded, value: '$total', label: 'Questions\nAnswered', cs: cs),
        const SizedBox(width: 10),
        _StatTile(icon: Icons.check_circle_rounded, value: '$correct', label: 'Correct\nAnswers', cs: cs, highlight: true),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        _StatTile(icon: Icons.cancel_rounded, value: '$wrong', label: 'Wrong\nAnswers', cs: cs),
        const SizedBox(width: 10),
        _StatTile(icon: Icons.download_done_rounded, value: '$downloads', label: 'Books\nDownloaded', cs: cs),
      ]),
    ]);
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final ColorScheme cs;
  final bool highlight;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.cs,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: highlight ? cs.primaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: highlight
                ? cs.primary.withValues(alpha: 0.25)
                : cs.outlineVariant,
          ),
          boxShadow: AppDecoration.of(context).softShadow,
        ),
        child: Row(children: [
          Icon(icon, size: 22, color: highlight ? cs.primary : cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: highlight ? cs.onPrimaryContainer : cs.onSurface,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: highlight ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ─── Achievements ─────────────────────────────────────────────────────────────

class _AchievementsGrid extends StatelessWidget {
  final int total;
  final double accuracy;
  final int downloads;
  final ColorScheme cs;

  const _AchievementsGrid({
    required this.total,
    required this.accuracy,
    required this.downloads,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final badges = [
      _Badge('🎯', 'First Step', 'Answer your first question', total > 0),
      _Badge('📚', 'Bookworm', 'Download a book', downloads > 0),
      _Badge('⭐', 'Scholar', 'Reach 75% accuracy', accuracy >= 75 && total > 0),
      _Badge('🔥', 'Dedicated', 'Answer 10+ questions', total >= 10),
      _Badge('🏆', 'Champion', 'Reach 90% accuracy', accuracy >= 90 && total > 0),
      _Badge('📖', 'Collector', 'Download 3+ books', downloads >= 3),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.88,
      children: badges.map((b) => _AchievementCard(badge: b, cs: cs)).toList(),
    );
  }
}

class _Badge {
  final String emoji;
  final String title;
  final String description;
  final bool unlocked;

  const _Badge(this.emoji, this.title, this.description, this.unlocked);
}

class _AchievementCard extends StatelessWidget {
  final _Badge badge;
  final ColorScheme cs;

  const _AchievementCard({required this.badge, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: badge.unlocked ? cs.primaryContainer : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: badge.unlocked ? Border.all(color: cs.primary.withValues(alpha: 0.3)) : null,
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(badge.unlocked ? badge.emoji : '🔒', style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 6),
          Text(
            badge.title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: badge.unlocked ? cs.onPrimaryContainer : cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (badge.unlocked)
            Text(
              badge.description,
              style: TextStyle(fontSize: 9, color: cs.onPrimaryContainer.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

// ─── Recent History ───────────────────────────────────────────────────────────

class _RecentHistory extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  final ColorScheme cs;

  const _RecentHistory({required this.history, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: history.map((attempt) {
        final isCorrect = attempt['is_correct'] == 1;
        final question = attempt['question'] as String? ?? 'Question';
        final answer = attempt['user_answer'] as String? ?? '—';
        final date = (attempt['attempted_at'] as String? ?? '').split('T')[0];

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCorrect ? cs.primaryContainer : cs.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCorrect ? Icons.check_rounded : Icons.close_rounded,
                  size: 16,
                  color: isCorrect ? cs.primary : cs.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: cs.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Your answer: $answer',
                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Text(date, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
