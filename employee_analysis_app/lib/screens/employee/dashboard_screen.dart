import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'job_listings_tab.dart';
import '../role_selection_screen.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  final String umis;
  const EmployeeDashboardScreen({super.key, required this.umis});

  @override
  State<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  // For Module 2: Resume Analyzer
  String? _pickedFileName;
  Uint8List? _pickedFileBytes;
  bool _isAnalyzing = false;
  String _analysisResult = "";
  String? _uploadError;

  String _selectedScope = 'state';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final result = await ApiService.getEmployeeDashboard(widget.umis);
      setState(() {
        _data = result;
        _isLoading = false;
      });
    } catch(e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        if (file.size > 5 * 1024 * 1024) {
          setState(() => _uploadError = 'File size must be less than 5MB');
          return;
        }

        setState(() {
          _pickedFileBytes = file.bytes;
          _pickedFileName = file.name;
          _uploadError = null;
          _analysisResult = '';
        });
      }
    } catch (e) {
      setState(() => _uploadError = 'Error picking file: $e');
    }
  }

  void _analyzeResume() async {
    if (_pickedFileBytes == null || _pickedFileName == null) return;
    setState(() {
      _isAnalyzing = true;
      _uploadError = null;
    });

    try {
      final result = await ApiService.uploadResume(
        _pickedFileBytes!.toList(),
        _pickedFileName!,
        _data?['predictions']?['skill'] ?? 'Developer'
      );
      setState(() {
        _analysisResult = result['analysis'] ?? 'Failed to analyze.';
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _analysisResult = '';
        _uploadError = 'Error: $e';
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))));
    if (_data == null || _data!.containsKey('error')) return Scaffold(body: Center(child: Text('Error loading dashboard', style: GoogleFonts.outfit(color: const Color(0xFF64748B)))));

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 90,
          centerTitle: false,
          title: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                  child: Text(_data!['stats']['user_name']?[0] ?? 'S', style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('SMART', style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      Text(_data!['stats']['user_name'] ?? 'Scholar', style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 20, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                  (route) => false,
                );
              },              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.logout_rounded, color: Color(0xFF64748B), size: 20)
              ),
            ),
            const SizedBox(width: 20),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
              child: TabBar(
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: const Color(0xFF6366F1),
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(text: "Insight"),
                  Tab(text: "Analyze"),
                  Tab(text: "Jobs"),
                  Tab(text: "Profile"),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildPredictionsTab(),
            _buildResumeAnalyzerTab(),
            _buildJobListingsTab(),
            _buildProfileTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    final profile = (_data!['full_profile'] as Map?);
    if (profile == null) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(32),
            decoration: _premiumCardDecoration(),
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    bool isSmall = constraints.maxWidth < 450;
                    return isSmall 
                      ? Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                              child: Text(profile['name']?[0] ?? '?', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF6366F1))),
                            ),
                            const SizedBox(height: 16),
                            Text(profile['name'] ?? 'Student', style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                            Text('${profile['degree']} in ${profile['department']}', style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 14), textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                              child: Text('VERIFIED SCHOLAR', style: GoogleFonts.outfit(color: const Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _showEditProfileDialog(profile),
                              icon: const Icon(Icons.edit_note_rounded, size: 18),
                              label: const Text('Update'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E293B),
                                minimumSize: const Size(double.infinity, 44),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                              child: Text(profile['name']?[0] ?? '?', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF6366F1))),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(profile['name'] ?? 'Student', style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold), overflow: TextOverflow.visible),
                                  Text('${profile['degree']} in ${profile['department']}', style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 14)),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                                    child: Text('VERIFIED SCHOLAR', style: GoogleFonts.outfit(color: const Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _showEditProfileDialog(profile),
                              icon: const Icon(Icons.edit_note_rounded, size: 18),
                              label: const Text('Update'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E293B),
                                minimumSize: const Size(0, 44),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        );
                  },
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: Color(0xFFF1F5F9))),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem('CGPA', profile['cgpa'].toString(), Icons.auto_awesome),
                    _statItem('YOP', profile['year_of_passing'].toString(), Icons.event_available),
                    _statItem('LOCATION', profile['district'], Icons.location_on_outlined),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Info Sections
          _profileSection('Contact Information', [
            _infoRow(Icons.email_rounded, 'EMAIL ADDRESS', profile['email_id'] ?? 'Not provided'),
            _infoRow(Icons.phone_rounded, 'MOBILE NUMBER', profile['mobile_number'] ?? 'Not provided'),
          ]),
          const SizedBox(height: 16),
          _profileSection('Academic Background', [
            _infoRow(Icons.school_rounded, 'INSTITUTION', profile['college_name']),
            _infoRow(Icons.category_rounded, 'DEPARTMENT', profile['department']),
            _infoRow(Icons.badge_rounded, 'STUDENT ID', profile['studentID']),
          ]),
          const SizedBox(height: 16),
          _profileSection('Government Initiatives', [
            _infoRow(Icons.star_rounded, 'NAAN MUDHALVAN COURSE', profile['naan_mudhalvan_course']),
            _infoRow(Icons.language_rounded, 'SWAYAM COURSE', profile['swayam_course']),
          ]),
          const SizedBox(height: 16),
          _profileSection('Professional Credentials', [
            _infoRow(Icons.bolt_rounded, 'CORE SKILLS', profile['skills']),
            _infoRow(Icons.business_center_rounded, 'INTERNSHIPS', profile['internships']),
            _infoRow(Icons.verified_rounded, 'CERTIFICATIONS', profile['certifications']),
          ]),
          const SizedBox(height: 16),
          _profileSection('Extra Curricular Activities', [
            _infoRow(Icons.emoji_events_rounded, 'ACTIVITIES', profile['extra_curricular_activities']),
          ]),
          const SizedBox(height: 16),
          _profileSection('Sports', [
            _infoRow(Icons.sports_soccer_rounded, 'SPORTS', profile['sports']),
          ]),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _statItem(String label, String val, IconData icon) => Column(
    children: [
      Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
      const SizedBox(height: 8),
      Text(val, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
      Text(label, style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold)),
    ],
  );

  Widget _profileSection(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.all(24),
    decoration: _premiumCardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF1E293B))),
        const SizedBox(height: 20),
        ...children,
      ],
    ),
  );

  Widget _infoRow(IconData icon, String label, dynamic val) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: const Color(0xFF6366F1), size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF94A3B8), fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              Text(val.toString(), style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildPredictionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Prediction Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Text('CAREER INTELLIGENCE', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
                  ],
                ),
                const SizedBox(height: 32),
                LayoutBuilder(
                  builder: (context, constraints) {
                    bool isSmall = constraints.maxWidth < 400;
                    return isSmall 
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _predictionRing('ACADEMIC PATH', _data!['predictions']['academic']),
                            const SizedBox(height: 20),
                            _predictionRing('SKILL ALIGNMENT', _data!['predictions']['skill']),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _predictionRing('ACADEMIC PATH', _data!['predictions']['academic']),
                            const SizedBox(width: 24),
                            _predictionRing('SKILL ALIGNMENT', _data!['predictions']['skill'], CrossAxisAlignment.end),
                          ],
                        );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Pros/Cons
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _skillBox('STRENGTHS', _data!['analysis']['advantages'], const Color(0xFF10B981))),
              const SizedBox(width: 16),
              Expanded(child: _skillBox('REFINEMENTS', _data!['analysis']['disadvantages'], const Color(0xFFF59E0B))),
            ],
          ),
          const SizedBox(height: 24),
          // Filter and Charts
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Peer Comparison', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
              DropdownButton<String>(
                value: _selectedScope,
                underline: const SizedBox(),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6366F1)),
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF6366F1), fontSize: 13),
                items: ['state', 'district', 'block', 'college'].map((s) => DropdownMenuItem(value: s, child: Text('${s.toUpperCase()} WIDE'))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedScope = val);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Academic Chart
          _buildBarChart(
            'Academic Performance (CGPA)',
            'Your performance relative to $_selectedScope peers',
            (_data?['stats']?['user_cgpa'] ?? 0).toDouble(),
            (_data?['stats_advanced']?[_selectedScope]?['avg_cgpa'] ?? _data?['stats']?['avg_peer_cgpa'] ?? 7.5).toDouble(),
          ),
          const SizedBox(height: 24),
          // Skill Chart
          _buildBarChart(
            'Skill Depth Benchmark',
            'Your skill count relative to $_selectedScope peers',
            (_data?['stats']?['user_skill_score'] ?? 0).toDouble(),
            (_data?['stats_advanced']?[_selectedScope]?['avg_skill'] ?? 3.0).toDouble(),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildBarChart(String title, String subtitle, double userScore, double peerScore) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: _premiumCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(subtitle, style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 12)),
          const Expanded(child: SizedBox(height: 40)),
          Expanded(
            flex: 8,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1)),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: userScore, color: const Color(0xFF6366F1), width: 35, borderRadius: const BorderRadius.vertical(top: Radius.circular(8)))]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: peerScore, color: const Color(0xFFE2E8F0), width: 35, borderRadius: const BorderRadius.vertical(top: Radius.circular(8)))]),
                ],
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
                    final labels = ['YOUR SCORE', 'PEER AVG'];
                    return Padding(padding: const EdgeInsets.only(top: 10), child: Text(labels[v.toInt()], style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 10)));
                  })),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _predictionRing(String label, String value, [CrossAxisAlignment align = CrossAxisAlignment.start]) => Column(
    crossAxisAlignment: align,
    children: [
      Text(label, style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.bold, fontSize: 9, letterSpacing: 1)),
      const SizedBox(height: 4),
      Text(
        value, 
        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17, height: 1.2), 
        textAlign: align == CrossAxisAlignment.end ? TextAlign.right : TextAlign.left,
      ),
    ],
  );

  Widget _skillBox(String title, dynamic items, Color color) => Container(
    height: 220,
    padding: const EdgeInsets.all(20),
    decoration: _premiumCardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: color, letterSpacing: 1)),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: (items as List).map((i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.arrow_right_rounded, color: color, size: 18),
                  const SizedBox(width: 4),
                  Expanded(child: Text(i.toString(), style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF475569)))),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    ),
  );

  Widget _buildResumeAnalyzerTab() {
    bool isWide = MediaQuery.of(context).size.width > 900;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Flex(
        direction: isWide ? Axis.horizontal : Axis.vertical,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResponsiveBox(
            flex: isWide ? 1 : 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Resume Optimizer (AI)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 5),
                const Text('Scan your PDF resume for ATS alignment', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                const SizedBox(height: 30),
                Center(
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickFile,
                        icon: const Text('📄'),
                        label: const Text('Select PDF Resume'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          backgroundColor: const Color(0xFFF1F5F9),
                          foregroundColor: const Color(0xFF1E293B),
                          elevation: 0,
                          side: const BorderSide(color: Color(0xFFE2E8F0))
                        ),
                      ),
                      if (_pickedFileName != null) ...[
                        const SizedBox(height: 15),
                        Text('Selected: $_pickedFileName', style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
                        Text('${(_pickedFileBytes!.length / 1024).toStringAsFixed(1)} KB', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                      ],
                      if (_uploadError != null) ...[
                        const SizedBox(height: 10),
                        Text(_uploadError!, style: const TextStyle(color: Colors.redAccent)),
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                _isAnalyzing 
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _pickedFileBytes == null ? null : _analyzeResume,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                        ),
                        child: const Text('Analyze Resume with AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    )
              ],
            ),
          ),
          if (isWide) const SizedBox(width: 30) else const SizedBox(height: 30),
          _buildResponsiveBox(
            flex: isWide ? 1 : 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Analysis Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 20),
                if (_analysisResult.isNotEmpty) ...[
                  Center(
                    child: SizedBox(
                      height: 150,
                      width: 150,
                      child: Stack(
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 0,
                              centerSpaceRadius: 50,
                              sections: [
                                PieChartSectionData(value: _parseATSScore(_analysisResult).toDouble(), color: const Color(0xFF6366F1), radius: 12, showTitle: false),
                                PieChartSectionData(value: 100 - _parseATSScore(_analysisResult).toDouble(), color: const Color(0xFFE2E8F0), radius: 10, showTitle: false),
                              ],
                            ),
                          ),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('${_parseATSScore(_analysisResult)}%', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFF6366F1))),
                                Text('ATS SCORE', style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w900, letterSpacing: 1)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                _analysisResult.isEmpty 
                  ? const Center(child: Text('Complete an analysis to see insights', style: TextStyle(color: Color(0xFF64748B))))
                  : _buildAnalysisBoxes(_analysisResult),
              ],
            ),
          ),
        ],
      )
    );
  }

  Widget _buildAnalysisBoxes(String rawText) {
    String strong = _extractSection(rawText, 'Strong Skills');
    String lacking = _extractSection(rawText, 'Lacking Skills');
    String suggestions = _extractSection(rawText, 'Suggestions');
    
    if (strong.isEmpty && lacking.isEmpty && suggestions.isEmpty) {
      return Text(rawText.replaceAll(RegExp(r'\*\*ATS Score:.*?\*\*\n?'), ''), style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)));
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (strong.isNotEmpty) _analysisBox('💪 Strengths', strong, const Color(0xFF10B981)),
        if (lacking.isNotEmpty) _analysisBox('⚠️ Improvement Areas', lacking, const Color(0xFFF59E0B)),
        if (suggestions.isNotEmpty) _analysisBox('💡 Optimization Tips', suggestions, const Color(0xFF6366F1)),
      ],
    );
  }

  Widget _analysisBox(String title, String content, Color highlight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: highlight.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: highlight)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(color: Color(0xFF475569), fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildPredictionsView() {
    return Container(
      width: double.infinity,
      decoration: _premiumCardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text('AI CAREER FORECAST', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(30),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(child: _predictionBadgePremium('Academic Focus', _data!['predictions']['academic'], Icons.school_rounded, const Color(0xFF6366F1))),
                  const VerticalDivider(width: 40, thickness: 1, color: Color(0xFFE2E8F0)),
                  Expanded(child: _predictionBadgePremium('Skill Alignment', _data!['predictions']['skill'], Icons.workspace_premium_rounded, const Color(0xFF8B5CF6))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _predictionBadgePremium(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          value, 
          style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.w800, fontSize: 18)
        ),
      ],
    );
  }

  Widget _predictionBadge(String label, String value, {Color color = const Color(0xFF6366F1)}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      ],
    );
  }

  Widget _buildAdvantages() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Profile Advantages', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 15),
          Expanded(
            child: ListView(
              children: (_data!['analysis']['advantages'] as List).map((a) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(a.toString(), style: const TextStyle(color: Color(0xFF475569), fontSize: 13))),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisadvantages() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Skill Gaps Identified', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 15),
          Expanded(
            child: ListView(
              children: (_data!['analysis']['disadvantages'] as List).map((d) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFF59E0B), size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(d.toString(), style: const TextStyle(color: Color(0xFF475569), fontSize: 13))),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    );
  }

  BoxDecoration _premiumCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white),
      boxShadow: [
        BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.06), blurRadius: 40, offset: const Offset(0, 10))
      ],
    );
  }

  int _parseATSScore(String text) {
    try {
      final match = RegExp(r'ATS Score: (\d+)').firstMatch(text);
      if (match != null) {
        return int.parse(match.group(1)!);
      }
    } catch (e) {}
    return 0;
  }

  Widget _techBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withOpacity(0.1),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFF6366F1), fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildJobListingsTab() {
    return JobListingsTab(
      defaultRole: _data?['predictions']?['skill'] ?? 'Developer',
      academicRole: _data?['predictions']?['academic'] ?? 'Engineer',
      skillRole: _data?['predictions']?['skill'] ?? 'Developer',
    );
  }

  Widget _buildResponsiveBox({required Widget child, int flex = 0}) {
    final box = Container(
      padding: const EdgeInsets.all(32),
      decoration: _cardDecoration(),
      child: child,
    );
    return flex > 0 ? Expanded(flex: flex, child: box) : box;
  }

  String _extractSection(String text, String sectionName) {
    try {
      final pattern = RegExp('$sectionName:?\\s*\\n?((?:(?!\n\n|\n[A-Z]).|\s)*)', multiLine: true);
      final match = pattern.firstMatch(text.replaceAll('**', ''));
      return match?.group(1)?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  void _showEditProfileDialog(Map profile) {
    final fields = [
      'skills',
      'internships',
      'certifications',
      'naan_mudhalvan_course',
      'swayam_course',
      'sports',
      'extra_curricular_activities',
      'cgpa',
      'year_of_passing',
      'district',
      'block',
      'college_name',
      'degree',
      'department',
    ];
    final fieldLabels = {
      'skills':                    'Core Skills',
      'internships':               'Internships',
      'certifications':            'Certifications',
      'naan_mudhalvan_course':     'Naan Mudhalvan Course',
      'swayam_course':             'Swayam Course',
      'sports':                    'Sports',
      'extra_curricular_activities': 'Extra Curricular Activities',
      'cgpa':                      'CGPA',
      'year_of_passing':           'Year of Passing',
      'district':                  'District',
      'block':                     'Block',
      'college_name':              'College Name',
      'degree':                    'Degree',
      'department':                'Department',
    };
    final controllers = { for (var f in fields) f: TextEditingController(text: profile[f]?.toString() ?? '') };

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Update Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: controllers.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextField(
                  controller: e.value,
                  style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF1E293B)),
                  maxLines: (e.key == 'skills' || e.key == 'certifications' || e.key == 'extra_curricular_activities') ? 3 : 1,
                  decoration: InputDecoration(
                    labelText: (fieldLabels[e.key] ?? e.key.replaceAll('_', ' ')).toUpperCase(),
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              final updated = Map<String, dynamic>.from(profile as Map<String, dynamic>);
              controllers.forEach((k, v) => updated[k] = v.text);
              updated['umis'] = widget.umis;
              try {
                await ApiService.updateEmployeeProfile(updated);
                if (mounted) {
                  Navigator.pop(ctx);
                  _fetchData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated successfully!')),
                  );
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('Save Changes', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }
}
