import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class ApiService {
  ApiService({String? baseUrl})
      : baseUrl = _normalizeBaseUrl(
          baseUrl ??
              const String.fromEnvironment(
                'API_BASE_URL',
                defaultValue: 'http://localhost:8000/api',
              ),
        );

  final String baseUrl;

  static String _normalizeBaseUrl(String raw) {
    var url = raw.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  Future<List<Member>> fetchMembers() async {
    final data = await _get('/members');
    return (data as List<dynamic>)
        .map((e) => Member.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Meal>> fetchMeals() async {
    final data = await _get('/meals');
    return (data as List<dynamic>)
        .map((e) => Meal.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createMember(String name) async {
    await _post('/members', {'name': name.trim()}, expectedStatus: 201);
  }

  Future<void> createMeal({
    required String date,
    required String kind,
    required List<String> participants,
  }) async {
    await _post(
      '/meals',
      {
        'date': date,
        'kind': kind,
        'participants': participants,
      },
      expectedStatus: 201,
    );
  }

  Future<DecideDishwasherResult> decideDishwasher({
    required String date,
    required String kind,
    required List<String> participants,
    bool explain = true,
  }) async {
    final data = await _post(
      '/meals/decide-dishwasher',
      {
        'date': date,
        'kind': kind,
        'participants': participants,
        'explain': explain,
      },
      expectedStatus: 200,
    );
    return DecideDishwasherResult.fromJson(data as Map<String, dynamic>);
  }

  Future<dynamic> _get(String path) async {
    final response = await http.get(Uri.parse('$baseUrl$path'));
    return _decodeOrThrow(response, expectedStatus: 200);
  }

  Future<dynamic> _post(String path, Map<String, dynamic> payload, {required int expectedStatus}) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    return _decodeOrThrow(response, expectedStatus: expectedStatus);
  }

  dynamic _decodeOrThrow(http.Response response, {required int expectedStatus}) {
    if (response.statusCode != expectedStatus) {
      throw Exception('API error ${response.statusCode}: ${response.body}');
    }
    if (response.body.isEmpty) {
      return null;
    }
    return jsonDecode(response.body);
  }
}
