import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/course_provider.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';

// ── Quiz type helpers (shared across the quiz UI) ───────────────────────────
String quizTypeLabel(String t) => switch (t) {
      'true_false' => 'True / False',
      'multiple_choice' => 'Multiple Choice',
      'fill_blank' => 'Fill in the Blank',
      'enumeration' => 'Enumeration',
      _ => 'Open Ended',
    };

IconData quizTypeIcon(String t) => switch (t) {
      'true_false' => Icons.toggle_on_rounded,
      'multiple_choice' => Icons.list_alt_rounded,
      'fill_blank' => Icons.short_text_rounded,
      'enumeration' => Icons.format_list_numbered_rounded,
      _ => Icons.edit_note_rounded,
    };

List<Color> quizTypeGradient(String t) => switch (t) {
      'true_false' => const [AppPalette.violet, AppPalette.magenta],
      'multiple_choice' => const [AppPalette.indigo, AppPalette.violet],
      'fill_blank' => const [AppPalette.cyan, AppPalette.indigo],
      'enumeration' => const [AppPalette.purple, AppPalette.pink],
      _ => const [AppPalette.indigo, AppPalette.cyan],
    };

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late bool _isTeacher;

  @override
  void initState() {
    super.initState();
    _isTeacher = context.read<AuthProvider>().currentUser?['role'] == 'Teacher';
    _tabController = TabController(length: _isTeacher ? 1 : 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().fetchQuizzes();
      context.read<CourseProvider>().fetchCourses();
      if (!_isTeacher) {
        final auth = context.read<AuthProvider>();
        if (auth.currentUser != null) {
          context.read<QuizProvider>().loadQuizHistory(auth.currentUser!['id']);
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quizzes'),
        bottom: _isTeacher
            ? null
            : TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Available'),
                  Tab(text: 'History'),
                ],
              ),
      ),
      floatingActionButton: _isTeacher
          ? GradientFab(
              icon: Icons.add_rounded,
              label: 'Add Quiz',
              onPressed: () => _showAddQuizDialog(context),
            )
          : null,
      body: _isTeacher
          ? const _AvailableTab(isTeacher: true)
          : TabBarView(
              controller: _tabController,
              children: const [
                _AvailableTab(isTeacher: false),
                _HistoryTab(),
              ],
            ),
    );
  }

  void _showAddQuizDialog(BuildContext context) {
    final questionCtrl = TextEditingController();
    final answerCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    String quizType = 'open_ended';
    final cs = Theme.of(context).colorScheme;

    final courses = context.read<CourseProvider>().courses;
    String courseId =
        courses.isNotEmpty ? courses.first['id'] as String : 'course-001';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Quiz Question'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: questionCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Question *',
                    prefixIcon: Icon(Icons.help_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Type', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                const SizedBox(height: 6),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'open_ended', label: Text('Open Ended')),
                    ButtonSegment(value: 'true_false', label: Text('True / False')),
                  ],
                  selected: {quizType},
                  onSelectionChanged: (s) {
                    setDialogState(() {
                      quizType = s.first;
                      if (quizType == 'true_false') answerCtrl.text = 'True';
                    });
                  },
                  style: ButtonStyle(
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                quizType == 'true_false'
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Correct Answer', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                          const SizedBox(height: 6),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'True', label: Text('True')),
                              ButtonSegment(value: 'False', label: Text('False')),
                            ],
                            selected: {answerCtrl.text.isEmpty ? 'True' : answerCtrl.text},
                            onSelectionChanged: (s) {
                              setDialogState(() => answerCtrl.text = s.first);
                            },
                          ),
                        ],
                      )
                    : TextField(
                        controller: answerCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Correct Answer *',
                          prefixIcon: Icon(Icons.check_rounded),
                        ),
                      ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Explanation (optional)',
                    prefixIcon: Icon(Icons.info_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Course',
                    prefixIcon: Icon(Icons.class_outlined),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: courseId,
                      isDense: true,
                      isExpanded: true,
                      items: courses
                          .map((c) => DropdownMenuItem(
                                value: c['id'] as String,
                                child: Text(c['title'] as String,
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => courseId = v);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final question = questionCtrl.text.trim();
                final answer = answerCtrl.text.trim();
                if (question.isEmpty || answer.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Question and answer are required'),
                      backgroundColor: cs.error,
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx);
                final ok = await context.read<QuizProvider>().addQuiz({
                  'question': question,
                  'quiz_type': quizType,
                  'correct_answer': answer,
                  'reason': reasonCtrl.text.trim(),
                  'course_id': courseId,
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok ? 'Quiz added!' : 'Failed to add quiz'),
                      backgroundColor: ok ? cs.primary : cs.error,
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Available Tab
// ──────────────────────────────────────────────

class _AvailableTab extends StatefulWidget {
  final bool isTeacher;
  const _AvailableTab({required this.isTeacher});

  @override
  State<_AvailableTab> createState() => _AvailableTabState();
}

class _AvailableTabState extends State<_AvailableTab> {
  String? _selectedCourseId;
  String _search = '';
  String _typeFilter = 'all'; // 'all' | 'true_false' | 'open_ended'
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Consumer<QuizProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.quizzes.isEmpty) {
          return _buildEmpty(context, cs);
        }

        // Course ids present overall — keeps the course chips stable even when
        // the search / type filters hide everything in a course.
        final courseIds = <String>{
          for (final q in provider.quizzes) (q['course_id'] ?? 'unknown') as String,
        };

        // Apply search + type filters
        final query = _search.trim().toLowerCase();
        final filtered = provider.quizzes.where((q) {
          final type = (q['quiz_type'] ?? 'open_ended') as String;
          final matchesType = _typeFilter == 'all' || type == _typeFilter;
          final matchesSearch = query.isEmpty ||
              (q['question'] ?? '').toString().toLowerCase().contains(query);
          return matchesType && matchesSearch;
        }).toList();

        // Group by course
        final grouped = <String, List<Map<String, dynamic>>>{};
        for (final q in filtered) {
          final cId = q['course_id'] ?? 'unknown';
          grouped.putIfAbsent(cId, () => []).add(q);
        }

        // Apply course filter
        final displayedGroups = _selectedCourseId == null
            ? grouped
            : {
                if (grouped.containsKey(_selectedCourseId))
                  _selectedCourseId!: grouped[_selectedCourseId]!,
              };

        return RefreshIndicator(
          onRefresh: () => context.read<QuizProvider>().fetchQuizzes(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Search field
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search questions...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _search = '');
                              },
                            )
                          : null,
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
              ),
              // Question-type filter
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    children: [
                      _buildTypeChip(cs, 'all', 'All Types'),
                      const SizedBox(width: 8),
                      _buildTypeChip(cs, 'multiple_choice', 'Multiple Choice'),
                      const SizedBox(width: 8),
                      _buildTypeChip(cs, 'true_false', 'True / False'),
                      const SizedBox(width: 8),
                      _buildTypeChip(cs, 'fill_blank', 'Fill in the Blank'),
                      const SizedBox(width: 8),
                      _buildTypeChip(cs, 'enumeration', 'Enumeration'),
                    ],
                  ),
                ),
              ),
              // Course filter chips
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
                    children: [
                      _buildChip(cs, null, 'All'),
                      for (final courseId in courseIds) ...[
                        const SizedBox(width: 8),
                        _buildChip(cs, courseId,
                            context.read<CourseProvider>().titleFor(courseId)),
                      ],
                    ],
                  ),
                ),
              ),
              if (displayedGroups.isEmpty)
                SliverToBoxAdapter(
                  child: _NoResults(cs: cs),
                ),
              for (final entry in displayedGroups.entries) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.read<CourseProvider>().titleFor(entry.key),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${entry.value.length}',
                            style: TextStyle(
                                fontSize: 11,
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (!widget.isTeacher) ...[
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: () {
                              context
                                  .read<QuizProvider>()
                                  .prepareQuiz(entry.value);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const QuizTakingScreen()),
                              );
                            },
                            icon: const Icon(Icons.play_arrow_rounded,
                                size: 16),
                            label: const Text('Start',
                                style: TextStyle(fontSize: 12)),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final quiz = entry.value[index];
                      return _QuizCard(
                        quiz: quiz,
                        isTeacher: widget.isTeacher,
                        onDelete: () async {
                          final ok = await context
                              .read<QuizProvider>()
                              .deleteQuiz(
                                quiz['quiz_id'] ?? quiz['id'] ?? '',
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok
                                    ? 'Quiz deleted'
                                    : 'Failed to delete'),
                                backgroundColor:
                                    ok ? cs.primary : cs.error,
                              ),
                            );
                          }
                        },
                      );
                    },
                    childCount: entry.value.length,
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChip(ColorScheme cs, String? courseId, String label) {
    final selected = _selectedCourseId == courseId;
    final decor = AppDecoration.of(context);
    return GestureDetector(
      onTap: () => setState(
          () => _selectedCourseId = selected ? null : courseId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? decor.brand : null,
          color: selected ? null : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? Colors.transparent : cs.outlineVariant,
          ),
          boxShadow: selected ? decor.glow(0.28) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : cs.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(ColorScheme cs, String type, String label) {
    final selected = _typeFilter == type;
    final decor = AppDecoration.of(context);
    return GestureDetector(
      onTap: () => setState(() => _typeFilter = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? decor.brand : null,
          color: selected ? null : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? Colors.transparent : cs.outlineVariant,
          ),
          boxShadow: selected ? decor.glow(0.22) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : cs.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, ColorScheme cs) {
    return RefreshIndicator(
      onRefresh: () => context.read<QuizProvider>().fetchQuizzes(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 400,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      gradient: AppDecoration.of(context).brand,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppDecoration.of(context).glow(0.3),
                    ),
                    child: const Icon(Icons.quiz_rounded,
                        size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'No quizzes available',
                    style: TextStyle(
                        fontSize: 14, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final ColorScheme cs;
  const _NoResults({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off_rounded,
                size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              'No matching quizzes',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Try a different search or filter',
              style: TextStyle(
                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final Map<String, dynamic> quiz;
  final bool isTeacher;
  final VoidCallback onDelete;

  const _QuizCard({
    required this.quiz,
    required this.isTeacher,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final decor = AppDecoration.of(context);
    final quizType = (quiz['quiz_type'] ?? 'open_ended').toString();
    final badgeGradient = quizTypeGradient(quizType);

    return GestureDetector(
      onLongPress: isTeacher ? onDelete : null,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.outlineVariant),
          boxShadow: decor.softShadow,
        ),
        child: Row(
          children: [
            GradientIconBadge(
              icon: quizTypeIcon(quizType),
              size: 42,
              iconSize: 22,
              radius: 13,
              gradient: LinearGradient(colors: badgeGradient),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quiz['question'] ?? 'No question',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeGradient.first.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      quizTypeLabel(quizType),
                      style: TextStyle(
                        fontSize: 10,
                        color: badgeGradient.first,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isTeacher)
              Icon(Icons.touch_app_rounded, size: 14, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// History Tab
// ──────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Consumer<QuizProvider>(
      builder: (context, provider, _) {
        final userId = context.read<AuthProvider>().currentUser?['id'] ?? '';

        if (provider.quizHistory.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => context.read<QuizProvider>().loadQuizHistory(userId),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: 400,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            gradient: AppDecoration.of(context).brand,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: AppDecoration.of(context).glow(0.3),
                          ),
                          child: const Icon(Icons.history_rounded, size: 40, color: Colors.white),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'No quiz attempts yet',
                          style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => context.read<QuizProvider>().loadQuizHistory(userId),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: provider.quizHistory.length,
          itemBuilder: (context, index) {
            final attempt = provider.quizHistory[index];
            final isCorrect = attempt['is_correct'] == 1;
            final date = attempt['attempted_at']?.toString().split('T')[0] ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isCorrect ? cs.primaryContainer : cs.errorContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isCorrect ? Icons.check_rounded : Icons.close_rounded,
                      color: isCorrect ? cs.onPrimaryContainer : cs.onErrorContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCorrect ? 'Correct' : 'Incorrect',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          'Answer: ${attempt['user_answer'] ?? 'Not answered'}',
                          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    date,
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            );
          },
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────
// Quiz Taking Screen
// ──────────────────────────────────────────────

class QuizTakingScreen extends StatefulWidget {
  const QuizTakingScreen({super.key});

  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  late TextEditingController _answerCtrl;

  @override
  void initState() {
    super.initState();
    _answerCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().resetQuiz();
    });
  }

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Exit Quiz?'),
            content: const Text('Your progress will not be saved.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Continue Quiz'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        if ((confirmed ?? false) && context.mounted) {
          context.read<QuizProvider>().resetQuiz();
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quiz'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('Exit Quiz?'),
                  content: const Text('Your progress will not be saved.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Continue'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Exit'),
                    ),
                  ],
                ),
              );
              if ((confirmed ?? false) && context.mounted) {
                context.read<QuizProvider>().resetQuiz();
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: Consumer<QuizProvider>(
          builder: (context, provider, _) {
            if (provider.showResults) {
              return _ResultsScreen(provider: provider);
            }
            if (provider.activeQuizzes.isEmpty) {
              return const Center(child: Text('No quizzes available'));
            }
            final quiz = provider.activeQuizzes[provider.currentQuestionIndex];
            return _QuestionScreen(
              quiz: quiz,
              provider: provider,
              answerCtrl: _answerCtrl,
            );
          },
        ),
      ),
    );
  }
}

class _QuestionScreen extends StatelessWidget {
  final Map<String, dynamic> quiz;
  final QuizProvider provider;
  final TextEditingController answerCtrl;

  const _QuestionScreen({
    required this.quiz,
    required this.provider,
    required this.answerCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final decor = AppDecoration.of(context);
    final quizId = quiz['quiz_id'] ?? quiz['id'] ?? '';
    final quizType = (quiz['quiz_type'] ?? 'open_ended').toString();
    final options = quiz['options'] is List
        ? (quiz['options'] as List).map((e) => e.toString()).toList()
        : <String>[];
    final selectedAnswer = provider.userAnswers[quizId];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress
            Row(
              children: [
                Text(
                  'Question ${provider.currentQuestionIndex + 1}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
                Text(
                  ' of ${provider.activeQuizzes.length}',
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (provider.currentQuestionIndex + 1) / provider.activeQuizzes.length,
                minHeight: 6,
                backgroundColor: cs.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 24),
            // Question card
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: decor.hero,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: decor.glow(0.32),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.help_outline_rounded,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'QUESTION',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.4,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            quiz['question'] ?? 'No question',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (quizType == 'true_false') ...[
                      _TrueFalseButton(
                        label: 'True',
                        icon: Icons.check_circle_rounded,
                        selected: selectedAnswer == 'True',
                        cs: cs,
                        onTap: () => provider.answerQuestion(quizId, 'True'),
                      ),
                      const SizedBox(height: 12),
                      _TrueFalseButton(
                        label: 'False',
                        icon: Icons.cancel_rounded,
                        selected: selectedAnswer == 'False',
                        cs: cs,
                        onTap: () => provider.answerQuestion(quizId, 'False'),
                      ),
                    ] else if (quizType == 'multiple_choice') ...[
                      for (final opt in options) ...[
                        _TrueFalseButton(
                          label: opt,
                          icon: selectedAnswer == opt
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          selected: selectedAnswer == opt,
                          cs: cs,
                          onTap: () => provider.answerQuestion(quizId, opt),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ] else if (quizType == 'enumeration') ...[
                      Text(
                        'Your Answers',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'List each item, separated by commas or new lines.',
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: answerCtrl..text = selectedAnswer ?? '',
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'e.g. item one, item two, item three',
                        ),
                        onChanged: (v) => provider.answerQuestion(quizId, v),
                      ),
                    ] else ...[
                      // fill_blank / open_ended
                      Text(
                        'Your Answer',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: answerCtrl..text = selectedAnswer ?? '',
                        decoration: const InputDecoration(
                          hintText: 'Type your answer here...',
                        ),
                        onChanged: (v) => provider.answerQuestion(quizId, v),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Nav buttons
            Row(
              children: [
                if (provider.currentQuestionIndex > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        answerCtrl.clear();
                        provider.previousQuestion();
                      },
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('Previous'),
                    ),
                  ),
                if (provider.currentQuestionIndex > 0) const SizedBox(width: 12),
                Expanded(
                  child: provider.currentQuestionIndex == provider.activeQuizzes.length - 1
                      ? ElevatedButton.icon(
                          onPressed: () {
                            final auth = context.read<AuthProvider>();
                            final courseId = provider.activeQuizzes.isNotEmpty
                                ? (provider.activeQuizzes.first['course_id'] ?? '')
                                : '';
                            provider.submitQuiz(
                              auth.currentUser?['id'] ?? '',
                              auth.currentUser?['username'] ?? 'Unknown',
                              courseId,
                            );
                          },
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: const Text('Submit'),
                        )
                      : ElevatedButton.icon(
                          onPressed: () {
                            answerCtrl.clear();
                            provider.nextQuestion();
                          },
                          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                          label: const Text('Next'),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrueFalseButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _TrueFalseButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final decor = AppDecoration.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          gradient: selected ? decor.brand : null,
          color: selected ? null : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? Colors.transparent : cs.outlineVariant,
            width: 1.5,
          ),
          boxShadow: selected ? decor.glow(0.3) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : cs.onSurfaceVariant,
              size: 28,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : cs.onSurface,
              ),
            ),
            const Spacer(),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }
}

class _ResultsScreen extends StatelessWidget {
  final QuizProvider provider;
  const _ResultsScreen({required this.provider});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final decor = AppDecoration.of(context);
    final score = provider.quizScore;
    final passed = provider.isPassed;
    final failGradient = [const Color(0xFFFB7185), cs.error];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: passed
                    ? decor.brand
                    : LinearGradient(
                        colors: failGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: (passed ? decor.glowShadow : cs.error)
                        .withValues(alpha: 0.45),
                    blurRadius: 32,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    passed
                        ? Icons.emoji_events_rounded
                        : Icons.refresh_rounded,
                    size: 30,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${score.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              passed ? 'Quiz Passed!' : 'Keep Practicing',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: passed ? cs.primary : cs.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Passing score: ${AppConfig.passingScore.toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ScoreStat(
                    label: 'Total',
                    value: '${provider.activeQuizzes.length}',
                    cs: cs,
                  ),
                  Container(width: 1, height: 36, color: cs.outline.withValues(alpha: 0.3)),
                  _ScoreStat(
                    label: 'Score',
                    value: '${score.toStringAsFixed(1)}%',
                    cs: cs,
                  ),
                  Container(width: 1, height: 36, color: cs.outline.withValues(alpha: 0.3)),
                  _ScoreStat(
                    label: 'Result',
                    value: passed ? 'PASS' : 'FAIL',
                    cs: cs,
                    color: passed ? cs.primary : cs.error,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  provider.resetQuiz();
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.done_rounded),
                label: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreStat extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme cs;
  final Color? color;

  const _ScoreStat({
    required this.label,
    required this.value,
    required this.cs,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color ?? cs.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
      ],
    );
  }
}
