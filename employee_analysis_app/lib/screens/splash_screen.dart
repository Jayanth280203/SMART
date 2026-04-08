import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'role_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _titleFade;
  late Animation<double> _subtitleFade;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );

    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.4, 0.7, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack)),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );

    _mainController.forward();

    Timer(const Duration(milliseconds: 4500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const RoleSelectionScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 1000),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          Positioned(top: -150, left: -100, child: _glassOrb(const Color(0xFF6366F1).withOpacity(0.12), 500)),
          Positioned(bottom: -150, right: -100, child: _glassOrb(const Color(0xFF8B5CF6).withOpacity(0.12), 600)),
          
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _titleFade,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 40, offset: const Offset(0, 20)),
                            ],
                          ),
                          child: const Icon(Icons.rocket_launch_rounded, size: 60, color: Colors.white),
                        ),
                        const SizedBox(height: 48),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF1E293B), Color(0xFF475569)],
                          ).createShader(bounds),
                          child: Text(
                            'SMART',
                            style: GoogleFonts.outfit(
                              fontSize: 64,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FadeTransition(
                  opacity: _subtitleFade,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        Text(
                          'Skill Mapping and Analytics for Recruiting the Talents',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                            color: const Color(0xFF6366F1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Positioned(
            bottom: 64,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _subtitleFade,
              child: Center(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF6366F1).withOpacity(0.3)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassOrb(ui.Color c, double s) => Container(
    width: s, height: s,
    decoration: BoxDecoration(shape: BoxShape.circle, color: c),
    child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 100, sigmaY: 100), child: Container(color: Colors.transparent)),
  );
}
