import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://192.168.64.6:5000';

  static Future<List<dynamic>> fetchQuestions() async {
    final response = await http.get(Uri.parse('$baseUrl/questions'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load questions');
    }
  }
}
