import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/auth/presentation/screens/login_screen.dart';

import 'features/resident/presentation/screens/resident_dashboard_screen.dart';
import 'features/legal/presentation/screens/legal_dashboard_screen.dart';
import 'features/technician/presentation/screens/technician_view_screen.dart';

import 'package:fcm_app/core/data/auth_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String initialRoute = '/login';
  final auth = AuthRepository.instance;

  if (await auth.isLoggedIn()) {
    final profile = await auth.getProfile();
    if (profile['success']) {
      final role = profile['data']['role'];
      if (role == 'Jurisdictic') {
        initialRoute = '/legal';
      } else if (role == 'Technician') {
        initialRoute = '/technician';
      } else if (role == 'Resident') {
        initialRoute = '/3d_model';
      }
    }
  }

  runApp(FcmApp(initialRoute: initialRoute));
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
        '/legal': (context) => const AuthGuard(child: LegalDashboardScreen()),
        '/technician': (context) =>
            const AuthGuard(child: TechnicianViewScreen()),
        '/3d_model': (context) =>
            const AuthGuard(child: ResidentDashboardScreen()),
      },
    );
  }
}

/// AuthGuard: "ยาม" ตรวจสอบสิทธิ์ก่อนเข้าหน้าต่างๆ
class AuthGuard extends StatelessWidget {
  final Widget child;
  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthRepository.instance.isLoggedIn(),
      builder: (context, snapshot) {
        // ขณะกำลังเช็คสถานะ ให้แสดงหน้า Loading สวยๆ
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF121212),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD700)),
            ),
          );
        }

        // ถ้ามี Session (Token) อยู่จริง ให้เข้าหน้าหน้าได้
        if (snapshot.hasData && snapshot.data == true) {
          return child;
        }

        // ถ้าไม่มี Session ให้เตะกลับไปหน้า Login ทันที
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/login');
        });
        return const SizedBox.shrink();
      },
    );
  }
}
