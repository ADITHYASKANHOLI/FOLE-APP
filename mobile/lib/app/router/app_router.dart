import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/academics/presentation/departments_browser_screen.dart';
import '../../features/academics/presentation/semesters_browser_screen.dart';
import '../../features/academics/presentation/subject_catalog_screen.dart';
import '../../features/academics/presentation/subject_detail_screen.dart';
import '../../features/account/presentation/account_profile_screen.dart';
import '../../features/account/presentation/change_password_screen.dart';
import '../../features/admin/presentation/admin_create_lecture_screen.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/admin/presentation/admin_login_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/fole_space/presentation/event_detail_screen.dart';
import '../../features/fole_space/presentation/events_catalog_screen.dart';
import '../../features/fole_space/presentation/my_space_screen.dart';
import '../../features/fole_space/presentation/space_landing_screen.dart';
import '../../features/fole_works/presentation/works_catalog_screen.dart';
import '../../features/fole_works/presentation/works_detail_screen.dart';
import '../../features/home/presentation/about_screen.dart';
import '../../features/home/presentation/contact_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/splash_screen.dart';
import '../../features/lectures/presentation/lectures_browser_screen.dart';
import '../../features/lectures/presentation/lesson_player_screen.dart';
import '../../features/materials/presentation/materials_catalog_screen.dart';
import '../../features/organizer/presentation/live_desk_screen.dart';
import '../../features/organizer/presentation/organizer_hub_screen.dart';
import '../../features/organizer/presentation/qr_scanner_screen.dart';
import '../../features/search/presentation/global_search_screen.dart';
import '../theme/app_colors.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      // Splash / Initialization
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Stateful Bottom Navigation Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _AppNavigationShell(navigationShell: navigationShell);
        },
        branches: [
          // Tab 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          // Tab 1: Learn / Subjects
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/subjects',
                builder: (context, state) {
                  final dept = state.uri.queryParameters['dept'];
                  final sem =
                      int.tryParse(state.uri.queryParameters['sem'] ?? '');
                  return SubjectCatalogScreen(
                    initialDept: dept,
                    initialSem: sem,
                  );
                },
              ),
            ],
          ),

          // Tab 2: Lectures
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/lectures',
                builder: (context, state) => const LecturesBrowserScreen(),
              ),
            ],
          ),

          // Tab 3: Materials
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/materials',
                builder: (context, state) => const MaterialsCatalogScreen(),
              ),
            ],
          ),

          // Tab 4: Account
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/account',
                builder: (context, state) => const AccountProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Full-screen Academic & Public Routes
      GoRoute(
        path: '/search',
        builder: (context, state) {
          final query = state.uri.queryParameters['q'];
          return GlobalSearchScreen(initialQuery: query);
        },
      ),
      GoRoute(
        path: '/departments',
        builder: (context, state) => const DepartmentsBrowserScreen(),
      ),
      GoRoute(
        path: '/semesters',
        builder: (context, state) {
          final dept = state.uri.queryParameters['dept'];
          return SemestersBrowserScreen(departmentSlug: dept);
        },
      ),
      GoRoute(
        path: '/subjects/:slug',
        builder: (context, state) {
          final slug = state.pathParameters['slug'] ?? '';
          return SubjectDetailScreen(slug: slug);
        },
      ),
      GoRoute(
        path: '/lessons/:idOrSlug',
        builder: (context, state) {
          final idOrSlug = state.pathParameters['idOrSlug'] ?? '';
          final subjectSlug = state.uri.queryParameters['subject'];
          final moduleSlug = state.uri.queryParameters['module'];
          return LessonPlayerScreen(
            idOrSlug: idOrSlug,
            subjectSlug: subjectSlug,
            moduleSlug: moduleSlug,
          );
        },
      ),
      GoRoute(
        path: '/works',
        builder: (context, state) => const WorksCatalogScreen(),
      ),
      GoRoute(
        path: '/works/:slug',
        builder: (context, state) {
          final slug = state.pathParameters['slug'] ?? '';
          return WorksDetailScreen(slug: slug);
        },
      ),
      GoRoute(
        path: '/space',
        builder: (context, state) => const SpaceLandingScreen(),
      ),
      GoRoute(
        path: '/space/events',
        builder: (context, state) => const EventsCatalogScreen(),
      ),
      GoRoute(
        path: '/space/events/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return EventDetailScreen(eventId: id);
        },
      ),
      GoRoute(
        path: '/space/my',
        builder: (context, state) => const MySpaceScreen(),
      ),
      GoRoute(
        path: '/organizer',
        builder: (context, state) => const OrganizerHubScreen(),
      ),
      GoRoute(
        path: '/organizer/events/:id/desk',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return LiveDeskScreen(eventId: id);
        },
      ),
      GoRoute(
        path: '/organizer/events/:id/scan',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return QrScannerScreen(eventId: id);
        },
      ),

      // Admin Privileged Routes
      GoRoute(
        path: '/admin/login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/lectures/create',
        builder: (context, state) => const AdminCreateLectureScreen(),
      ),

      // Auth & Account
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/account/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/contact',
        builder: (context, state) => const ContactScreen(),
      ),
    ],
  );
});

class _AppNavigationShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _AppNavigationShell({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.borderLight, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book_rounded),
              label: 'Learn',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.ondemand_video_outlined),
              activeIcon: Icon(Icons.ondemand_video_rounded),
              label: 'Lectures',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder_open_outlined),
              activeIcon: Icon(Icons.folder_rounded),
              label: 'Materials',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}
