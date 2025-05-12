import 'package:flutter/material.dart';

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
  final Color? accent; // ✅ NYT

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
    this.accent, // ✅ NYT
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
    accent: _assignAccent(json["title"]), // ✅ farve tildeles her
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

  static Color? _assignAccent(String title) {
    switch (title.toLowerCase()) {
      case 'lærke':
        return Colors.amberAccent;
      case 'due':
        return Colors.lightGreenAccent;
      case 'natugle':
        return Colors.lightBlueAccent;
      default:
        return Colors.white24;
    }
  }
}
