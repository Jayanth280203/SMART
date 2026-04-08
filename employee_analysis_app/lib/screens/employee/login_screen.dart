import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import 'signup_screen.dart';
import 'dashboard_screen.dart';

class EmployeeLoginScreen extends StatefulWidget {
  const EmployeeLoginScreen({super.key});

  @override
  State<EmployeeLoginScreen> createState() => _EmployeeLoginScreenState();
}

class _EmployeeLoginScreenState extends State<EmployeeLoginScreen> {
  final _umisController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  void _login() async {
    if (_umisController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('UMIS must be 10 digits'), backgroundColor: Color(0xFFF43F5E)));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.loginEmployee(_umisController.text, _passwordController.text);
      if (mounted) setState(() => _isLoading = false);
      if (result['status'] == 'success') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => EmployeeDashboardScreen(umis: _umisController.text)));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Login failed'), backgroundColor: const Color(0xFFF43F5E)));
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection server error'), backgroundColor: Color(0xFFF43F5E)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          Positioned(top: -200, left: -100, child: _glassOrb(const Color(0xFF6366F1).withOpacity(0.12), 500)),
          Positioned(bottom: -150, right: -100, child: _glassOrb(const Color(0xFF8B5CF6).withOpacity(0.12), 600)),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width > 400 ? 48 : 24, 
                        vertical: MediaQuery.of(context).size.width > 400 ? 60 : 40,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.white.withOpacity(0.9), width: 2),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 40, offset: const Offset(0, 20)),
                          BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
                            ),
                            child: const Icon(Icons.school_rounded, color: Colors.white, size: 36),
                          ),
                          const SizedBox(height: 32),
                          Text('Student Portal', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
                          const SizedBox(height: 8),
                          Text('Enter your credentials to continue', style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 52),
                          
                          _buildInputLabel('UMIS NUMBER'),
                          const SizedBox(height: 10),
                          _buildTextField(_umisController, '10-digit UMIS ID', Icons.badge_outlined, false),
                          const SizedBox(height: 24),
                          
                          _buildInputLabel('PASSWORD (DOB)'),
                          const SizedBox(height: 10),
                          _buildTextField(_passwordController, 'Date of Birth (YYYY-MM-DD)', Icons.lock_outline_rounded, true),
                          
                          const SizedBox(height: 48),
                          
                          _isLoading 
                            ? const CircularProgressIndicator(color: Color(0xFF6366F1))
                            : ElevatedButton(
                                onPressed: _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E293B),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 60),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                                child: Text('SIGN IN TO PORTAL', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13)),
                              ),
                          
                          const SizedBox(height: 40),
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text('No professional profile?', style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500)),
                            TextButton(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeSignupScreen())),
                              child: Text('Register Now', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: const Color(0xFF6366F1), fontSize: 12)),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('← SWITCH ACCESS PORTAL', style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) => Align(
    alignment: Alignment.centerLeft,
    child: Text(label, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF94A3B8), letterSpacing: 1.2)),
  );

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, bool isPass) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: isPass && !_isPasswordVisible,
        keyboardType: !isPass ? TextInputType.number : TextInputType.text,
        inputFormatters: !isPass ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)] : null,
        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13),
          prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 20),
          suffixIcon: isPass ? IconButton(
            icon: Icon(_isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: const Color(0xFF94A3B8), size: 18),
            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
          ) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _glassOrb(ui.Color c, double s) => Container(
    width: s, height: s,
    decoration: BoxDecoration(shape: BoxShape.circle, color: c),
    child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 100, sigmaY: 100), child: Container(color: Colors.transparent)),
  );
}
