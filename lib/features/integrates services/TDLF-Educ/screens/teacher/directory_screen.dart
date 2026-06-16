import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../services/api_service.dart';

/// Teacher-only directory: browse every teacher and every student with their
/// info. Tapping a student opens their profile + quiz progress.
class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late final TabController _tab = TabController(length: 2, vsync: this);

  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _students = [];
  Map<String, List<Map<String, dynamic>>> _resultsByStudent = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final courseProv = context.read<CourseProvider>();
    await courseProv.fetchCourses();
    final teachers = await auth.getAllTeachers();
    final students = await auth.getAllStudents();
    final results = await _api.getStudents();

    // Scope a student's shown progress to the viewing teacher's course.
    final teacherCourse = (auth.currentUser?['course'] ?? '').toString().trim();
    final myCourseIds = courseProv.courses
        .where((c) => (c['title'] ?? '').toString() == teacherCourse)
        .map((c) => c['id'].toString())
        .toSet();
    final scoped = (teacherCourse.isEmpty || myCourseIds.isEmpty)
        ? results
        : results.where((r) {
            final cid = (r['course_id'] ?? '').toString();
            return cid.isEmpty || myCourseIds.contains(cid);
          }).toList();

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final r in scoped) {
      final id = r['student_id']?.toString() ?? '';
      if (id.isEmpty) continue;
      grouped.putIfAbsent(id, () => []).add(r);
    }

    if (!mounted) return;
    setState(() {
      _teachers = teachers;
      _students = students;
      _resultsByStudent = grouped;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _load,
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: [
            Tab(text: 'Teachers (${_teachers.length})'),
            Tab(text: 'Students (${_students.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [
                _buildTeachers(cs),
                _buildStudents(cs),
              ],
            ),
    );
  }

  Widget _buildTeachers(ColorScheme cs) {
    if (_teachers.isEmpty) return _empty(cs, 'No teachers found');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _teachers.length,
        itemBuilder: (context, i) {
          final t = _teachers[i];
          final name = (t['username'] ?? 'Unknown').toString();
          final email = (t['email'] ?? '').toString();
          final course = (t['course'] ?? '').toString();
          return _PersonCard(
            cs: cs,
            initial: name.isNotEmpty ? name[0].toUpperCase() : '?',
            title: name,
            subtitle: email,
            trailing: course.isNotEmpty
                ? _Chip(text: course, cs: cs)
                : null,
          );
        },
      ),
    );
  }

  Widget _buildStudents(ColorScheme cs) {
    if (_students.isEmpty) return _empty(cs, 'No students found');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _students.length,
        itemBuilder: (context, i) {
          final s = _students[i];
          final name = (s['username'] ?? 'Unknown').toString();
          final fullName = (s['full_name'] ?? '').toString().trim();
          final grade = (s['grade_level'] ?? '').toString().trim();
          final subs = _resultsByStudent[s['id']?.toString()] ?? const [];
          return _PersonCard(
            cs: cs,
            initial: name.isNotEmpty ? name[0].toUpperCase() : '?',
            title: name,
            subtitle: fullName.isNotEmpty ? fullName : (s['email'] ?? '').toString(),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (grade.isNotEmpty) _Chip(text: grade, cs: cs),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: cs.onSurfaceVariant),
              ],
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StudentProfileScreen(
                  student: s,
                  submissions: List<Map<String, dynamic>>.from(subs),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _empty(ColorScheme cs, String text) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(Icons.people_outline_rounded,
            size: 56, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
        const SizedBox(height: 12),
        Center(
          child: Text(text,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// Person card
// ──────────────────────────────────────────────

class _PersonCard extends StatelessWidget {
  final ColorScheme cs;
  final String initial;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _PersonCard({
    required this.cs,
    required this.initial,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: cs.primaryContainer,
          child: Text(
            initial,
            style: TextStyle(
              color: cs.onPrimaryContainer,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14, color: cs.onSurface),
        ),
        subtitle: subtitle.isEmpty
            ? null
            : Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
        trailing: trailing,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final ColorScheme cs;
  const _Chip({required this.text, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: cs.onSecondaryContainer,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Student profile + progress
// ──────────────────────────────────────────────

class StudentProfileScreen extends StatelessWidget {
  final Map<String, dynamic> student;
  final List<Map<String, dynamic>> submissions;

  const StudentProfileScreen({
    super.key,
    required this.student,
    required this.submissions,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = (student['username'] ?? 'Student').toString();
    final fullName = (student['full_name'] ?? '').toString().trim();
    final email = (student['email'] ?? '').toString().trim();
    final studentId = (student['student_id'] ?? '').toString().trim();
    final grade = (student['grade_level'] ?? '').toString().trim();

    final total = submissions.length;
    final passed = submissions.where((r) => r['passed'] == true).length;
    final avg = total == 0
        ? 0.0
        : submissions.fold<double>(
                0, (s, r) => s + ((r['score'] as num?)?.toDouble() ?? 0)) /
            total;
    final best = submissions.fold<double>(0, (b, r) {
      final v = (r['score'] as num?)?.toDouble() ?? 0;
      return v > b ? v : b;
    });

    final sorted = [...submissions]..sort((a, b) =>
        (b['submitted_at'] ?? '').toString().compareTo(
            (a['submitted_at'] ?? '').toString()));

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                Text(name,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                if (fullName.isNotEmpty)
                  Text(fullName,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Personal info
          _InfoCard(cs: cs, rows: [
            ('Full Name', fullName, Icons.badge_outlined),
            ('Email', email, Icons.email_outlined),
            ('Student ID', studentId, Icons.tag_rounded),
            ('Grade Level', grade, Icons.school_outlined),
          ]),
          const SizedBox(height: 20),
          // Progress
          Row(children: [
            Icon(Icons.insights_rounded, size: 20, color: cs.primary),
            const SizedBox(width: 8),
            Text('Quiz Progress',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface)),
          ]),
          const SizedBox(height: 12),
          if (total == 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Text('No quiz attempts yet.',
                  style: TextStyle(color: cs.onSurfaceVariant)),
            )
          else ...[
            Row(children: [
              _Stat(cs: cs, value: '$total', label: 'Attempts'),
              const SizedBox(width: 10),
              _Stat(cs: cs, value: '$passed', label: 'Passed'),
              const SizedBox(width: 10),
              _Stat(cs: cs, value: '${avg.toStringAsFixed(0)}%', label: 'Avg'),
              const SizedBox(width: 10),
              _Stat(cs: cs, value: '${best.toStringAsFixed(0)}%', label: 'Best'),
            ]),
            const SizedBox(height: 14),
            for (final r in sorted) _AttemptRow(cs: cs, result: r),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final ColorScheme cs;
  final List<(String, String, IconData)> rows;
  const _InfoCard({required this.cs, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          for (final (label, value, icon) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
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
                        Text(label,
                            style: TextStyle(
                                fontSize: 11, color: cs.onSurfaceVariant)),
                        Text(
                          value.isEmpty ? 'Not set' : value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: value.isEmpty
                                ? cs.onSurfaceVariant.withValues(alpha: 0.6)
                                : cs.onSurface,
                            fontStyle:
                                value.isEmpty ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                      ],
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

class _Stat extends StatelessWidget {
  final ColorScheme cs;
  final String value;
  final String label;
  const _Stat({required this.cs, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cs.primary)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _AttemptRow extends StatelessWidget {
  final ColorScheme cs;
  final Map<String, dynamic> result;
  const _AttemptRow({required this.cs, required this.result});

  @override
  Widget build(BuildContext context) {
    final score = (result['score'] as num?)?.toDouble() ?? 0;
    final isPassed = result['passed'] == true;
    final date = (result['submitted_at'] ?? '').toString().split('T').first;
    final totalQ = result['total_questions'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPassed ? cs.primaryContainer : cs.errorContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(isPassed ? Icons.check_rounded : Icons.close_rounded,
                color: isPassed ? cs.onPrimaryContainer : cs.onErrorContainer,
                size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isPassed ? 'Passed' : 'Failed',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isPassed ? cs.primary : cs.error)),
                Text('$totalQ questions · $date',
                    style:
                        TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Text('${score.toStringAsFixed(0)}%',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isPassed ? cs.primary : cs.error)),
        ],
      ),
    );
  }
}
