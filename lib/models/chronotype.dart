class Chronotype {
  final String typeKey;
  final String title;
  final String shortDescription;
  final String imageUrl;

  Chronotype({
    required this.typeKey,
    required this.title,
    required this.shortDescription,
    required this.imageUrl,
  });

  factory Chronotype.fromJson(Map<String, dynamic> json) {
    return Chronotype(
      typeKey: json['type_key'],
      title: json['title'],
      shortDescription: json['short_description'],
      imageUrl: json['icon_url'],
    );
  }
}
