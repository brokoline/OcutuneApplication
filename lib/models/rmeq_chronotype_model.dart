class ChronotypeModel {
  final int id;
  final String typeKey;
  final String title;
  final String shortDescription;
  final String? longDescription;
  final String? facts;
  final String? imageUrl;
  final String? iconUrl;
  final String? language;

  ChronotypeModel({
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

  factory ChronotypeModel.fromJson(Map<String, dynamic> json) => ChronotypeModel(
    id: json["id"] as int,
    typeKey: json["type_key"] as String,
    title: json["title"] as String,
    shortDescription: json["short_description"] as String,
    longDescription: json["long_description"] as String?,
    facts: json["facts"] as String?,
    imageUrl: json["image_url"] as String?,
    iconUrl: json["icon_url"] as String?,
    language: json["language"] as String?,
  );

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

   String get fullImageUrl {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return "";
    }

    if (imageUrl!.startsWith('http')) {
      return imageUrl!;
    }

    return "https://ocutune2025.ddns.net/images/$imageUrl";
  }

  String get fullIconUrl {
    if (iconUrl == null || iconUrl!.isEmpty) {
      return "";
    }
    if (iconUrl!.startsWith('http')) {
      return iconUrl!;
    }
    return "https://ocutune2025.ddns.net/images/$iconUrl";
  }
}
