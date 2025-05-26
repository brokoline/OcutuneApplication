class Diagnosis {
  final String diagnosis;
  final String code;

  Diagnosis({required this.diagnosis, required this.code});

  factory Diagnosis.fromJson(Map<String, dynamic> json) {
    return Diagnosis(
      diagnosis: json['diagnosis'],
      code: json['diagnosis_code'] ?? '',
    );
  }
}
