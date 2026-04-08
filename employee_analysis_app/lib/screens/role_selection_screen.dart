import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'employee/login_screen.dart';
import 'employer/login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          // ── BACKGROUND AESTHTICS ───────────────────────────────────────────
          Positioned(top: -150, right: -100, child: _glassOrb(const Color(0xFF6366F1).withOpacity(0.12), 600)),
          Positioned(bottom: -200, left: -100, child: _glassOrb(const Color(0xFF8B5CF6).withOpacity(0.15), 700)),
          Positioned(top: 200, left: -50, child: _glassOrb(const Color(0xFF10B981).withOpacity(0.05), 300)),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeroSection(context),
                    const SizedBox(height: 8),
                    // Responsive Grid for Cards
                    LayoutBuilder(builder: (context, constraints) {
                      bool isSmall = constraints.maxWidth < 650;
                      return Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 24,
                        runSpacing: 24,
                        children: [
                          _buildPremiumCard(
                            context,
                            'STUDENT PORTAL',
                            'Analyze your academic & skill profile to unlock AI-driven career predictions and smart job matching.',
                            Icons.school_rounded,
                            const EmployeeLoginScreen(),
                            const Color(0xFF6366F1),
                            isSmall,
                          ),
                          _buildPremiumCard(
                            context,
                            'HIRE TALENT',
                            'Discover elite state-wide talent distribution and student analytics tailored to your industry needs.',
                            Icons.corporate_fare_rounded,
                            const EmployerLoginScreen(),
                            const Color(0xFF8B5CF6),
                            isSmall,
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    bool isSmall = MediaQuery.of(context).size.width < 400;
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.35), blurRadius: 15, offset: const Offset(0, 5))
                ],
              ),
              child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'SMART',
              style: GoogleFonts.outfit(
                fontSize: isSmall ? 28 : 34,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1E293B),
                letterSpacing: -1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Skill Mapping and Analytics for Recruiting the Talents',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: const Color(0xFF6366F1),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumCard(BuildContext context, String title, String subtitle, IconData icon, Widget target, Color color, bool isSmall) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => target)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isSmall ? double.infinity : 210, // Reduced from 240
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(color: const Color(0xFF1E293B).withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.12), width: 1.0),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B), letterSpacing: 0.5),
              ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 10, height: 1.3, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('EXPLORE', style: GoogleFonts.outfit(color: color, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, color: color, size: 14),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildFooter() => const SizedBox.shrink();

  Widget _glassOrb(Color c, double s) => Container(
    width: s, height: s,
    decoration: BoxDecoration(shape: BoxShape.circle, color: c),
    child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 100, sigmaY: 100), child: Container(color: Colors.transparent)),
  );
}
