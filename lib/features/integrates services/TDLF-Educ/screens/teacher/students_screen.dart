import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'directory_screen.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final ApiService _api = ApiService();
  Map<String, List<Map<String, dynamic>>> _grouped = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    final data = await _api.getStudents();
    if (mounted) {
      final grouped = <String, List<Map<String, dynamic>>>{};
      for (final r in data) {
        final id = r['student_id']?.toString() ?? 'unknown';
        grouped.putIfAbsent(id, () => []).add(r);
      }
      setState(() {
        _grouped = grouped;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.contacts_rounded),
            tooltip: 'Directory',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DirectoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadStudents,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _grouped.isEmpty
              ? _buildEmpty(cs)
              : Column(
                  children: [
                    _buildSummaryHeader(cs),
                    Expanded(child: _buildStudentList(cs)),
                  ],
                ),
    );
  }

  Widget _buildEmpty(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.people_outline_rounded, size: 40, color: cs.onPrimaryContainer),
          ),
          const SizedBox(height: 20),
          Text(
            'No submissions yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: cs.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            'Student quiz results will appear here\nonce they complete a quiz.',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(ColorScheme cs) {
    final allResults = _grouped.values.expand((e) => e).toList();
    final uniqueStudents = _grouped.length;
    final passed = allResults.where((r) => r['passed'] == true).length;
    final avgScore = allResults.isEmpty
        ? 0.0
        : allResults.fold<double>(0, (s, r) => s + (r['score'] as num).toDouble()) /
            allResults.length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _SummaryTile(value: '$uniqueStudents', label: 'Students', icon: Icons.people_rounded),
          _SummaryTile(value: '$passed', label: 'Passed', icon: Icons.check_circle_outline_rounded),
          _SummaryTile(value: '${avgScore.toStringAsFixed(1)}%', label: 'Avg Score', icon: Icons.bar_chart_rounded),
        ],
      ),
    );
  }

  Widget _buildStudentList(ColorScheme cs) {
    final students = _grouped.entries.toList();

    return RefreshIndicator(
      onRefresh: _loadStudents,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: students.length,
        itemBuilder: (context, index) {
          final entry = students[index];
          final submissions = entry.value;
          final name = submissions.last['student_name']?.toString() ?? 'Unknown';
          final attempts = submissions.length;
          final avgScore = submissions.fold<double>(0, (s, r) => s + (r['score'] as num).toDouble()) / attempts;
          final passCount = submissions.where((r) => r['passed'] == true).length;
          final lastDate = submissions.last['submitted_at']?.toString().split('T')[0] ?? '';

          return GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StudentDetailScreen(
                  studentName: name,
                  submissions: submissions,
                ),
              ),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$attempts attempt${attempts == 1 ? '' : 's'} · $passCount passed · last: $lastDate',
                          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: avgScore / 100,
                            minHeight: 5,
                            backgroundColor: cs.surface,
                            valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${avgScore.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(Icons.arrow_forward_ios_rounded, size: 12, color: cs.onSurfaceVariant),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Student Detail Screen
// ──────────────────────────────────────────────

class StudentDetailScreen extends StatelessWidget {
  final String studentName;
  final List<Map<String, dynamic>> submissions;

  const StudentDetailScreen({
    super.key,
    required this.studentName,
    required this.submissions,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sorted = [...submissions]..sort((a, b) =>
        (b['submitted_at'] ?? '').compareTo(a['submitted_at'] ?? ''));

    final total = submissions.length;
    final passed = submissions.where((r) => r['passed'] == true).length;
    final avgScore = submissions.fold<double>(0, (s, r) => s + (r['score'] as num).toDouble()) / total;
    final bestScore = submissions.fold<double>(0, (best, r) {
      final score = (r['score'] as num).toDouble();
      return score > best ? score : best;
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(studentName),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildDetailHeader(cs, total, passed, avgScore, bestScore)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Quiz History',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final r = sorted[index];
                final score = (r['score'] as num).toDouble();
                final isPassed = r['passed'] == true;
                final date = (r['submitted_at'] ?? '').toString().split('T')[0];
                final totalQ = r['total_questions'] as int? ?? 0;

                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isPassed ? cs.primaryContainer : cs.errorContainer,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          isPassed ? Icons.check_rounded : Icons.close_rounded,
                          color: isPassed ? cs.onPrimaryContainer : cs.onErrorContainer,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPassed ? 'Passed' : 'Failed',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isPassed ? cs.primary : cs.error,
                              ),
                            ),
                            Text(
                              '$totalQ questions · $date',
                              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                            ),
                            const SizedBox(height: 5),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: score / 100,
                                minHeight: 4,
                                backgroundColor: cs.surface,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isPassed ? cs.primary : cs.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${score.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isPassed ? cs.primary : cs.error,
                        ),
                      ),
                    ],
                  ),
                );
              },
              childCount: sorted.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildDetailHeader(
    ColorScheme cs,
    int total,
    int passed,
    double avgScore,
    double bestScore,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
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
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                studentName.isNotEmpty ? studentName[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            studentName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _SummaryTile(value: '$total', label: 'Attempts', icon: Icons.quiz_rounded),
              _SummaryTile(value: '$passed', label: 'Passed', icon: Icons.check_circle_outline_rounded),
              _SummaryTile(value: '${avgScore.toStringAsFixed(1)}%', label: 'Avg Score', icon: Icons.bar_chart_rounded),
              _SummaryTile(value: '${bestScore.toStringAsFixed(1)}%', label: 'Best', icon: Icons.emoji_events_rounded),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Shared widget
// ──────────────────────────────────────────────

class _SummaryTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _SummaryTile({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
