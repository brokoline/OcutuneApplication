class Chronotype {
  final int id;
  final String typeKey;
  final String title;
  final String shortDescription;
  final String? longDescription;
  final String? facts;
  final String? imageUrl;
  final String? iconUrl;
  final String? language;

  Chronotype({
    required this.id,
    required this.typeKey,
    required this.title,
    required this.shortDescription,
    this.longDescription,
    this.facts,
    this.imageUrl,
    this.iconUrl,
    this.language,
  });

  factory Chronotype.fromJson(Map<String, dynamic> json) => Chronotype(
    id: json["id"],
    typeKey: json["type_key"],
    title: json["title"],
    shortDescription: json["short_description"],
    longDescription: json["long_description"],
    facts: json["facts"],
    imageUrl: json["image_url"],
    iconUrl: json["icon_url"],
    language: json["language"],
  );

  factory Chronotype.manual(String title) {
    return Chronotype(
      id: -1,
      typeKey: title.toLowerCase().replaceAll(' ', '_'),
      title: title,
      shortDescription: '',
      longDescription: '',
      facts: '',
      imageUrl: '',
      iconUrl: '',
      language: 'da',
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "type_key": typeKey,
    "title": title,
    "short_description": shortDescription,
    "long_description": longDescription,
    "facts": facts,
    "image_url": imageUrl,
    "icon_url": iconUrl,
    "language": language,
  };
}
