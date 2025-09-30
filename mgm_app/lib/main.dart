import 'package:flutter/material.dart';

import 'routes.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_signup_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';
import 'services/data_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DataRepository.instance.ensureInitialized();
  runApp(const MgmApp());
}

class MgmApp extends StatelessWidget {
  const MgmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Member Get Member',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.light,
        useMaterial3: true,
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
