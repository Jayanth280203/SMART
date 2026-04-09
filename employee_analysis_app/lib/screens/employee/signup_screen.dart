import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import 'dart:convert';

class EmployeeSignupScreen extends StatefulWidget {
  const EmployeeSignupScreen({super.key});

  @override
  State<EmployeeSignupScreen> createState() => _EmployeeSignupScreenState();
}

class _EmployeeSignupScreenState extends State<EmployeeSignupScreen> {
  final _umisController = TextEditingController();
  final _stuidController = TextEditingController();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final _degreeController = TextEditingController();
  final _deptController = TextEditingController();
  final _cgpaController = TextEditingController();
  final _yearController = TextEditingController();
  final _skillsController = TextEditingController();
  final _swayamController = TextEditingController();
  final _naanController = TextEditingController();
  final _certsController = TextEditingController();
  final _internsController = TextEditingController();
  final _extracurrController = TextEditingController();
  final _sportsController = TextEditingController();

  Map<String, dynamic> _hierarchy = {};
  List<String> _districts = [];
  List<String> _blocks = [];
  List<String> _colleges = [];

  String? _selectedDistrict;
  String? _selectedBlock;
  String? _selectedCollege;

  bool _isLoading = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    Map<String, dynamic> h = {};
    try {
      h = await ApiService.getHierarchy();
    } catch (e) {
      debugPrint('API hierarchy failed: $e');
    }
    if (h.isEmpty) {
      try {
        final jsonStr = await rootBundle.loadString('assets/hierarchy.json');
        h = json.decode(jsonStr);
      } catch (e) {
        debugPrint('Asset load failed: $e');
      }
    }
    setState(() {
      _hierarchy = h;
      _districts = _hierarchy.keys.map((e) => e.toString()).toList()..sort();
      _isInitializing = false;
    });
  }

  void _onDistrictChanged(String? val) {
    setState(() {
      _selectedDistrict = val;
      _selectedBlock = null;
      _selectedCollege = null;
      _colleges = [];
      if (val != null && _hierarchy.containsKey(val)) {
        final districtData = Map<String, dynamic>.from(_hierarchy[val]);
        _blocks = districtData.keys.toList()..sort();
      } else {
        _blocks = [];
      }
    });
  }

  void _onBlockChanged(String? val) {
    setState(() {
      _selectedBlock = val;
      _selectedCollege = null;
      if (_selectedDistrict != null && val != null) {
        final districtData = Map<String, dynamic>.from(_hierarchy[_selectedDistrict]);
        if (districtData.containsKey(val)) {
          _colleges = List<String>.from(districtData[val])..sort();
        } else {
          _colleges = [];
        }
      } else {
        _colleges = [];
      }
    });
  }

  void _signup() async {
    if (_umisController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('UMIS Number must be 10 digits'), backgroundColor: Color(0xFFF43F5E)));
      return;
    }
    
    final ctrls = [
      _umisController, _stuidController, _nameController, _dobController,
      _mobileController, _emailController,
      _degreeController, _deptController, _cgpaController, _yearController,
      _skillsController, _swayamController, _naanController, _certsController,
      _internsController, _extracurrController, _sportsController
    ];
    
    if (ctrls.any((c) => c.text.isEmpty) || _selectedDistrict == null || _selectedBlock == null || _selectedCollege == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All fields are mandatory'), backgroundColor: Color(0xFFF43F5E)));
      return;
    }

    setState(() => _isLoading = true);
    final data = {
      "UMIS number": _umisController.text,
      "studentID": _stuidController.text,
      "name": _nameController.text,
      "dob": _dobController.text,
      "district": _selectedDistrict,
      "block": _selectedBlock,
      "email_id": _emailController.text,
      "mobile_number": _mobileController.text,
      "college_name": _selectedCollege,
      "degree": _degreeController.text,
      "department": _deptController.text,
      "cgpa": double.tryParse(_cgpaController.text) ?? 0.0,
      "year_of_passing": int.tryParse(_yearController.text) ?? 2024,
      "skills": _skillsController.text,
      "swayam_course": _swayamController.text,
      "naan_mudhalvan_course": _naanController.text,
      "certifications": _certsController.text,
      "internships": _internsController.text,
      "extra_curricular_activities": _extracurrController.text,
      "sports": _sportsController.text
    };

    final result = await ApiService.signupEmployee(data);
    setState(() => _isLoading = false);

    if (result['status'] == 'success') {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: const Color(0xFFF43F5E)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Account Registration', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: _glassOrb(const Color(0xFF6366F1).withOpacity(0.08), 500)),
          Positioned(bottom: -200, left: -100, child: _glassOrb(const Color(0xFF8B5CF6).withOpacity(0.1), 600)),
          
          _isInitializing
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
            : SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 900),
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
                          
                          _buildSection('ACADEMIC IDENTITY', [
                            _field(_umisController, 'UMIS Number', Icons.badge_outlined, kb: TextInputType.number, format: [FilteringTextInputFormatter.digitsOnly], maxL: 10),
                            _field(_stuidController, 'Student ID', Icons.fingerprint_rounded),
                            _field(_nameController, 'Full Professional Name', Icons.person_outline_rounded),
                            _field(_dobController, 'Date of Birth (YYYY-MM-DD)', Icons.calendar_today_rounded, readOnly: true, onTap: _pickDate),
                            _field(_mobileController, 'Mobile Number', Icons.phone_rounded, kb: TextInputType.phone, format: [FilteringTextInputFormatter.digitsOnly], maxL: 10),
                            _field(_emailController, 'Email Address', Icons.email_rounded, kb: TextInputType.emailAddress),
                          ]),
                          
                          const SizedBox(height: 32),
                          _buildSection('INSTITUTIONAL ALIGNMENT', [
                            _drop('Select District *', _districts, _selectedDistrict, _onDistrictChanged, Icons.location_on_outlined),
                            _drop('Select Assembly/Block *', _blocks, _selectedBlock, _onBlockChanged, Icons.map_outlined, enabled: _selectedDistrict != null),
                            _drop('Select College Name *', _colleges, _selectedCollege, (v) => setState(() => _selectedCollege = v), Icons.account_balance_rounded, enabled: _selectedBlock != null),
                          ], isFull: true),

                          const SizedBox(height: 32),
                          _buildSection('EDUCATIONAL TRACK', [
                            _field(_degreeController, 'Current Degree', Icons.school_outlined),
                            _field(_deptController, 'Specialized Department', Icons.category_outlined),
                            _field(_cgpaController, 'Current CGPA', Icons.auto_awesome_rounded, kb: TextInputType.number),
                            _field(_yearController, 'Expected Year of Graduation', Icons.event_available_rounded, kb: TextInputType.number),
                          ]),

                          const SizedBox(height: 32),
                          _buildSection('SKILL ARSENAL', [
                            _field(_skillsController, 'Technical Skills (Comma separated)', Icons.psychology_outlined),
                            _field(_swayamController, 'Swayam/NPTEL Credits', Icons.history_edu_rounded),
                            _field(_naanController, 'Naan Mudhalvan Course', Icons.verified_user_outlined),
                            _field(_certsController, 'Professional Certifications', Icons.card_membership_rounded),
                          ]),

                          const SizedBox(height: 32),
                          _buildSection('ACHIEVEMENTS & ENGAGEMENT', [
                            _field(_internsController, 'Industrial Internships', Icons.business_center_outlined),
                            _field(_extracurrController, 'Extra-Curricular Highlights', Icons.celebration_outlined),
                            _field(_sportsController, 'Sports & Team Lead', Icons.emoji_events_outlined),
                          ]),

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
                                child: Text('CREATE PROFESSIONAL PROFILE', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5)),
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
          child: const Icon(Icons.person_add_rounded, size: 40, color: Color(0xFF6366F1)),
        ),
        const SizedBox(height: 20),
        Text('Student Enrollment', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
        Text('Deploy your academic profile into the SMART network', style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> items, {bool isFull = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w900, color: const Color(0xFF94A3B8), letterSpacing: 2)),
        const SizedBox(height: 20),
        LayoutBuilder(builder: (context, constraints) {
          bool isSingleCol = isFull || constraints.maxWidth < 600;
          double width = isSingleCol ? constraints.maxWidth : (constraints.maxWidth - 25) / 2;
          return Wrap(
            spacing: 24,
            runSpacing: 16,
            children: items.map((item) => SizedBox(width: width, child: item)).toList(),
          );
        }),
      ],
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {TextInputType? kb, List<TextInputFormatter>? format, int? maxL, bool readOnly = false, VoidCallback? onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextField(
            controller: ctrl,
            keyboardType: kb,
            inputFormatters: format,
            maxLength: maxL,
            readOnly: readOnly,
            onTap: onTap,
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
            decoration: InputDecoration(
              hintText: label,
              hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13),
              prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 18),
              counterText: "",
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _drop(String label, List<String> items, String? val, Function(String?) onChange, IconData icon, {bool enabled = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: enabled ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9)),
      ),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        dropdownColor: Colors.white,
        style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: GoogleFonts.outfit(color: enabled ? const Color(0xFF94A3B8) : const Color(0xFFCBD5E1), fontSize: 13),
          prefixIcon: Icon(icon, color: enabled ? const Color(0xFF6366F1) : const Color(0xFFCBD5E1), size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
        value: (items.contains(val)) ? val : null,
        items: enabled ? items.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList() : [],
        onChanged: enabled ? onChange : null,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
      ),
    );
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2004),
      firstDate: DateTime(1960),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF6366F1), onPrimary: Colors.white, surface: Colors.white, onSurface: Color(0xFF1E293B)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dobController.text = picked.toString().split(' ')[0]);
  }

  Widget _glassOrb(ui.Color c, double s) => Container(
    width: s, height: s,
    decoration: BoxDecoration(shape: BoxShape.circle, color: c),
    child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 100, sigmaY: 100), child: Container(color: Colors.transparent)),
  );
}
