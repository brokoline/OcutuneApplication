class ChoiceModel {
  final String id;
  final String text;
  final int score;

  ChoiceModel({required this.id, required this.text, required this.score});

  factory ChoiceModel.fromJson(Map<String, dynamic> json) {
    return ChoiceModel(
      id: json['id'].toString(),
      text: json['choice_text'],
      score: json['score'] ?? 0,
    );
  }
}
