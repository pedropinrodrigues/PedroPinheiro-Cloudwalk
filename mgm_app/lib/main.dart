import 'package:flutter/material.dart';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import 'routes.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_signup_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';
import 'services/data_repository.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final supportDir = await getApplicationSupportDirectory();
  Hive.init(supportDir.path);
  // Helpful while debugging export paths.
  debugPrint('Hive dir: ${supportDir.path}');
  await DataRepository.instance.ensureInitialized();
  runApp(const MgmApp());
}

class MgmApp extends StatelessWidget {
  const MgmApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.light(useMaterial3: true);
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          secondary: AppColors.bonus,
          error: AppColors.error,
          surface: AppColors.surface,
        );

    final textTheme = base.textTheme
        .apply(
          displayColor: AppColors.textPrimary,
          bodyColor: AppColors.textPrimary,
        )
        .copyWith(
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          bodyMedium: base.textTheme.bodyMedium?.copyWith(
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
          bodySmall: base.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        );

    return MaterialApp(
      title: 'Member Get Member',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: AppColors.background,
        textTheme: textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: textTheme.titleLarge,
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.7),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.primary,
          contentTextStyle: const TextStyle(color: Colors.white),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (_) => const LoginSignupScreen(),
        AppRoutes.dashboard: (_) => const DashboardScreen(),
        AppRoutes.notifications: (_) => const NotificationsScreen(),
        AppRoutes.profile: (_) => const ProfileScreen(),
      },
    );
  }
}
