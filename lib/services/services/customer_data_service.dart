import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/customer_response_model.dart';
import '../auth_storage.dart';

CustomerResponse? currentCustomerResponse;

int currentQuestion = 0;

void updateBasicInfo({
  required String firstName,
  required String lastName,
  required String email,
  required String gender,
  required String birthYear,
}) {
  currentCustomerResponse = CustomerResponse(
    firstName:     firstName,
    lastName:      lastName,
    email:         email,
    gender:        gender,
    birthYear:     birthYear,
    answers:       <String>[],
    questionScores:<String,int>{},
    rmeqScore:     null,
    meqScore:      null,
    chronotype: null,
    password:      null,
  );
}

void saveAnswer(String answer, int score) {
  final resp = currentCustomerResponse;
  if (resp == null) return;
  while (resp.answers.length < currentQuestion) {
    resp.answers.add('');
  }

  resp.answers[currentQuestion - 1] = answer;

  final qs = resp.questionScores;
  final key = 'q$currentQuestion';
  qs[key] = score;

  if (resp.answers.length >= 5) {
    final sum = qs.entries
        .where((e) => int.parse(e.key.substring(1)) <= 5)
        .map((e) => e.value)
        .fold(0, (a, b) => a + b);
    currentCustomerResponse = resp.copyWith(rmeqScore: sum);
  }
}

void setChronotypeKey(String key) {
  final resp = currentCustomerResponse;
  if (resp == null) return;

  currentCustomerResponse = resp.copyWith(
    chronotype: key,
  );
}

Future<void> updateCustomerProfile(Map<String, dynamic> updatedData) async {
  final token = await AuthStorage.getToken();
  final url = Uri.parse('https://ocutune2025.ddns.net/api/customer/profile');
  final response = await http.put(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(updatedData),
  );

  if (response.statusCode != 200) {
    throw Exception('Kunne ikke opdatere profilen: ${response.body}');
  }
}

Future<void> submitCustomerResponse() async {
  final resp = currentCustomerResponse;
  if (resp == null) return;

  final registerUrl = Uri.parse('https://ocutune2025.ddns.net/api/auth/registerCustomer');
  final profileUpdateUrl = Uri.parse('https://ocutune2025.ddns.net/api/customer/profile');
  final jsonBody = json.encode(resp.toJson());

  final registerResponse = await http.post(
    registerUrl,
    headers: {'Content-Type': 'application/json'},
    body: jsonBody,
  );

  if (registerResponse.statusCode == 409) {
    final token = await AuthStorage.getToken();
    if (token == null) {
      throw Exception("Manglende token til profilopdatering.");
    }

    final updateResponse = await http.put(
      profileUpdateUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'chronotype': resp.chronotype,
        'rmeq_score': resp.rmeqScore,
        'answers': resp.answers,
        'question_scores': resp.questionScores,
      }),
    );

    if (updateResponse.statusCode != 200) {
      throw Exception("Kunne ikke opdatere brugerprofil: ${updateResponse.body}");
    }

  } else if (registerResponse.statusCode != 201) {
    throw Exception("Fejl ved registrering: ${registerResponse.body}");
  } else {

    final Map<String, dynamic> body = json.decode(registerResponse.body);
    final accessToken = body['access_token'] as String;
    final refreshToken = body['refresh_token'] as String;
    final userJson = body['user'] as Map<String, dynamic>;

    await AuthStorage.saveLogin(
      id: userJson['id'].toString(),
      role: userJson['role'] as String,
      token: accessToken,
      simUserId: refreshToken,
    );
    print('Tokens og bruger gemt: access=$accessToken');
  }
}
