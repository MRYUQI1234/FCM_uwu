import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/resident/presentation/screens/resident_dashboard_screen.dart';
import 'features/legal/presentation/screens/legal_dashboard_screen.dart';
import 'features/technician/presentation/screens/technician_view_screen.dart';

import 'package:fcm_app/core/data/auth_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isLoggedIn = await AuthRepository.instance.isLoggedIn();
  runApp(FcmApp(initialRoute: isLoggedIn ? '/legal' : '/login'));
}

class FcmApp extends StatelessWidget {
  final String initialRoute;
  const FcmApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FCM System',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212), // Dark Background
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFD700), // Gold
          secondary: Color(0xFFD4AF37), // Metallic Gold
          surface: Color(0xFF1E1E1E), // Dark Grey Surface
          onPrimary: Colors.black, // Text on Gold
        ),
        useMaterial3: true,
        // fontFamily: 'Roboto', // Removed to use GoogleFonts
        textTheme: GoogleFonts.promptTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          foregroundColor: Color(0xFFFFD700), // Gold Text in AppBar
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD700), // Gold Button
            foregroundColor: Colors.black, // Black Text
            textStyle: GoogleFonts.prompt(fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFFFD700)), // Gold Border
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFFFD700), width: 2),
          ),
          labelStyle: TextStyle(color: Color(0xFFD4AF37)),
          prefixIconColor: Color(0xFFFFD700),
        ),
      ),
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/legal': (context) => const LegalDashboardScreen(),
        '/technician': (context) => const TechnicianViewScreen(),
        '/3d_model': (context) => const ResidentDashboardScreen(),
      },
    );
  }
}
