import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/role_selection_screen.dart';

void main() {
  runApp(
    const EmployeeAnalysisApp(),
  );
}

class EmployeeAnalysisApp extends StatelessWidget {
  const EmployeeAnalysisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMART | AI Career Intelligence',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        primaryColor: const Color(0xFF6366F1),
        
        // Premium Branding
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFF8B5CF6),
          tertiary: const Color(0xFF10B981),
          surface: Colors.white,
          onSurface: const Color(0xFF1E293B),
        ),

        // Typography Overhaul
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).copyWith(
          displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
          headlineMedium: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
          titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
          bodyLarge: GoogleFonts.outfit(color: const Color(0xFF475569)),
        ),

        // Deep Card Aesthetics
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 2,
          shadowColor: const Color(0xFF6366F1).withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
        ),

        // Elite UI Components
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 50),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
            textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
          hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 14),
        ),
      ),
      home: const RoleSelectionScreen(),
    );
  }
}
