import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'ui/theme/lore_theme.dart';
import 'ui/theme/responsive.dart';
import 'ui/screens/creator_dashboard.dart';
import 'ui/screens/story_manager.dart';
import 'ui/screens/character_manager.dart';
import 'ui/screens/story_journey_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase not yet configured: $e");
  }

  runApp(const LoreApp());
}

/// Root application widget with centralized theme and accessibility support.
class LoreApp extends StatelessWidget {
  const LoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lore Keeper',
      theme: LoreTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const MainScreen(),
      builder: (context, child) {
        // Respect user's text scaling preferences
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.of(context).textScaler,
          ),
          child: child!,
        );
      },
    );
  }
}

/// Main navigation screen with responsive bottom/side navigation.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late final AnimationController _transitionController;

  final List<Widget> _screens = [
    const CreatorDashboard(),
    const StoryJourneyHome(),
    const StoryManagerScreen(),
    const CharacterManagerScreen(),
  ];

  static const List<NavigationItem> _navItems = [
    NavigationItem(
      icon: Icons.dashboard_rounded,
      label: 'Dashboard',
      semanticLabel: 'Creator Dashboard',
    ),
    NavigationItem(
      icon: Icons.auto_stories_rounded,
      label: 'Journey',
      semanticLabel: 'Story Journey',
    ),
    NavigationItem(
      icon: Icons.library_books_rounded,
      label: 'Stories',
      semanticLabel: 'Story Library',
    ),
    NavigationItem(
      icon: Icons.person_add_rounded,
      label: 'Forge',
      semanticLabel: 'Character Forge',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    _transitionController.forward(from: 0);
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.deviceType(context) == DeviceType.desktop;

    return Scaffold(
      body: Container(
        decoration: LoreTheme.backgroundGradient,
        child: isDesktop
            ? _buildDesktopLayout(context)
            : _buildMobileLayout(context),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: FadeTransition(
            opacity: _transitionController,
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),
        ),
        _buildBottomNav(context),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Side navigation rail
        _buildSideNav(context),
        // Main content
        Expanded(
          child: FadeTransition(
            opacity: _transitionController,
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: LoreTheme.inkBlack,
        border: Border(
          top: BorderSide(
            color: LoreTheme.warmBrown.withOpacity(0.15),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Semantics(
          label: 'Main navigation',
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: LoreTheme.goldAccent,
            unselectedItemColor: LoreTheme.warmBrown,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: const TextStyle(
              fontFamily: LoreTheme.serifFont,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: LoreTheme.serifFont,
              fontSize: 10,
            ),
            items: _navItems
                .map((item) => BottomNavigationBarItem(
                      icon: Semantics(
                        label: item.semanticLabel,
                        child: Icon(item.icon),
                      ),
                      label: item.label,
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSideNav(BuildContext context) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: LoreTheme.inkBlack.withOpacity(0.8),
        border: Border(
          right: BorderSide(
            color: LoreTheme.warmBrown.withOpacity(0.15),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // App icon
            Icon(
              Icons.auto_stories,
              color: LoreTheme.goldAccent,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              'LORE',
              style: TextStyle(
                color: LoreTheme.goldAccent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontFamily: LoreTheme.serifFont,
              ),
            ),
            const SizedBox(height: 24),
            Divider(
              color: LoreTheme.warmBrown.withOpacity(0.2),
              indent: 16,
              endIndent: 16,
            ),
            const SizedBox(height: 8),
            // Nav items
            ...List.generate(_navItems.length, (i) {
              final item = _navItems[i];
              final isSelected = _selectedIndex == i;
              return Semantics(
                button: true,
                label: item.semanticLabel,
                selected: isSelected,
                child: InkWell(
                  onTap: () => _onItemTapped(i),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: isSelected
                              ? LoreTheme.goldAccent
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          item.icon,
                          color: isSelected
                              ? LoreTheme.goldAccent
                              : LoreTheme.warmBrown,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: isSelected
                                ? LoreTheme.goldAccent
                                : LoreTheme.warmBrown,
                            fontSize: 9,
                            fontFamily: LoreTheme.serifFont,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Navigation item data.
class NavigationItem {
  final IconData icon;
  final String label;
  final String semanticLabel;

  const NavigationItem({
    required this.icon,
    required this.label,
    required this.semanticLabel,
  });
}
