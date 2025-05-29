class ChoiceModel {
  final String id;
  final String text;
  final int score;

  ChoiceModel({required this.id, required this.text, required this.score});

  factory ChoiceModel.fromJson(Map<String, dynamic> json) {
    final text = json['choice_text'] ?? '';
    final rawId = json['id'];

    return ChoiceModel(
      id: rawId?.toString() ?? text,
      text: text,
      score: json['score'] ?? 0,
    );
  }
}