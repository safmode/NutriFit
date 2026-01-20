import 'package:flutter/material.dart';

import '../screens/onboarding/welcome_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';

// Workout
import '../screens/workout/workout_tracker_screen.dart';
import '../screens/workout/workout_detail_screen.dart';
import '../screens/workout/exercise_detail_screen.dart';
import '../screens/workout/workout_schedule_screen.dart';

// Diet
import '../screens/diet/meal_planner_screen.dart';
import '../screens/diet/meal_schedule_screen.dart';
import '../screens/diet/meal_category_screen.dart';
import '../screens/diet/meal_detail_screen.dart';

// Sleep
import '../screens/sleep/sleep_tracker_screen.dart';
import '../screens/sleep/sleep_schedule_screen.dart';
import '../screens/sleep/add_alarm_screen.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    late final Widget page;

    switch (settings.name) {
      case '/':
      case '/welcome':
        page = const WelcomeScreen();
        break;

      case '/login':
        page = const LoginScreen();
        break;

      case '/register':
        page = const RegisterScreen();
        break;

      case '/home':
        page = const HomeScreen();
        break;

      // Workout
      case '/workout-tracker':
        page = const WorkoutTrackerScreen();
        break;

      case '/workout-detail':
        page = const WorkoutDetailScreen();
        break;

      case '/exercise-detail':
        page = const ExerciseDetailScreen();
        break;

      case '/workout-schedule':
        page = const WorkoutScheduleScreen();
        break;

      // Diet
      case '/meal-planner':
        page = const MealPlannerScreen();
        break;

      case '/meal-schedule':
        page = const MealScheduleScreen();
        break;

      case '/meal-category': {
        final arg = settings.arguments;

        String type = 'Breakfast';
        if (arg is String && arg.trim().isNotEmpty) {
          type = arg.trim();
        } else if (arg is Map) {
          final t = arg['type'];
          if (t is String && t.trim().isNotEmpty) type = t.trim();
        }

        page = MealCategoryScreen(mealType: type);
        break;
      }

      case '/meal-detail':
        page = const MealDetailScreen();
        break;

      // Sleep
      case '/sleep-tracker':
        page = const SleepTrackerScreen();
        break;

      case '/sleep-schedule':
        page = const SleepScheduleScreen();
        break;

      case '/add-alarm':
        page = const AddAlarmScreen();
        break;

      default:
        page = Scaffold(
          body: Center(child: Text('Route not found: ${settings.name}')),
        );
        break;
    }

    return _animatedRoute(page, settings);
  }

  static PageRouteBuilder _animatedRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0.02),
              end: Offset.zero,
            ).animate(curve),
            child: child,
          ),
        );
      },
    );
  }
}
