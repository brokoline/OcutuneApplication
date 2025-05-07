import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_response.dart';

UserResponse? currentUserResponse;

/// Globalt spørgsmålstracker – skal sættes i hver spørgsmålsskærm
int currentQuestion = 0;

void updateBasicInfo({
  required String firstName,
  required String lastName,
  required String email,
  required String gender,
  required String birthYear,
}) {
  currentUserResponse = UserResponse(
    firstName: firstName,
    lastName: lastName,
    email: email,
    gender: gender,
    birthYear: birthYear,
    answers: [],
    scores: [],
    chronotypeKey: null, // ← initialiseret
  );
}

void saveAnswer(String answer, int score) {
  if (currentUserResponse == null) return;

  final a = currentUserResponse!.answers;
  final s = currentUserResponse!.scores;

  // Hvis der allerede er svaret på spørgsmålet – overskriv
  if (a.length >= currentQuestion) {
    a[currentQuestion - 1] = answer;
    s[currentQuestion - 1] = score;
  } else {
    // Ellers tilføj
    a.add(answer);
    s.add(score);
  }

  // DEBUG (kan fjernes)
  print('💾 Svar gemt: $answer (score $score) → Q$currentQuestion');
  print('📋 Alle scores: ${currentUserResponse!.scores}');
  print('📊 Total score: ${currentUserResponse!.scores.fold(0, (a, b) => a + b)}');
}

void setChronotypeKey(String key) {
  if (currentUserResponse != null) {
    currentUserResponse!.chronotypeKey = key;
    print('🔑 Kronotype sat: $key');
  }
}

Future<void> submitUserResponse() async {
  if (currentUserResponse == null) return;

  final url = Uri.parse('https://ocutune.ddns.net/users'); // ← tilpas når backend er klar

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode(currentUserResponse!.toJson()),
  );

  if (response.statusCode != 200) {
    throw Exception("Fejl ved upload: ${response.body}");
  }
}
