class UserResponse {
  final String firstName;
  final String lastName;
  final String email;
  final String gender;
  final String birthYear;
  final List<String> answers;
  final List<int> scores;
  String? chronotypeKey; // ← tilføjet

  UserResponse({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.gender,
    required this.birthYear,
    required this.answers,
    required this.scores,
    this.chronotypeKey, // ← tilføjet
  });

  Map<String, dynamic> toJson() => {
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'gender': gender,
    'birth_year': birthYear,
    'answers': answers,
    'scores': scores,
    'chronotype_key': chronotypeKey, // ← tilføjet
  };
}
