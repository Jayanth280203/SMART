import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  // Use relative path for Web (same origin), fixed URL for mobile apps
  static String get baseUrl => kIsWeb ? '' : 'https://smart-zzhm.onrender.com';

  static Future<Map<String, dynamic>> loginEmployee(String umis, String dob) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/login/employee'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'umis': umis, 'dob': dob}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> signupEmployee(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/signup/employee'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getEmployeeDashboard(String umis) async {
    final response = await http.get(Uri.parse('$baseUrl/api/dashboard/employee/$umis'));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> analyzeResume(String resumeText, String role) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/analyze_resume'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'resume': resumeText, 'role': role}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> uploadResume(List<int> bytes, String fileName, String role) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/upload_resume'));
    request.fields['role'] = role;
    request.files.add(http.MultipartFile.fromBytes(
      'resume',
      bytes,
      filename: fileName,
    ));
    
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> scrapeJobs(String role, {
    String location = '',
    String workType = '',
    int minSalary = 0,
    int maxSalary = 0,
  }) async {
    final params = <String, String>{
      'role': role,
      if (location.isNotEmpty) 'location': location,
      if (workType.isNotEmpty) 'work_type': workType,
      if (minSalary > 0) 'min_salary': minSalary.toString(),
      if (maxSalary > 0) 'max_salary': maxSalary.toString(),
    };
    final uri = Uri.parse('$baseUrl/api/scrape_jobs').replace(queryParameters: params);
    final response = await http.get(uri);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> loginEmployer(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/login/employer'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> signupEmployer(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/signup/employer'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getEmployerAnalytics(String role, String by, {String? district, String? block, String? college}) async {
    String url = '$baseUrl/api/analytics/employer?role=$role&by=$by';
    if (district != null) url += '&district=$district';
    if (block != null) url += '&block=$block';
    if (college != null) url += '&college=$college';
    
    final response = await http.get(Uri.parse(url));
    return jsonDecode(response.body);
  }
  static Future<Map<String, dynamic>> getHierarchy() async {
    final response = await http.get(Uri.parse('$baseUrl/api/hierarchy'));
    return jsonDecode(response.body);
  }
  static Future<List<dynamic>> getRoles() async {
    final response = await http.get(Uri.parse('$baseUrl/api/roles'));
    return jsonDecode(response.body);
  }
  static Future<bool> updateEmployeeProfile(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/update/employee'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> getEmployerProfile(String companyName) async {
    final response = await http.get(Uri.parse('$baseUrl/api/profile/employer/$companyName'));
    return jsonDecode(response.body);
  }

  static Future<bool> updateEmployerProfile(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/update/employer'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> getDistrictBreakdown(String role) async {
    final uri = Uri.parse('$baseUrl/api/analytics/district_breakdown').replace(
      queryParameters: role.isNotEmpty ? {'role': role} : {},
    );
    final response = await http.get(uri);
    return jsonDecode(response.body);
  }
}
