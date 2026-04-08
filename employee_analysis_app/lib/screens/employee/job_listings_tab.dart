import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

// All major Indian cities for autocomplete
const List<String> kIndianCities = [
  'Agra', 'Ahmedabad', 'Aizawl', 'Ajmer', 'Akola', 'Aligarh', 'Alwar',
  'Amravati', 'Amritsar', 'Aurangabad', 'Bareilly', 'Belgaum', 'Bhavnagar',
  'Bhilai', 'Bhopal', 'Bhubaneswar', 'Bikaner', 'Bokaro', 'Chandigarh',
  'Chennai', 'Coimbatore', 'Cuttack', 'Dehradun', 'Delhi', 'Delhi NCR',
  'Dhanbad', 'Durgapur', 'Erode', 'Faridabad', 'Firozabad', 'Ghaziabad',
  'Gorakhpur', 'Guntur', 'Gurgaon', 'Guwahati', 'Gwalior', 'Hubli',
  'Hyderabad', 'Imphal', 'Indore', 'Itanagar', 'Jabalpur', 'Jaipur',
  'Jalandhar', 'Jammu', 'Jamshedpur', 'Jodhpur', 'Kakinada', 'Kalyan',
  'Kanpur', 'Kochi', 'Kohima', 'Kolkata', 'Kota', 'Kozhikode', 'Lucknow',
  'Ludhiana', 'Madurai', 'Mangalore', 'Meerut', 'Moradabad', 'Mumbai',
  'Mysore', 'Nagpur', 'Nashik', 'Navi Mumbai', 'Nellore', 'Noida',
  'Panaji', 'Patiala', 'Patna', 'Pune', 'Raipur', 'Rajkot', 'Ranchi',
  'Salem', 'Shillong', 'Shimla', 'Siliguri', 'Srinagar', 'Surat',
  'Thane', 'Thanjavur', 'Thiruvananthapuram', 'Tiruchirappalli',
  'Tirunelveli', 'Tirupati', 'Tiruppur', 'Tumkur', 'Udaipur', 'Vadodara',
  'Varanasi', 'Vasai', 'Vijayawada', 'Visakhapatnam', 'Warangal',
  'Bengaluru', 'Bangalore', 'Remote India',
];

const List<String> kCtcRanges = [
  'Any',
  'Below ₹3L',
  '₹3L – ₹6L',
  '₹6L – ₹10L',
  '₹10L – ₹20L',
  'Above ₹20L',
];

class JobListingsTab extends StatefulWidget {
  final String defaultRole;
  final String academicRole;
  final String skillRole;

  const JobListingsTab({
    super.key,
    required this.defaultRole,
    required this.academicRole,
    required this.skillRole,
  });

  @override
  State<JobListingsTab> createState() => _JobListingsTabState();
}

class _JobListingsTabState extends State<JobListingsTab> {
  late TextEditingController _roleController;
  final TextEditingController _locationController = TextEditingController();
  final FocusNode _locationFocus = FocusNode();

  String _selectedWorkType = '';      // '', 'onsite', 'remote', 'hybrid'
  String _selectedCtc = 'Any';
  String _selectedLocation = '';

  List<String> _locationSuggestions = [];
  bool _showSuggestions = false;

  List<dynamic> _jobs = [];
  bool _isLoading = false;
  String _source = '';

