import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/book_provider.dart';
import '../providers/quiz_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/aurora_background.dart';
import '../widgets/glass.dart';
import 'books_screen.dart';
import 'quiz_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'teacher/students_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  List<_NavItem> _buildNavItems(bool isTeacher) {
    return [
      const _NavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
      const _NavItem(
          Icons.menu_book_outlined, Icons.menu_book_rounded, 'Books'),
      const _NavItem(Icons.quiz_outlined, Icons.quiz_rounded, 'Quizzes'),
      if (isTeacher)
        const _NavItem(
            Icons.people_outline_rounded, Icons.people_rounded, 'Students'),
      const _NavItem(
          Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
      const _NavItem(
          Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
    ];
  }

  List<Widget> _buildScreens(bool isTeacher) {
    return [
      _HomeBody(
        isTeacher: isTeacher,
        onNavigate: (tab) {
          setState(() {
            switch (tab) {
              case 'books':
                _selectedIndex = 1;
              case 'quizzes':
                _selectedIndex = 2;
              case 'students':
                if (isTeacher) _selectedIndex = 3;
              case 'profile':
                _selectedIndex = isTeacher ? 4 : 3;
            }
          });
        },
      ),
      const BooksScreen(),
      const QuizScreen(),
      if (isTeacher) const StudentsScreen(),
      const ProfileScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final isTeacher = auth.currentUser?['role'] == 'Teacher';
        final navItems = _buildNavItems(isTeacher);
        final screens = _buildScreens(isTeacher);
        final safeIndex = _selectedIndex.clamp(0, navItems.length - 1);

        // Desktop / wide windows get a left sidebar; phones keep the bottom bar.
        final isWide = MediaQuery.of(context).size.width >= 900;
        final body = IndexedStack(index: safeIndex, children: screens);

        if (isWide) {
          return Scaffold(
            body: Row(
              children: [
                _SideNavBar(
                  items: navItems,
                  selectedIndex: safeIndex,
                  onSelected: (i) => setState(() => _selectedIndex = i),
                ),
                Expanded(child: body),
              ],
            ),
          );
        }

        return Scaffold(
          body: body,
          bottomNavigationBar: _GlassNavBar(
            items: navItems,
            selectedIndex: safeIndex,
            onSelected: (i) => setState(() => _selectedIndex = i),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  Glass bottom navigation (floating-pill style)
// ══════════════════════════════════════════════════════════════════════════

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

class _GlassNavBar extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _GlassNavBar({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final decor = AppDecoration.of(context);

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: cs.outlineVariant, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: decor.cardShadow,
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              for (int i = 0; i < items.length; i++)
                _NavButton(
                  item: items[i],
                  selected: i == selectedIndex,
                  onTap: () => onSelected(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final decor = AppDecoration.of(context);

    // Only the selected tab expands into a labelled pill; others stay
    // compact icon buttons so labels never overflow with 6 tabs.
    final button = AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: EdgeInsets.symmetric(horizontal: selected ? 14 : 0),
      decoration: BoxDecoration(
        gradient: selected ? decor.brand : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: selected ? decor.glow(0.32) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            selected ? item.activeIcon : item.icon,
            size: 22,
            color: selected ? Colors.white : cs.onSurfaceVariant,
          ),
          if (selected)
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(left: 7),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    final tappable = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: button,
    );

    // Selected pill flexes to fit its label; icon-only tabs stay fixed.
    return selected
        ? Expanded(child: tappable)
        : SizedBox(width: 54, child: tappable);
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  Desktop side navigation (left sidebar)
// ══════════════════════════════════════════════════════════════════════════

class _SideNavBar extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _SideNavBar({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final decor = AppDecoration.of(context);

    return Container(
      width: 256,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(right: BorderSide(color: cs.outlineVariant)),
        boxShadow: [
          BoxShadow(
            color: decor.cardShadow,
            blurRadius: 24,
            offset: const Offset(6, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Brand header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
              child: Row(
                children: [
                  const GradientIconBadge(
                    icon: Icons.school_rounded,
                    size: 44,
                    iconSize: 24,
                    radius: 14,
                  ),
                  const SizedBox(width: 12),
                  ShaderMask(
                    shaderCallback: (rect) => decor.brand.createShader(rect),
                    child: const Text(
                      'TDLF-Educ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Nav items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  const _SideNavLabel('MENU'),
                  for (int i = 0; i < items.length; i++)
                    _SideNavItem(
                      item: items[i],
                      selected: i == selectedIndex,
                      onTap: () => onSelected(i),
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: cs.outlineVariant),
            const _SidebarUserCard(),
          ],
        ),
      ),
    );
  }
}

class _SideNavLabel extends StatelessWidget {
  final String text;
  const _SideNavLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _SideNavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final decor = AppDecoration.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              gradient: selected ? decor.brand : null,
              borderRadius: BorderRadius.circular(14),
              boxShadow: selected ? decor.glow(0.28) : null,
            ),
            child: Row(
              children: [
                Icon(
                  selected ? item.activeIcon : item.icon,
                  size: 22,
                  color: selected ? Colors.white : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 14),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? Colors.white : cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarUserCard extends StatelessWidget {
  const _SidebarUserCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final decor = AppDecoration.of(context);
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final name = (auth.currentUser?['username'] ?? 'User').toString();
        final role = (auth.currentUser?['role'] ?? 'Guest').toString();
        final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration:
                    BoxDecoration(gradient: decor.brand, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      role,
                      style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: auth.isGuest ? 'Exit' : 'Logout',
                icon: Icon(
                    auth.isGuest
                        ? Icons.arrow_back_rounded
                        : Icons.logout_rounded,
                    size: 20,
                    color: cs.onSurfaceVariant),
                onPressed: () => auth.isGuest
                    ? Navigator.of(context, rootNavigator: true).maybePop()
                    : _confirmLogout(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  Home tab body
// ══════════════════════════════════════════════════════════════════════════

class _HomeBody extends StatelessWidget {
  final bool isTeacher;
  final void Function(String tab) onNavigate;

  const _HomeBody({required this.isTeacher, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              context.read<BookProvider>().fetchBooks(),
              context.read<QuizProvider>().fetchQuizzes(),
            ]);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _GreetingBar(),
                        const SizedBox(height: 20),
                        _SpotlightCard(
                          isTeacher: isTeacher,
                          onPrimary: () =>
                              onNavigate(isTeacher ? 'books' : 'quizzes'),
                        ),
                        const SizedBox(height: 24),
                        if (!isTeacher) ...[
                          _StatsRow(),
                          const SizedBox(height: 24),
                        ],
                        Text(
                          isTeacher ? 'Teacher Tools' : 'Quick Actions',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _ActionCard(
                      icon: Icons.menu_book_rounded,
                      title: isTeacher ? 'Manage Books' : 'Browse Books',
                      subtitle: isTeacher
                          ? 'Add, edit and organise the library'
                          : 'Download books for offline reading',
                      gradient: const [
                        AppPalette.indigo,
                        AppPalette.violet,
                      ],
                      onTap: () => onNavigate('books'),
                    ),
                    const SizedBox(height: 12),
                    _ActionCard(
                      icon: Icons.quiz_rounded,
                      title: isTeacher ? 'Manage Quizzes' : 'Take a Quiz',
                      subtitle: isTeacher
                          ? 'Create and curate quiz questions'
                          : 'Test your knowledge and track progress',
                      gradient: const [
                        AppPalette.violet,
                        AppPalette.magenta,
                      ],
                      onTap: () => onNavigate('quizzes'),
                    ),
                    if (isTeacher) ...[
                      const SizedBox(height: 12),
                      _ActionCard(
                        icon: Icons.insights_rounded,
                        title: 'Monitor Students',
                        subtitle: 'Review quiz scores and progress',
                        gradient: const [
                          AppPalette.cyan,
                          AppPalette.indigo,
                        ],
                        onTap: () => onNavigate('students'),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _ActionCard(
                      icon: Icons.person_rounded,
                      title: 'My Profile',
                      subtitle: 'View your stats and quiz history',
                      gradient: const [
                        AppPalette.pink,
                        AppPalette.purple,
                      ],
                      onTap: () => onNavigate('profile'),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Greeting bar ──────────────────────────────────────────────────────────────

class _GreetingBar extends StatelessWidget {
  const _GreetingBar();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final decor = AppDecoration.of(context);
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final name = (auth.currentUser?['username'] ?? 'User').toString();
        final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

        return Row(
          children: [
            // When embedded in a host app (Tawi-Tawi), give an obvious way back.
            if (auth.isGuest) ...[
              Material(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () =>
                      Navigator.of(context, rootNavigator: true).maybePop(),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(Icons.arrow_back_rounded,
                        size: 22, color: cs.onSurface),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting 👋',
                    style: TextStyle(
                      fontSize: 14,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: decor.brand,
                shape: BoxShape.circle,
                boxShadow: decor.glow(0.28),
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Spotlight (hero) card ─────────────────────────────────────────────────────

class _SpotlightCard extends StatelessWidget {
  final bool isTeacher;
  final VoidCallback onPrimary;

  const _SpotlightCard({required this.isTeacher, required this.onPrimary});

  @override
  Widget build(BuildContext context) {
    final decor = AppDecoration.of(context);
    final role = isTeacher ? 'Teacher' : 'Student';

    return Container(
      decoration: BoxDecoration(
        gradient: decor.hero,
        borderRadius: BorderRadius.circular(26),
        boxShadow: decor.glow(0.4),
      ),
      child: Stack(
        children: [
          // decorative bubbles
          Positioned(
            right: -28,
            top: -28,
            child: _bubble(96, 0.16),
          ),
          Positioned(
            right: 36,
            bottom: -34,
            child: _bubble(70, 0.12),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassPill(
                  text: role,
                  icon: isTeacher
                      ? Icons.school_rounded
                      : Icons.auto_stories_rounded,
                ),
                const SizedBox(height: 16),
                Text(
                  isTeacher
                      ? 'Shape your\nclassroom today'
                      : 'Ready to level up\nyour knowledge?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isTeacher
                      ? 'Manage books, quizzes and track your students.'
                      : 'Pick up a quiz and keep your streak going.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),
                _SpotlightButton(
                  label: isTeacher ? 'Manage Library' : 'Start a Quiz',
                  onTap: onPrimary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _SpotlightButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SpotlightButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: cs.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_rounded, size: 18, color: cs.primary),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<BookProvider, QuizProvider>(
      builder: (context, books, quizzes, _) {
        return Row(
          children: [
            _StatTile(
              value: '${books.books.length}',
              label: 'Books',
              icon: Icons.menu_book_rounded,
              gradient: const [AppPalette.indigo, AppPalette.violet],
            ),
            const SizedBox(width: 10),
            _StatTile(
              value: '${books.downloadedBooks.length}',
              label: 'Downloads',
              icon: Icons.download_done_rounded,
              gradient: const [AppPalette.cyan, AppPalette.indigo],
            ),
            const SizedBox(width: 10),
            _StatTile(
              value: '${quizzes.quizzes.length}',
              label: 'Quizzes',
              icon: Icons.quiz_rounded,
              gradient: const [AppPalette.violet, AppPalette.magenta],
            ),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final List<Color> gradient;

  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        radius: 20,
        child: Column(
          children: [
            GradientIconBadge(
              icon: icon,
              size: 40,
              iconSize: 20,
              radius: 12,
              gradient: LinearGradient(colors: gradient),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action card ───────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GradientIconBadge(
            icon: icon,
            size: 52,
            iconSize: 26,
            radius: 16,
            gradient: LinearGradient(colors: gradient),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: cs.primary),
          ),
        ],
      ),
    );
  }
}
