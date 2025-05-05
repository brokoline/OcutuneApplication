import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://ocutune.ddns.net';

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
            '❌Failed to load questions. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('💥Exception caught while fetching questions: $e');
      rethrow;
    }
  }
}ßß