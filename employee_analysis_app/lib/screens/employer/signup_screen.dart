import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

class EmployerSignupScreen extends StatefulWidget {
  const EmployerSignupScreen({super.key});

  @override
  State<EmployerSignupScreen> createState() => _EmployerSignupScreenState();
}

class _EmployerSignupScreenState extends State<EmployerSignupScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _mobileController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _companyTypeController = TextEditingController();
  final _industryDomainController = TextEditingController();
  final _headOfficeCityController = TextEditingController();
  final _regNumberController = TextEditingController();
  
  String? _fileName;
  Uint8List? _fileBytes;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _emailError;
  String? _mobileError;

  void _pickProof() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
    );

    if (result != null) {
      if (mounted) {
        setState(() {
          _fileName = result.files.first.name;
          _fileBytes = result.files.first.bytes;
        });
      }
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(email.trim());
  }

  void _onEmailChanged(String value) {
    setState(() {
      if (value.trim().isEmpty) {
        _emailError = 'Official email address is required';
      } else if (!_isValidEmail(value)) {
        _emailError = 'Enter a valid email';
      } else {
        _emailError = null;
      }
    });
  }

  void _onMobileChanged(String value) {
    setState(() {
      if (value.isEmpty) {
        _mobileError = 'Mobile number is required';
      } else if (value.length < 10) {
        _mobileError = 'Must be exactly 10 digits';
      } else {
        _mobileError = null;
      }
    });
  }

  void _signup() async {
    _onEmailChanged(_emailController.text);
    _onMobileChanged(_mobileController.text);

    if (_fullNameController.text.trim().isEmpty || _emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty ||
        _mobileController.text.trim().isEmpty || _companyNameController.text.trim().isEmpty || _companyTypeController.text.trim().isEmpty ||
        _industryDomainController.text.trim().isEmpty || _headOfficeCityController.text.trim().isEmpty || _regNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All mandatory fields are required'), backgroundColor: Color(0xFFF43F5E)));
      return;
    }

    if (_emailError != null || _mobileError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_emailError ?? _mobileError ?? 'Fix validation errors'), backgroundColor: const Color(0xFFF43F5E)));
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match'), backgroundColor: Color(0xFFF43F5E)));
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      "full_name": _fullNameController.text.trim(),
      "email": _emailController.text.trim(),
      "password": _passwordController.text.trim(),
      "mobile": _mobileController.text.trim(),
      "company_name": _companyNameController.text.trim(),
      "company_type": _companyTypeController.text.trim(),
      "industry_domain": _industryDomainController.text.trim(),
      "head_office_city": _headOfficeCityController.text.trim(),
      "reg_number": _regNumberController.text.trim(),
      "proof_file": _fileName ?? "",
    };

    try {
      final result = await ApiService.signupEmployer(data);
      if (mounted) setState(() => _isLoading = false);

      if (result['status'] == 'success') {
        Navigator.pop(context);
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Signup failed'), backgroundColor: const Color(0xFFF43F5E)));
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFF43F5E)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Enterprise Onboarding', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned(top: -100, left: -100, child: _glassOrb(const Color(0xFF6366F1).withOpacity(0.08), 500)),
          Positioned(bottom: -200, right: -100, child: _glassOrb(const Color(0xFF10B981).withOpacity(0.1), 600)),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 850),
                  padding: EdgeInsets.all(MediaQuery.of(context).size.width > 500 ? 40 : 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 40, offset: const Offset(0, 20))],
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 48),
                      
                      _buildSection('RECRUITER IDENTITY', [
                        _field(_fullNameController, 'Full Professional Name', Icons.person_outline_rounded),
                        _field(_emailController, 'Official Work Email', Icons.mail_outline_rounded, kb: TextInputType.emailAddress, onChanged: _onEmailChanged, error: _emailError),
                        _field(_mobileController, 'Mobile Contact Number', Icons.phone_android_outlined, kb: TextInputType.phone, format: [FilteringTextInputFormatter.digitsOnly], maxL: 10, onChanged: _onMobileChanged, error: _mobileError),
                        _responsiveRow([
                          Expanded(child: _field(_passwordController, 'Access Password', Icons.lock_outline_rounded, obscure: !_isPasswordVisible, showToggle: true)),
                          const SizedBox(width: 16),
                          Expanded(child: _field(_confirmPasswordController, 'Confirm Access', Icons.lock_outline_rounded, obscure: !_isPasswordVisible)),
                        ]),
                      ]),

                      const SizedBox(height: 32),
                      _buildSection('CORPORATE PROFILE', [
                        _field(_companyNameController, 'Enterprise Name', Icons.business_outlined),
                        _drop('Enterprise Type', [
                          'IT / Software', 'Non-IT / Services', 'Manufacturing', 'Startup', 'Government / PSU', 'NGO / Others'
                        ], _companyTypeController, Icons.category_outlined),
                        _field(_industryDomainController, 'Industry Strategic Domain', Icons.domain_outlined),
                        _responsiveRow([
                          Expanded(child: _field(_headOfficeCityController, 'Head Office City', Icons.location_city_outlined)),
                          const SizedBox(width: 16),
                          Expanded(child: _field(_regNumberController, 'Corporate Reg No', Icons.app_registration_outlined)),
                        ]),
                      ]),

                      const SizedBox(height: 32),
                      _buildSection('ENTERPRISE VERIFICATION', [
                        _buildFileUpload(),
                      ], isFull: true),

                      const SizedBox(height: 60),
                      _isLoading
                        ? const CircularProgressIndicator(color: Color(0xFF6366F1))
                        : ElevatedButton(
                            onPressed: _signup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E293B),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 64),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: Text('INITIATE STRATEGIC PARTNERSHIP', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.08), shape: BoxShape.circle),
          child: const Icon(Icons.business_rounded, size: 40, color: Color(0xFF6366F1)),
        ),
        const SizedBox(height: 20),
        Text('Employer Onboarding', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
        Text('Secure access to Tamil Nadu\'s elite academic talent pool', style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _responsiveRow(List<Widget> children) {
    bool isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children.map((c) {
          if (c is Expanded) return Padding(padding: const EdgeInsets.only(bottom: 16), child: c.child);
          if (c is SizedBox) return const SizedBox.shrink();
          return c;
        }).toList(),
      );
    }
    return Row(children: children);
  }

  Widget _buildSection(String title, List<Widget> items, {bool isFull = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w900, color: const Color(0xFF94A3B8), letterSpacing: 2)),
        const SizedBox(height: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: items.map((item) => Padding(padding: const EdgeInsets.only(bottom: 16), child: item)).toList(),
        ),
      ],
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {TextInputType? kb, List<TextInputFormatter>? format, int? maxL, bool obscure = false, bool showToggle = false, void Function(String)? onChanged, String? error}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: error != null ? const Color(0xFFF43F5E) : const Color(0xFFE2E8F0)),
          ),
          child: TextField(
            controller: ctrl,
            keyboardType: kb,
            inputFormatters: format,
            maxLength: maxL,
            obscureText: obscure,
            onChanged: onChanged,
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
            decoration: InputDecoration(
              hintText: label,
              hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13),
              prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 18),
              counterText: "",
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: showToggle ? IconButton(
                icon: Icon(_isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: const Color(0xFF94A3B8), size: 18),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ) : null,
            ),
          ),
        ),
        if (error != null) Padding(padding: const EdgeInsets.only(top: 4, left: 4), child: Text(error, style: GoogleFonts.outfit(color: const Color(0xFFF43F5E), fontSize: 10))),
      ],
    );
  }

  Widget _drop(String label, List<String> items, TextEditingController ctrl, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        dropdownColor: Colors.white,
        style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13),
          prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
        value: ctrl.text.isEmpty ? null : ctrl.text,
        items: items.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
        onChanged: (v) => setState(() => ctrl.text = v!),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
      ),
    );
  }

  Widget _buildFileUpload() {
    return InkWell(
      onTap: _pickProof,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9).withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _fileName != null ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0), style: BorderStyle.solid),
        ),
        child: Row(
          children: [
            Icon(_fileName != null ? Icons.check_circle_rounded : Icons.cloud_upload_outlined, color: _fileName != null ? const Color(0xFF10B981) : const Color(0xFF64748B)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _fileName ?? 'Upload Corporate Credential (PDF/JPG)',
                style: GoogleFonts.outfit(color: _fileName != null ? const Color(0xFF1E293B) : const Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            if (_fileName != null) Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text('VERIFIED', style: GoogleFonts.outfit(color: const Color(0xFF6366F1), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ],
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
