import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_response.dart';

UserResponse? currentUserResponse;

/// Globalt spørgsmålstracker – skal sættes i hver spørgsmålsskærm
int currentQuestion = 0;

/// Gem de basale brugeroplysninger fra register-siden
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
    chronotypeKey: null,
  );
}

/// Gem svar og score fra spørgsmålsskærm
void saveAnswer(String answer, int score) {
  if (currentUserResponse == null) return;

  final a = currentUserResponse!.answers;
  final s = currentUserResponse!.scores;

  // Hvis allerede besvaret, overskriv
  if (a.length >= currentQuestion) {
    a[currentQuestion - 1] = answer;
    s[currentQuestion - 1] = score;
  } else {
    a.add(answer);
    s.add(score);
  }

  // Debug info
  print('💾 Svar gemt: $answer (score $score) → Q$currentQuestion');
  print('📋 Alle scores: ${currentUserResponse!.scores}');
  print('📊 Total score: ${currentUserResponse!.scores.fold(0, (a, b) => a + b)}');
}

/// Sæt kronotype efter beregning eller valg
void setChronotypeKey(String key) {
  if (currentUserResponse != null) {
    currentUserResponse!.chronotypeKey = key;
    print('🔑 Kronotype sat: $key');
  }
}

/// Upload alle brugerdata til server
Future<void> submitUserResponse() async {
  if (currentUserResponse == null) return;

  final url = Uri.parse('https://ocutune.ddns.net/customers');

  final jsonBody = json.encode(currentUserResponse!.toJson());

  print("📤 Upload data til $url:");
  print("📦 Payload: $jsonBody");

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonBody,
  );

  if (response.statusCode == 409) {
    throw Exception("Denne e-mail er allerede registreret.");
  }

  if (response.statusCode != 200) {
    throw Exception("Fejl ved upload: ${response.body}");
  }

  print("✅ Data sendt og modtaget korrekt");
}
