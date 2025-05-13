import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://ocutune.ddns.net';

  // Hent spørgsmål (eksisterende)
  static Future<List<dynamic>> fetchQuestions() async {
    print('📡 Trying to fetch questions from $baseUrl/questions');
    try {
      final response = await http.get(Uri.parse('$baseUrl/questions'));

      print('🔁 Response status code: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            '❌ Failed to load questions. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception caught while fetching questions: $e');
      rethrow;
    }
  }

  // Henter seneste patients fornavn (og efternavn)
  static Future<Map<String, String>> fetchLatestPatientName() async {
    final url = '$baseUrl/latest-patient';
    print('📡 Fetching latest patient from $url');

    try {
      final response = await http.get(Uri.parse(url));

      print('🔁 Response: ${response.statusCode}');
      print('📦 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'first_name': data['first_name'] ?? 'Bruger',
          'last_name': data['last_name'] ?? '',
        };
      } else {
        throw Exception('❌ Failed to load patient');
      }
    } catch (e) {
      print('💥 Error: $e');
      return {
        'first_name': 'Bruger',
        'last_name': '',
      };
    }
  }
}