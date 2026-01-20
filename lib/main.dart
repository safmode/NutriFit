// lib/main.dart
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // ✅ added
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'core/constants.dart';

// Auth (aliases to avoid clash)
import 'screens/auth/login_screen.dart' as auth_login;
import 'screens/auth/register_screen.dart' as auth_register;

// Onboarding
import 'screens/onboarding/welcome_screen.dart';
import 'screens/onboarding/profile_setup_screen.dart';
import 'screens/onboarding/goal_selection_screen.dart';

// Home
import 'screens/home/home_screen.dart';

// Diet
import 'screens/diet/meal_planner_screen.dart';
import 'screens/diet/meal_category_screen.dart';
import 'screens/diet/meal_detail_screen.dart';
import 'screens/diet/meal_schedule_screen.dart';

// Workout
import 'screens/workout/workout_tracker_screen.dart';
import 'screens/workout/workout_detail_screen.dart';
import 'screens/workout/workout_schedule_screen.dart';
import 'screens/workout/exercise_detail_screen.dart';

// Activity
import 'screens/activity/progress_photo_screen.dart';
import 'screens/activity/progress_comparison_screen.dart';
import 'screens/activity/progress_result_screen.dart';
import 'screens/activity/body_visualization_screen.dart';
import 'screens/activity/activity_tracker_screen.dart';

// Sleep
import 'screens/sleep/sleep_tracker_screen.dart';
import 'screens/sleep/sleep_schedule_screen.dart';
import 'screens/sleep/add_alarm_screen.dart';

// Misc
import 'screens/notification/notification_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/personal_data_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // ✅ App Check (Debug provider for emulator/dev)
  // This removes: "No AppCheckProvider installed"
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );

  runApp(const NutriFitApp());
}

class NutriFitApp extends StatelessWidget {
  const NutriFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriFit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),

      onGenerateRoute: (settings) {
        final routes = <String, WidgetBuilder>{
          // Root / Onboarding & Auth
          '/': (_) => const AuthWrapper(),
          '/welcome': (_) => const WelcomeScreen(),
          '/login': (_) => const auth_login.LoginScreen(),
          '/register': (_) => const auth_register.RegisterScreen(),
          '/profile-setup': (_) => const ProfileSetupScreen(),
          '/goal-selection': (_) => const GoalSelectionScreen(),

          // Main
          '/home': (_) => const HomeScreen(),

          // Diet
          '/meal-planner': (_) => const MealPlannerScreen(),
          '/meal-schedule': (_) => const MealScheduleScreen(),

          // Workout
          '/workout-tracker': (_) => const WorkoutTrackerScreen(),
          '/workout-detail': (_) => const WorkoutDetailScreen(),
          '/workout-schedule': (_) => const WorkoutScheduleScreen(),
          '/exercise-detail': (_) => const ExerciseDetailScreen(),

          // Activity
          '/progress-photo': (_) => const ProgressPhotoScreen(),
          '/progress-comparison': (_) => const ProgressComparisonScreen(),
          '/progress-result': (_) => const ProgressResultScreen(),
          '/body-visualization': (_) => const BodyVisualizationScreen(),
          '/activity-tracker': (_) => const ActivityTrackerScreen(),

          // Sleep
          '/sleep-tracker': (_) => const SleepTrackerScreen(),
          '/sleep-schedule': (_) => const SleepScheduleScreen(),
          '/add-alarm': (_) => const AddAlarmScreen(),

          // Misc
          '/notification': (_) => const NotificationScreen(),
          '/profile': (_) => const ProfileScreen(),
          '/edit-profile': (_) => const EditProfileScreen(),
          '/personal-data': (_) => const PersonalDataScreen(),
        };

        // ✅ Meal category supports args OR defaults
        if (settings.name == '/meal-category') {
          final arg = settings.arguments;

          String mealType = 'Breakfast';
          if (arg is String && arg.trim().isNotEmpty) {
            mealType = arg.trim();
          } else if (arg is Map) {
            final t = arg['type'];
            if (t is String && t.trim().isNotEmpty) {
              mealType = t.trim();
            }
          }

          return _buildRoute(settings, MealCategoryScreen(mealType: mealType));
        }

        // ✅ Meal detail (screen reads args inside)
        if (settings.name == '/meal-detail') {
          return _buildRoute(settings, const MealDetailScreen());
        }

        final builder = routes[settings.name];
        if (builder == null) {
          return _buildRoute(
            settings,
            Scaffold(
              body: Center(child: Text('Route not found: ${settings.name}')),
            ),
          );
        }

        return _buildRoute(settings, builder(context));
      },
    );
  }
}

/// ✅ Wrapper to handle Auth State & Profile Setup Check
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnap.data;
        if (user == null) return const WelcomeScreen();

        return FutureBuilder<void>(
          future: _ensureUserDocument(user),
          builder: (context, ensureSnap) {
            if (ensureSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, userSnap) {
                if (userSnap.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                final data = userSnap.data?.data();
                final profileComplete =
                    (data?['profileSetupComplete'] ?? false) as bool;

                if (!profileComplete) return const ProfileSetupScreen();
                return const HomeScreen();
              },
            );
          },
        );
      },
    );
  }

  /// Ensures user document exists in Firestore, creating it if missing
  Future<void> _ensureUserDocument(User user) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        // Document doesn't exist, create it with basic info
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email ?? '',
          'firstName': '', // User will set this in profile setup
          'lastName': '',
          'profileSetupComplete': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Ignore errors - document might be created later or connection issue
      // ignore: avoid_print
      print('Error ensuring user document: $e');
    }
  }
}

/// ✅ Smooth transition for all routes
PageRoute _buildRoute(RouteSettings settings, Widget page) {
  return PageRouteBuilder(
    settings: settings,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, anim, __, child) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.08, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
