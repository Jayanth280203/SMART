import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:syncfusion_flutter_maps/maps.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;
import '../role_selection_screen.dart';

class MapDataModel {
  MapDataModel(this.name, this.count, this.percentage, this.color);
  final String name;
  final int count;
  final double percentage;
  Color color;
  Map<String, dynamic>? extraData;
}

class EmployerDashboardScreen extends StatefulWidget {
  final String? email;
  const EmployerDashboardScreen({super.key, this.email});
  @override
  State<EmployerDashboardScreen> createState() => _EmployerDashboardScreenState();
}

class _EmployerDashboardScreenState extends State<EmployerDashboardScreen> {
  String _selectedRole = '';
  List<String> _allRoles = [];
  bool _isLoading = true;
  String _activeSection = 'map';

  String _mapLevel = 'district';
  String? _mapDistrict;
  String? _mapBlock;
  String? _mapCollege;

  String _dataLevel = 'district';
  String? _dataDistrict;
  String? _dataBlock;
  String? _dataCollege;

  List<MapDataModel> _viewData = [];
  late MapShapeSource _shapeSource;
  MapZoomPanBehavior? _zoomPanBehavior;

  Map<String, dynamic>? _employerProfile;
  bool _isProfileLoading = false;
  int _totalMatched = 0;
  Map<String, dynamic> _districtBreakdown = {};

  static const List<String> _geojsonDistricts = [
    'Ariyalur','Chennai','Coimbatore','Cuddalore','Dharmapuri',
    'Dindigul','Erode','Kancheepuram','Kanniyakumari','Karur',
    'Krishnagiri','Madurai','Nagapattinam','Namakkal','Perambalur',
    'Pudukkottai','Ramanathapuram','Salem','Sivaganga','Thanjavur',
    'The Nilgiris','Theni','Thiruvallur','Thiruvarur','Thoothukudi',
    'Tiruchchirappalli','Tirunelveli','Tiruppur','Tiruvannamalai',
    'Vellore','Villupuram','Virudhunagar',
  ];

  static const List<Color> _colors = [
    Color(0xFF6366F1),Color(0xFF10B981),Color(0xFFF59E0B),Color(0xFF8B5CF6),
    Color(0xFFEC4899),Color(0xFF06B6D4),Color(0xFF84CC16),Color(0xFFF43F5E),
    Color(0xFF14B8A6),Color(0xFFEAB308),Color(0xFFD946EF),Color(0xFF0EA5E9),
    Color(0xFF22C55E),Color(0xFFF97316),Color(0xFFFACC15),Color(0xFF4F46E5),
    Color(0xFF0891B2),Color(0xFF16A34A),Color(0xFFEA580C),Color(0xFFDB2777),
    Color(0xFF7C3AED),Color(0xFF0284C7),Color(0xFF2563EB),Color(0xFF34D399),
    Color(0xFFFB923C),Color(0xFFA78BFA),Color(0xFF38BDF8),Color(0xFF4ADE80),
    Color(0xFFF472B6),Color(0xFFCB6CE6),Color(0xFFFF6B6B),Color(0xFF6366F1),
  ];

  static String _normalize(String raw) {
    switch (raw.trim()) {
      case 'Tiruchirappalli': return 'Tiruchchirappalli';
      case 'Viluppuram':      return 'Villupuram';
      case 'Nilgiris':        return 'The Nilgiris';
      case 'Chengalpattu':    return 'Kancheepuram';
      case 'Kallakurichi':    return 'Villupuram';
      case 'Mayiladuthurai':  return 'Nagapattinam';
      case 'Ranipet':         return 'Vellore';
      case 'Tenkasi':         return 'Tirunelveli';
      case 'Tirupattur':      return 'Vellore';
      default: return raw.trim();
    }
  }