  @override
  void initState() {
    super.initState();
    _roleController = TextEditingController(text: widget.defaultRole);
    // REMOVED: Aggressive focus listener that hides suggestions before they can be clicked
    // Moved hide logic to _selectLocation and focus loss handling inside the UI builder

    // Auto-search on load
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchJobs());
  }

  @override
  void dispose() {
    _roleController.dispose();
    _locationController.dispose();
    _locationFocus.dispose();
    super.dispose();
  }

  // Added a small delay to ensure onTap fires before suggestions disappear
  void _onLocationFocusChange(bool hasFocus) {
    if (!hasFocus) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) setState(() => _showSuggestions = false);
      });
    } else if (_locationSuggestions.isNotEmpty) {
      setState(() => _showSuggestions = true);
    }
  }

  void _onLocationChanged(String val) {
    final suggestions = val.isEmpty
        ? <String>[]
        : kIndianCities
            .where((c) => c.toLowerCase().startsWith(val.toLowerCase()))
            .take(8)
            .toList();
    setState(() {
      _locationSuggestions = suggestions;
      _showSuggestions = suggestions.isNotEmpty;
    });
  }

  void _selectLocation(String city) {
    _locationController.text = city;
    setState(() {
      _selectedLocation = city;
      _showSuggestions = false;
    });
    _locationFocus.unfocus();
  }

  (int, int) _ctcToSalary(String ctc) {
    switch (ctc) {
      case 'Below ₹3L': return (0, 300000);
      case '₹3L – ₹6L': return (300000, 600000);
      case '₹6L – ₹10L': return (600000, 1000000);
      case '₹10L – ₹20L': return (1000000, 2000000);
      case 'Above ₹20L': return (2000000, 0);
      default: return (0, 0);
    }
  }

  void _fetchJobs({String? customRole}) async {
    final role = customRole ?? _roleController.text.trim();
    if (role.isEmpty) return;
    
    if (customRole != null) {
      _roleController.text = customRole;
    }
    
    setState(() { _isLoading = true; _jobs = []; });

    final (min, max) = _ctcToSalary(_selectedCtc);
    try {
      final result = await ApiService.scrapeJobs(
        role,
        location: _selectedLocation,
        workType: _selectedWorkType,
        minSalary: min,
        maxSalary: max,
      );
      if (mounted) {
        setState(() {
          _jobs = result['jobs'] ?? [];
          _source = result['source'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _launchJobUrl(String url) async {
    final uri = Uri.parse(url == '#' || url.isEmpty ? 'https://www.google.com/search?q=jobs' : url);
    try {
      // Direct launch for web compatibility
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch $url');
    }
  }

  Color _workTypeColor(String wt) {
    switch (wt.toLowerCase()) {
      case 'remote': return const Color(0xFF00C853);
      case 'hybrid': return const Color(0xFFFF9800);
      default: return const Color(0xFF6366F1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          _buildSearchBar(),
          _buildFilters(),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Expanded(child: _buildJobList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    bool isWide = MediaQuery.of(context).size.width > 900;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommended for you',
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold, 
              color: const Color(0xFF1E293B)
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _roleChip(widget.academicRole, label: 'Academic Match'),
              const SizedBox(width: 8),
              _roleChip(widget.skillRole, label: 'Skill Match'),
            ],
          ),
          const SizedBox(height: 20),
          if (isWide)
            Row(
              children: [
                Expanded(flex: 3, child: _searchBox()),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: _locationBox()),
                const SizedBox(width: 12),
                _searchButton(),
              ],
            )
          else
            Column(
              children: [
                _searchBox(),
                const SizedBox(height: 10),
                _locationBox(),
                const SizedBox(height: 10),
                _searchButton(isExpanded: true),
              ],
            ),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return TextField(
      controller: _roleController,
      style: const TextStyle(color: Color(0xFF1E293B), fontSize: 15),
      onSubmitted: (_) => _fetchJobs(),
      decoration: InputDecoration(
        hintText: 'Job title or role...',
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear, size: 20, color: Color(0xFF94A3B8)),
          onPressed: () { _roleController.clear(); setState(() {}); },
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _locationBox() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Focus(
          onFocusChange: _onLocationFocusChange,
          child: TextField(
            controller: _locationController,
            focusNode: _locationFocus,
            style: const TextStyle(color: Color(0xFF1E293B), fontSize: 15),
            onChanged: _onLocationChanged,
            onSubmitted: (_) { setState(() => _showSuggestions = false); _fetchJobs(); },
            decoration: InputDecoration(
              hintText: 'City (e.g. Chennai)',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF64748B)),
              suffixIcon: _locationController.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear, size: 20), onPressed: () { _locationController.clear(); setState(() { _selectedLocation = ''; _showSuggestions = false; }); })
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        if (_showSuggestions)
          Positioned(
            top: 58, left: 0, right: 0,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              elevation: 4,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  padding: EdgeInsets.zero, shrinkWrap: true,
                  itemCount: _locationSuggestions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (ctx, i) => ListTile(
                    dense: true, 
                    leading: const Icon(Icons.location_city, size: 18, color: Color(0xFF64748B)),
                    title: Text(_locationSuggestions[i], style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14)),
                    onTap: () => _selectLocation(_locationSuggestions[i]),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _searchButton({bool isExpanded = false}) {
    return ElevatedButton(
      onPressed: _fetchJobs,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        minimumSize: Size(isExpanded ? double.infinity : 120, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: const Text('Search Jobs', style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _roleChip(String role, {required String label}) {
    final isActive = _roleController.text.toLowerCase() == role.toLowerCase();
    return GestureDetector(
      onTap: () => _fetchJobs(customRole: role),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF6366F1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0)),
          boxShadow: isActive ? [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : const Color(0xFF64748B)
              ),
            ),
            const SizedBox(width: 4),
            Text(
              role.length > 20 ? '${role.substring(0, 18)}..' : role,
              style: TextStyle(
                fontSize: 12, 
                color: isActive ? Colors.white.withOpacity(0.9) : const Color(0xFF1E293B)
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(Icons.filter_list, size: 18, color: Color(0xFF64748B)),
            const SizedBox(width: 12),
            // Work type choices
            ...[('All', ''), ('Onsite', 'onsite'), ('Remote', 'remote'), ('Hybrid', 'hybrid')]
                .map((e) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(e.$1, style: TextStyle(fontSize: 12, color: _selectedWorkType == e.$2 ? Colors.white : const Color(0xFF1E293B))),
                    selected: _selectedWorkType == e.$2,
                    selectedColor: const Color(0xFF6366F1),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: _selectedWorkType == e.$2 ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0)),
                    showCheckmark: false,
                    onSelected: (_) {
                      setState(() => _selectedWorkType = e.$2);
                      _fetchJobs();
                    },
                  ),
                )),
            const VerticalDivider(width: 16),
            const Text('CTC Range:', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _selectedCtc,
              style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13),
              dropdownColor: Colors.white,
              underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down, size: 18),
              items: kCtcRanges.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) {
                if (v != null) { setState(() => _selectedCtc = v); _fetchJobs(); }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF0F62FE)),
            SizedBox(height: 20),
            Text('Hunting for opportunities...', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
    if (_jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_outlined, size: 80, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 20),
            const Text('No matches found yet', style: TextStyle(color: Color(0xFF1E293B), fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Try adjusting your filters or location', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _fetchJobs,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
              child: const Text('Search Again'),
            )
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      itemCount: _jobs.length,
      itemBuilder: (ctx, i) => _buildJobCard(_jobs[i]),
    );
  }

  Widget _buildJobCard(Map<dynamic, dynamic> job) {
    final title = job['title'] ?? 'Job Opening';
    final company = job['company'] ?? '';
    final location = job['location'] ?? '';
    final workType = job['work_type'] ?? 'Onsite';
    final salary = job['salary'] ?? '';
    final source = job['source'] ?? '';
    final description = job['description'] ?? '';
    final datePosted = job['date_posted'] ?? '';
    final link = job['link'] ?? '#';
    final wtColor = _workTypeColor(workType);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final uri = Uri.parse(link == '#' ? 'https://www.linkedin.com/jobs/' : link);
          if (await canLaunchUrl(uri)) launchUrl(uri);
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        company.isNotEmpty ? company[0].toUpperCase() : 'J',
                        style: const TextStyle(color: Color(0xFF0F62FE), fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(color: Color(0xFF1E293B), fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(company, style: const TextStyle(color: Color(0xFF0F62FE), fontSize: 15, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  if (source.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                      child: Text(source, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _infoTile(Icons.location_on_outlined, location),
                  _infoTile(Icons.work_outline, workType, color: wtColor),
                  if (salary.isNotEmpty) _infoTile(Icons.payments_outlined, salary),
                  if (datePosted.isNotEmpty) _infoTile(Icons.access_time, datePosted),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF475569), fontSize: 13, height: 1.5),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {},
                    child: const Text('Save Job', style: TextStyle(color: Color(0xFF64748B))),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _launchJobUrl(link),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: const Color(0xFF6366F1).withOpacity(0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Apply Now', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String text, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color ?? const Color(0xFF64748B)),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color ?? const Color(0xFF64748B), fontSize: 13)),
      ],
    );
  }
}
