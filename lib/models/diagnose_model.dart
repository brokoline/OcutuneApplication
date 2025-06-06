class Diagnosis {
  final String description;
  final String icd10;

  Diagnosis({ required this.description, required this.icd10 });

  factory Diagnosis.fromJson(Map<String, dynamic> json) {
    return Diagnosis(
      description: (json['description'] as String?) ?? '',
      icd10: (json['icd10'] as String?) ?? '',
    );
  }
}
