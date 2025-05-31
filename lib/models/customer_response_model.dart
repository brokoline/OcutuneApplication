class CustomerResponse {
  final String firstName;
  final String lastName;
  final String email;
  final String gender;
  final String birthYear;

  /// Liste med alle svar-tekster (“q1”, “q2” …)
  final List<String> answers;

  /// Hvert enkelt svar-score som questionId → score
  final Map<String, int> questionScores;

  /// Kort version (5 spørgsmål)
  final int? rmeqScore;

  /// Lang version (19 spørgsmål)
  final int? meqScore;

  /// Kronotype-nøgle, når kunden vælger kronotype / testen er færdig
  final String? chronotypeKey;

  /// Indregistreret kodeord
  final String? password;

  CustomerResponse({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.gender,
    required this.birthYear,
    required this.answers,
    required this.questionScores,
    this.rmeqScore,
    this.meqScore,
    this.chronotypeKey,
    this.password,
  });

  factory CustomerResponse.fromJson(Map<String, dynamic> json) {
    return CustomerResponse(
      firstName:     json['first_name']        as String,
      lastName:      json['last_name']         as String,
      email:         json['email']             as String,
      gender:        json['gender']            as String,
      birthYear:     json['birth_year']        as String,
      answers:       List<String>.from(json['answers']          as List<dynamic>),
      questionScores:Map<String, int>.from(json['question_scores'] as Map),
      rmeqScore:     (json['rmeq_score']       as num?)?.toInt(),
      meqScore:      (json['meq_score']        as num?)?.toInt(),
      chronotypeKey: json['chronotype_key']    as String?,
      password:      json['password']          as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'first_name':      firstName,
    'last_name':       lastName,
    'email':           email,
    'password':        password,
    'gender':          gender,
    'birth_year':      birthYear,
    'answers':         answers,
    'question_scores': questionScores,
    'rmeq_score':      rmeqScore,
    'meq_score':       meqScore,
    'chronotype_key':  chronotypeKey,
  };

  CustomerResponse copyWith({
    String? gender,
    String? birthYear,
    List<String>? answers,
    Map<String, int>? questionScores,
    int? rmeqScore,
    int? meqScore,
    String? chronotypeKey,
    String? password,
  }) {
    return CustomerResponse(
      firstName:     firstName,
      lastName:      lastName,
      email:         email,
      gender:        gender        ?? this.gender,
      birthYear:     birthYear     ?? this.birthYear,
      answers:       answers       ?? this.answers,
      questionScores:questionScores?? this.questionScores,
      rmeqScore:     rmeqScore     ?? this.rmeqScore,
      meqScore:      meqScore      ?? this.meqScore,
      chronotypeKey: chronotypeKey ?? this.chronotypeKey,
      password:      password      ?? this.password,
    );
  }
}