  @override
  void initState() {
    super.initState();
    _zoomPanBehavior = MapZoomPanBehavior(
      enableDoubleTapZooming: true, enablePanning: true,
      zoomLevel: 1.5, focalLatLng: const MapLatLng(11.1271, 78.6569),
    );
    _shapeSource = MapShapeSource.asset(
      'assets/tamilnadu_districts.json',
      shapeDataField: 'Dist_Name',
      dataCount: 0,
      primaryValueMapper: (i) => '',
    );
    _loadInitialData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  String get _currentLevel    => _activeSection == 'map' ? _mapLevel    : _dataLevel;
  String? get _currentDistrict => _activeSection == 'map' ? _mapDistrict : _dataDistrict;
  String? get _currentBlock    => _activeSection == 'map' ? _mapBlock    : _dataBlock;
  String? get _currentCollege  => _activeSection == 'map' ? _mapCollege  : _dataCollege;

  void _setCurrentLevel(String lvl) {
    if (_activeSection == 'map') {
      setState(() => _mapLevel = lvl);
    } else {
      setState(() => _dataLevel = lvl);
    }
  }

  Future<void> _loadInitialData() async {
    final roles = await ApiService.getRoles();
    setState(() {
      _allRoles = List<String>.from(roles);
      if (_allRoles.length < 100) {
        _allRoles.addAll([
          'Blockchain Developer','Cybersecurity Specialist','Embedded Systems Engineer',
          'Financial Analyst','SEO Consultant','Marketing Manager','HR Generalist',
          'Network Engineer','Product Designer','Quality Assurance Tester','Content Writer',
          'Data Engineer','Mobile Developer (Flutter)','React Developer','Angular Developer',
          'Vue.js Developer','Cloud Infrastructure Architect','Site Reliability Engineer',
          'Penetration Tester','Solutions Architect','Scrum Master',
        ]);
      }
    });
    await _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final level    = _currentLevel;
      final district = _currentDistrict;
      final block    = _currentBlock;
      final college  = _currentCollege;

      final data = await ApiService.getEmployerAnalytics(
        _selectedRole, level, district: district, block: block, college: college,
      );

      final List<MapDataModel> items = [];
      for (var item in data) {
        String name;
        if (level == 'district') name = _normalize(item['district'].toString());
        else if (level == 'block') name = item['block'].toString();
        else if (level == 'college') name = item['college_name'].toString();
        else {
          final dept = item['department'] != null && item['department'].toString() != 'N/A'
              ? ' (${item['department']})' : '';
          name = item['individual_name'].toString() + dept;
        }

        final model = MapDataModel(
          name,
          (item['count'] as num).toInt(),
          (item['percentage'] as num).toDouble(),
          Colors.blue,
        );
        if (level == 'individual') {
          model.extraData = Map<String, dynamic>.from(item);
        }
        items.add(model);
      }

      List<MapDataModel> newData;
      if (level == 'district') {
        int ci = 0;
        newData = _geojsonDistricts.map((d) {
          final matched = items.where((m) => m.name == d).toList();
          final count = matched.isNotEmpty ? matched[0].count : 0;
          final pct   = matched.isNotEmpty ? matched[0].percentage : 0.0;
          final col   = _colors[ci++ % _colors.length];
          return MapDataModel(d, count, pct, pct > 0 ? col : const Color(0xFFF1F5F9));
        }).toList();
      } else {
        newData = items;
        int ci = 0;
        for (var d in newData) {
          d.color = _colors[ci++ % _colors.length];
          if (d.percentage == 0) d.color = const Color(0xFFF1F5F9);
        }
      }

      final int total = data.isNotEmpty && data[0].containsKey('total_matched_overall')
          ? (data[0]['total_matched_overall'] as num).toInt()
          : items.fold<int>(0, (a, b) => a + b.count);

      Map<String, dynamic> breakdown = {};
      if (level == 'district') {
        final raw = await ApiService.getDistrictBreakdown(_selectedRole);
        raw.forEach((k, v) => breakdown.putIfAbsent(_normalize(k), () => v));
      }

      setState(() {
        _viewData          = newData;
        _totalMatched      = total;
        _districtBreakdown = breakdown;
        if (level == 'district') {
          _shapeSource = MapShapeSource.asset(
            'assets/tamilnadu_districts.json',
            shapeDataField: 'Dist_Name',
            dataCount: newData.length,
            primaryValueMapper: (i) => newData[i].name,
            dataLabelMapper: (i) {
              final d = newData[i];
              return _selectedRole.isNotEmpty && d.percentage > 0
                  ? '${d.name}\n${d.percentage.toStringAsFixed(1)}%'
                  : d.name;
            },
            shapeColorValueMapper: (i) => newData[i].color,
          );
        }
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _drillDown(int index) {
    final item = _viewData[index];
    if (_currentLevel == 'district') {
      if (_activeSection == 'map') {
        setState(() { _mapDistrict = item.name; _mapLevel = 'block'; });
      } else {
        setState(() { _dataDistrict = item.name; _dataLevel = 'block'; });
      }
      _loadAnalytics();
    } else if (_currentLevel == 'block') {
      if (_activeSection == 'map') {
        setState(() { _mapBlock = item.name; _mapLevel = 'college'; });
      } else {
        setState(() { _dataBlock = item.name; _dataLevel = 'college'; });
      }
      _loadAnalytics();
    } else if (_currentLevel == 'college') {
      if (_activeSection == 'map') {
        setState(() { _mapCollege = item.name; _mapLevel = 'individual'; });
      } else {
        setState(() { _dataCollege = item.name; _dataLevel = 'individual'; });
      }
      _loadAnalytics();
    }
  }

  void _resetToDistrict() {
    if (_activeSection == 'map') {
      setState(() { _mapLevel = 'district'; _mapDistrict = null; _mapBlock = null; _mapCollege = null; });
    } else {
      setState(() { _dataLevel = 'district'; _dataDistrict = null; _dataBlock = null; _dataCollege = null; });
    }
    _loadAnalytics();
  }

  void _resetToBlock() {
    if (_activeSection == 'map') {
      setState(() { _mapLevel = 'block'; _mapBlock = null; _mapCollege = null; });
    } else {
      setState(() { _dataLevel = 'block'; _dataBlock = null; _dataCollege = null; });
    }
    _loadAnalytics();
  }

  void _resetToCollege() {
    if (_activeSection == 'map') {
      setState(() { _mapLevel = 'college'; _mapCollege = null; });
    } else {
      setState(() { _dataLevel = 'college'; _dataCollege = null; });
    }
    _loadAnalytics();
  }

  Future<void> _loadEmployerProfile({String? customEmail}) async {
    setState(() => _isProfileLoading = true);
    try {
      final email = customEmail ?? _employerProfile?['email'] ?? widget.email ?? '';
      final data  = await ApiService.getEmployerProfile(email);
      setState(() { _employerProfile = data; _isProfileLoading = false; });
    } catch (_) {
      setState(() => _isProfileLoading = false);
    }
  }

  void _updateProfile(Map<String, dynamic> updated) async {
    try {
      updated['original_email'] = _employerProfile?['email'];
      final ok = await ApiService.updateEmployerProfile(updated);
      if (ok) {
        // Use the potentially new email to reload
        await _loadEmployerProfile(customEmail: updated['email']);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Updated Successfully')));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update failed. This email might already be in use or server error.'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: isWide ? null : Drawer(backgroundColor: Colors.white, child: _buildSidebar()),
      body: Stack(children: [
        Positioned(top: -150, left: -200, child: _orb(const Color(0xFF6366F1), 600)),
        Positioned(bottom: -200, right: -150, child: _orb(const Color(0xFF8B5CF6), 700)),
        Positioned(top: 100, right: 50, child: _orb(const Color(0xFF06B6D4), 400)),
        Positioned(bottom: 100, left: 250, child: _orb(const Color(0xFFF59E0B), 500)),
        Positioned.fill(child: Row(children: [
          if (isWide) Padding(padding: const EdgeInsets.all(20), child: _buildSidebar()),
          Expanded(child: Padding(
            padding: EdgeInsets.fromLTRB(isWide ? 0 : 20, 20, 20, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _buildTopBar(isMobile: !isWide),
              const SizedBox(height: 16),
              Expanded(child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: _glassDeco(),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                    : _activeSection == 'map'
                        ? _buildMapSection()
                        : _activeSection == 'data'
                            ? _buildDataSection()
                            : _buildProfileSection(),
              )),
            ]),
          )),
        ])),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SIDEBAR
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: _glassDeco(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.fromLTRB(28, 40, 24, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Text('SMART', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B), letterSpacing: -0.5)),
            ]),
            const SizedBox(height: 8),
            Text('RECRUITER COMMAND CENTER', style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF94A3B8), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ]),
        ),
        Expanded(child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _sidebarBtn('Overview', Icons.dashboard_customize_rounded, _activeSection == 'map', () {
              setState(() => _activeSection = 'map');
              _loadAnalytics();
            }),
            const SizedBox(height: 4),
            _sidebarBtn('Talent Ledger', Icons.analytics_rounded, _activeSection == 'data', () {
              setState(() => _activeSection = 'data');
              _loadAnalytics();
            }),
            const SizedBox(height: 4),
            _sidebarBtn('My Workspace', Icons.person_pin_rounded, _activeSection == 'profile', () {
              setState(() => _activeSection = 'profile');
              _loadEmployerProfile();
            }),
            const Padding(padding: EdgeInsets.fromLTRB(16, 32, 16, 12), child: Divider(color: Color(0xFFF1F5F9), thickness: 1.5)),
            _sectionLabel('GEOGRAPHICAL DRILL-DOWN', Icons.map_rounded),
            const SizedBox(height: 8),
            _hierarchyTile('Metros & Districts', Icons.location_city_rounded, 'district'),
            _hierarchyTile('Blocks & Clusters', Icons.hub_rounded, 'block'),
            _hierarchyTile('Institutions', Icons.account_balance_rounded, 'college'),
            _hierarchyTile('Individual Talent', Icons.group_add_rounded, 'individual'),
            const SizedBox(height: 40),
          ],
        )),
        Padding(padding: const EdgeInsets.all(24),
          child: InkWell(
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                (route) => false,
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
                const SizedBox(width: 12),
                Text('Terminate Session', style: GoogleFonts.outfit(color: const Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _sectionLabel(String label, IconData icon) => Padding(
    padding: const EdgeInsets.only(left: 16, bottom: 8),
    child: Row(children: [
      Icon(icon, size: 12, color: const Color(0xFF94A3B8)),
      const SizedBox(width: 8),
      Text(label, style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
    ]),
  );

  Widget _sidebarBtn(String label, IconData icon, bool active, VoidCallback onTap) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF6366F1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: active ? [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
        ),
        child: Row(children: [
          Icon(icon, size: 20, color: active ? Colors.white : const Color(0xFF94A3B8)),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.outfit(color: active ? Colors.white : const Color(0xFF64748B), fontSize: 14, fontWeight: active ? FontWeight.bold : FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _hierarchyTile(String label, IconData icon, String level) {
    final isActive = _currentLevel == level && _activeSection != 'profile';
    bool enabled = true;
    if (level == 'block'      && _currentDistrict == null) enabled = false;
    if (level == 'college'    && _currentBlock    == null) enabled = false;
    if (level == 'individual' && _currentCollege  == null) enabled = false;

    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: InkWell(
        onTap: enabled ? () { _setCurrentLevel(level); _loadAnalytics(); } : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF6366F1).withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            Icon(icon, size: 16, color: isActive ? const Color(0xFF6366F1) : const Color(0xFF94A3B8)),
            const SizedBox(width: 12),
            Text(label, style: GoogleFonts.outfit(color: isActive ? const Color(0xFF6366F1) : const Color(0xFF64748B), fontSize: 13, fontWeight: isActive ? FontWeight.bold : FontWeight.w500)),
          ]),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // TOP BAR
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildTopBar({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 32, vertical: isMobile ? 12 : 0),
      constraints: const BoxConstraints(minHeight: 90),
      decoration: _glassDeco(),
      child: isMobile
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Builder(builder: (ctx) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(ctx).openDrawer())),
                  Expanded(child: _buildRoleSearch(isMobile: isMobile)),
                ]),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBreadcrumb(),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Flexible(
                              child: Text(_selectedRole.isEmpty ? 'All Talent' : _selectedRole, 
                                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)), 
                                overflow: TextOverflow.ellipsis),
                            ),
                            if (_selectedRole.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: InkWell(
                                  onTap: () { setState(() => _selectedRole = ''); _loadAnalytics(); },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                    child: const Text('Clear', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    )),
                    Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('TALENT', style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w900, color: const Color(0xFF94A3B8), letterSpacing: 1)),
                      Text(_totalMatched.toString(), style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF6366F1))),
                    ]),
                  ],
                ),
              ],
            )
          : Row(children: [
              Expanded(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBreadcrumb(),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(_selectedRole.isEmpty ? 'All Talent' : _selectedRole,
                          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                      if (_selectedRole.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: TextButton.icon(
                            onPressed: () { setState(() => _selectedRole = ''); _loadAnalytics(); },
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Reset Map'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              backgroundColor: Colors.redAccent.withOpacity(0.1),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              minimumSize: Size.zero,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              )),
              SizedBox(width: 360, child: _buildRoleSearch(isMobile: isMobile)),
              const SizedBox(width: 24),
              Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('QUALIFIED TALENT', style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w900, color: const Color(0xFF94A3B8), letterSpacing: 1)),
                Text(_totalMatched.toString(), style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, color: const Color(0xFF6366F1))),
              ]),
            ]),
    );
  }

  Widget _buildBreadcrumb() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        _breadcrumbItem('TAMIL NADU', null),
        if (_currentDistrict != null) _breadcrumbItem(_currentDistrict!, _resetToDistrict),
        if (_currentBlock    != null) _breadcrumbItem(_currentBlock!,    _resetToBlock),
        if (_currentCollege  != null) _breadcrumbItem(_currentCollege!,  _resetToCollege),
      ]),
    );
  }

  Widget _breadcrumbItem(String text, VoidCallback? onTap) => Row(children: [
    InkWell(
      onTap: onTap,
      child: Text(text.toUpperCase(), style: GoogleFonts.outfit(
        fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5,
        color: onTap == null ? const Color(0xFF94A3B8) : const Color(0xFF6366F1),
      )),
    ),
    if (onTap != null) const Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFFCBD5E1)),
  ]);

  Widget _buildRoleSearch({required bool isMobile}) {
    return Autocomplete<String>(
      optionsBuilder: (val) {
        if (val.text.isEmpty) return const Iterable<String>.empty();
        final matches = _allRoles.where((r) => r.toLowerCase().contains(val.text.toLowerCase())).toList();
        return matches.isEmpty ? ['No results found'] : matches.take(8);
      },
      onSelected: (role) {
        if (role == 'No results found') return;
        setState(() => _selectedRole = role);
        _loadAnalytics();
      },
      fieldViewBuilder: (ctx, ctrl, fn, onSubmit) => Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: TextField(
          controller: ctrl, focusNode: fn,
          style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF1E293B)),
          onChanged: (v) {
            // Automatically clear the map if the user backspaces the entire search text
            if (v.trim().isEmpty && _selectedRole.isNotEmpty) {
              setState(() => _selectedRole = '');
              _loadAnalytics();
            }
          },
          onSubmitted: (v) { setState(() => _selectedRole = v); _loadAnalytics(); },
          decoration: InputDecoration(
            hintText: isMobile ? 'Search...' : 'Search skills or roles...',
            hintStyle: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8)),
            prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF6366F1)),
            suffixIcon: _selectedRole.isNotEmpty || ctrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.cancel_rounded, size: 18, color: Color(0xFF94A3B8)),
                    onPressed: () {
                      ctrl.clear();
                      fn.unfocus();
                      setState(() => _selectedRole = '');
                      _loadAnalytics();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          ),
        ),
      ),
      optionsViewBuilder: (ctx, onSel, opts) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 16, borderRadius: BorderRadius.circular(12), shadowColor: Colors.black26,
          child: Container(
            width: 360, constraints: const BoxConstraints(maxHeight: 280),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0)), color: Colors.white),
            child: ListView(padding: EdgeInsets.zero, shrinkWrap: true,
              children: opts.map((role) {
                if (role == 'No results found') return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('No results found', style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13)),
                );
                return InkWell(onTap: () => onSel(role),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
                    child: Row(children: [
                      const Icon(Icons.work_outline_rounded, size: 15, color: Color(0xFF6366F1)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(role, style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.w500))),
                      const Icon(Icons.north_west, size: 12, color: Color(0xFF94A3B8)),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // MAP SECTION
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildMapSection() {
    return Stack(children: [
      Positioned.fill(child: _buildMap()),
      if (_mapLevel == 'block' || _mapLevel == 'college' || _mapLevel == 'individual')
        Positioned(
          top: MediaQuery.of(context).size.width > 900 ? 16 : null, 
          bottom: 16,
          left: MediaQuery.of(context).size.width > 900 ? null : 16,
          right: 16,
          child: Container(
            width: MediaQuery.of(context).size.width > 900 ? 320 : MediaQuery.of(context).size.width - 32,
            height: MediaQuery.of(context).size.width > 900 ? null : MediaQuery.of(context).size.height * 0.45,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.1), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: _buildMapOverlayList(),
          ),
        ),
      if (_mapLevel != 'district')
        Positioned(top: 16, left: 16, child: _buildMapBackButton()),
      if (_selectedRole.isNotEmpty && _mapLevel == 'district')
        Positioned(bottom: 16, left: 16, child: _buildHeatmapLegend()),
    ]);
  }

  Widget _buildMap() {
    try {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: SfMaps(layers: [
          MapShapeLayer(
            source: _shapeSource,
            zoomPanBehavior: _zoomPanBehavior,
            showDataLabels: true,
            dataLabelSettings: const MapDataLabelSettings(
              overflowMode: MapLabelOverflow.visible,
              textStyle: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black45, blurRadius: 4)]),
            ),
            onSelectionChanged: (i) => _drillDown(i),
            selectionSettings: const MapSelectionSettings(
              color: Color(0x226366F1), strokeWidth: 2.5, strokeColor: Color(0xFF6366F1)),
          ),
        ]),
      );
    } catch (_) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.map_outlined, size: 64, color: Color(0xFF6366F1)),
        const SizedBox(height: 16),
        Text('Map unavailable — select a district to explore', style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 16)),
      ]));
    }
  }

  Widget _buildMapBackButton() {
    return GestureDetector(
      onTap: _mapLevel == 'individual' ? _resetToCollege
           : _mapLevel == 'college'    ? _resetToBlock
           : _resetToDistrict,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16)],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.arrow_back_ios_rounded, size: 14, color: Color(0xFF6366F1)),
          const SizedBox(width: 6),
          Text(
            _mapLevel == 'individual' ? 'Back to Colleges'
          : _mapLevel == 'college'   ? 'Back to Blocks'
          : 'Back to Districts',
            style: GoogleFonts.outfit(color: const Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeatmapLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.circle, size: 10, color: Color(0xFF6366F1)),
        const SizedBox(width: 6),
        Text('Talent density for: $_selectedRole',
            style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF1E293B), fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildMapOverlayList() {
    final label = _mapLevel == 'block'
        ? '${_mapDistrict ?? ''} — BLOCKS'
        : _mapLevel == 'college'
            ? '${_mapBlock ?? ''} — COLLEGES'
            : '${_mapCollege ?? ''} — INDIVIDUALS';
    final emoji = _mapLevel == 'block' ? '📍' : _mapLevel == 'college' ? '🏫' : '👨‍🎓';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1)),
          if (_selectedRole.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('For: $_selectedRole', style: GoogleFonts.outfit(color: const Color(0xFF6366F1), fontSize: 11, fontWeight: FontWeight.w600)),
            ),
        ]),
      ),
      const Divider(height: 1, color: Color(0xFFE2E8F0)),
      Expanded(child: _viewData.isEmpty
        ? Center(child: Text('No data found', style: GoogleFonts.outfit(color: const Color(0xFF94A3B8))))
        : ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _viewData.length,
            itemBuilder: (ctx, i) => _buildOverlayItem(_viewData[i], i),
          )),
    ]);
  }

  Widget _buildOverlayItem(MapDataModel item, int index) {
    if (_currentLevel == 'individual') return _buildIndividualCard(item, index);
    return InkWell(
      onTap: () => _drillDown(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: item.color.withOpacity(0.12), shape: BoxShape.circle),
            child: Center(child: Text('${index + 1}', style: TextStyle(color: item.color, fontWeight: FontWeight.bold, fontSize: 12))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.name, style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: item.percentage / 100,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(item.color),
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
          ])),
          const SizedBox(width: 10),
          Text('${item.percentage.toStringAsFixed(1)}%', style: GoogleFonts.outfit(color: item.color, fontWeight: FontWeight.bold, fontSize: 13)),
          const Icon(Icons.chevron_right, size: 16, color: Color(0xFF94A3B8)),
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // DATA SECTION
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildDataSection() {
    final label = _dataLevel == 'district' ? 'All Districts'
        : _dataLevel == 'block'   ? 'Blocks in $_dataDistrict'
        : _dataLevel == 'college' ? 'Colleges in $_dataBlock'
        : 'Talent in $_dataCollege';

    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('DATA INTELLIGENCE', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF94A3B8), letterSpacing: 1.5)),
            Text(label, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
          ])),
          if (_dataLevel != 'district')
            ElevatedButton.icon(
              onPressed: _dataLevel == 'individual' ? _resetToCollege
                       : _dataLevel == 'college'   ? _resetToBlock
                       : _resetToDistrict,
              icon: const Icon(Icons.arrow_back_rounded, size: 14),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                foregroundColor: const Color(0xFF1E293B),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
        ]),
      ),
      const Divider(height: 1, color: Color(0xFFF1F5F9)),
      Expanded(child: _viewData.isEmpty
        ? Center(child: Text('No talent data found for this selection', style: GoogleFonts.outfit(color: const Color(0xFF94A3B8))))
        : ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: _viewData.length,
            itemBuilder: (ctx, i) => _buildDataBarItem(_viewData[i], i),
          )),
    ]);
  }

  Widget _buildDataBarItem(MapDataModel item, int index) {
    if (_dataLevel == 'individual') return _buildIndividualCard(item, index);

    return InkWell(
      onTap: () => _drillDown(index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300 + (index * 50)),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: item.color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(item.name[0], style: TextStyle(color: item.color, fontWeight: FontWeight.bold, fontSize: 16))),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF1E293B))),
            const SizedBox(height: 8),
            Stack(children: [
              Container(height: 6, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(3))),
              FractionallySizedBox(
                widthFactor: (item.percentage / 100).clamp(0.0, 1.0),
                child: Container(height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [item.color.withOpacity(0.7), item.color]),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ]),
          ])),
          const SizedBox(width: 20),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${item.percentage.toStringAsFixed(1)}%', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: item.color, fontSize: 15)),
            Text('${item.count} Candidates', style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
          ]),
          const Padding(padding: EdgeInsets.only(left: 12), child: Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1))),
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // INDIVIDUAL CARD (shared by both map overlay and data list)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildIndividualCard(MapDataModel item, int index) {
    final d    = item.extraData ?? {};
    final name = (d['individual_name'] ?? 'Talent').toString().split(' (')[0];
    final dept = d['department'] ?? 'N/A';
    final deg  = d['degree']     ?? 'N/A';
    final cgpa = d['cgpa']?.toString() ?? 'N/A';
    final skills = (d['skills']?.toString().split(',') ?? []).take(3).join(', ');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
            child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
            Text('$deg — $dept', style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF64748B))),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text('CGPA: $cgpa', style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 12),
        Text('Key Skills: ${skills.isNotEmpty ? skills : "N/A"}', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF1E293B))),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          ElevatedButton(
            onPressed: () => _showStudentDetailsDialog(d),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              minimumSize: const Size(0, 34),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text('View Profile', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ]),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // PROFILE SECTION
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildProfileSection() {
    if (_isProfileLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
    final p = _employerProfile;
    if (p == null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.person_outline_rounded, size: 64, color: Color(0xFFCBD5E1)),
        const SizedBox(height: 16),
        Text('No profile loaded', style: GoogleFonts.outfit(fontSize: 16, color: const Color(0xFF94A3B8))),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _loadEmployerProfile,
          child: const Text('Load Profile'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
        ),
      ]));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('MY WORKSPACE', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF94A3B8), letterSpacing: 1.5)),
            Text(p['company_name'] ?? 'Organization', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
          ]),
          ElevatedButton.icon(
            onPressed: () => _showEditDialog(p),
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: const Text('Edit Profile'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ]),
        const SizedBox(height: 32),
        _detailRow(Icons.person_rounded,        'FULL NAME',           p['full_name']),
        _detailRow(Icons.email_rounded,          'EMAIL',               p['email']),
        _detailRow(Icons.phone_rounded,          'MOBILE',              p['mobile']),
        _detailRow(Icons.location_city_rounded,  'HEAD OFFICE CITY',    p['head_office_city']),
        _detailRow(Icons.business_rounded,       'INDUSTRY DOMAIN',     p['industry_domain']),
        _detailRow(Icons.apartment_rounded,      'COMPANY TYPE',        p['company_type']),
        _detailRow(Icons.badge_rounded,          'REGISTRATION NUMBER', p['reg_number']),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // DIALOGS
  // ─────────────────────────────────────────────────────────────────────────────
  void _showStudentDetailsDialog(Map<String, dynamic> d) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
          width: MediaQuery.of(context).size.width > 600 ? 600 : double.maxFinite,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(children: [
                const CircleAvatar(radius: 30, backgroundColor: Colors.white24, child: Icon(Icons.person_rounded, color: Colors.white, size: 35)),
                const SizedBox(width: 20),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d['individual_name'] ?? d['name'] ?? 'Student Profile',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(d['degree'] ?? 'Undergraduate',
                      style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14)),
                ])),
              ]),
            ),
            Flexible(child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                _detailRow(Icons.email_rounded,            'EMAIL ID',                 d['email_id'] ?? 'Not provided'),
                _detailRow(Icons.phone_rounded,            'MOBILE NUMBER',            d['mobile_number'] ?? 'Not provided'),
                _detailRow(Icons.school_rounded,           'INSTITUTION',              d['college_name']),
                _detailRow(Icons.workspace_premium_rounded,'ACADEMIC DEGREE',          d['degree']),
                _detailRow(Icons.category_rounded,         'DEPARTMENT',               d['department']),
                _detailRow(Icons.auto_awesome_rounded,     'CGPA',                     d['cgpa']),
                _detailRow(Icons.psychology_rounded,       'TECHNICAL SKILLS',         d['skills']),
                _detailRow(Icons.history_edu_rounded,      'INTERNSHIPS',              d['internships']),
                _detailRow(Icons.card_membership_rounded,  'CERTIFICATIONS',           d['certifications']),
                _detailRow(Icons.location_on_rounded,      'DISTRICT',                 d['district']),
                _detailRow(Icons.home_rounded,             'BLOCK',                    d['block']),
                _detailRow(Icons.event_available_rounded,  'YEAR OF PASSING',          d['year_of_passing']),
                _detailRow(Icons.star_rounded,             'NAAN MUDHALVAN',           d['naan_mudhalvan_course']),
                _detailRow(Icons.language_rounded,         'SWAYAM COURSE',            d['swayam_course']),
                _detailRow(Icons.sports_soccer_rounded,    'SPORTS',                   d['sports']),
                _detailRow(Icons.volunteer_activism_rounded,'EXTRA CURRICULAR',        d['extra_curricular_activities']),
              ]),
            )),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Close'),
                )),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> p) {
    final ctrls = {
      'company_name':     TextEditingController(text: p['company_name']     ?? ''),
      'full_name':        TextEditingController(text: p['full_name']        ?? ''),
      'mobile':           TextEditingController(text: p['mobile']           ?? ''),
      'head_office_city': TextEditingController(text: p['head_office_city'] ?? ''),
      'industry_domain':  TextEditingController(text: p['industry_domain']  ?? ''),
      'company_type':     TextEditingController(text: p['company_type']     ?? ''),
      'reg_number':       TextEditingController(text: p['reg_number']       ?? ''),
    };

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Edit Organization Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
        content: SizedBox(
          width: MediaQuery.of(context).size.width > 500 ? 500 : double.maxFinite,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 8),
            child: Column(mainAxisSize: MainAxisSize.min,
              children: ctrls.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextField(
                  controller: e.value,
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                  decoration: InputDecoration(
                    labelText: e.key.replaceAll('_', ' ').toUpperCase(),
                    labelStyle: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF94A3B8), letterSpacing: 1),
                    filled: true, fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366F1))),
                  ),
                ),
              )).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontWeight: FontWeight.bold))),
          ElevatedButton(
            onPressed: () {
              final updated = Map<String, dynamic>.from(p);
              ctrls.forEach((k, v) => updated[k] = v.text);
              _updateProfile(updated);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('Save Changes', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SHARED HELPERS
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _detailRow(IconData icon, String label, dynamic value) {
    if (value == null || value.toString().isEmpty ||
        value.toString().toLowerCase() == 'n/a' ||
        value.toString().toLowerCase() == 'none') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: const Color(0xFF6366F1)),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(value.toString(), style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), fontWeight: FontWeight.w500)),
        ])),
      ]),
    );
  }

  BoxDecoration _glassDeco() => BoxDecoration(
    color: Colors.white.withOpacity(0.85),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.white.withOpacity(0.5)),
    boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.06), blurRadius: 30, offset: const Offset(0, 8))],
  );

  Widget _orb(Color c, double s) => Container(
    width: s, height: s,
    decoration: BoxDecoration(shape: BoxShape.circle, color: c.withOpacity(0.07)),
  );
}
