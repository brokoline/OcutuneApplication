// lib/models/customer.dart

import 'package:flutter/foundation.dart';

/// Dart‐model, der matcher strukturen i MySQL‐tabellen “customers”:
/// id, first_name, last_name, email, password_hash, birth_year, gender,
/// chronotype, registration_date, rmeq_score, meq_score

enum Gender { male, female, other }
enum Chronotype { dove, lark, nightowl }

class Customer {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String passwordHash;
  final int birthYear;
  final Gender gender;
  final Chronotype chronotype;
  final DateTime registrationDate;
  final int rmeqScore;
  final int? meqScore; // nullable, da serveren kan returnere null

  Customer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.passwordHash,
    required this.birthYear,
    required this.gender,
    required this.chronotype,
    required this.registrationDate,
    required this.rmeqScore,
    required this.meqScore,
  });

  /// Konstruktion fra JSON (fra fx en REST‐endpoint eller lokal DB‐mappe).
  /// Forventet JSON‐struktur:
  /// {
  ///   "id": 5,
  ///   "first_name": "Jens",
  ///   "last_name": "Hansen",
  ///   "email": "jens@example.com",
  ///   "password_hash": "…",
  ///   "birth_year": 1980,
  ///   "gender": "male",
  ///   "chronotype": "lark",
  ///   "registration_date": "2025-06-04T12:34:56.000Z",
  ///   "rmeq_score": 12,
  ///   "meq_score": null   // <–– kan være null eller et heltal
  /// }
  factory Customer.fromJson(Map<String, dynamic> json) {
    // Konverter gender‐feltet til enum
    String genderStr = (json['gender'] as String? ?? '').toLowerCase();
    Gender genderEnum;
    switch (genderStr) {
      case 'male':
        genderEnum = Gender.male;
        break;
      case 'female':
        genderEnum = Gender.female;
        break;
      default:
        genderEnum = Gender.other;
    }

    // Konverter chronotype‐feltet til enum
    String chronoStr = (json['chronotype'] as String? ?? '').toLowerCase();
    Chronotype chronoEnum;
    switch (chronoStr) {
      case 'dove':
        chronoEnum = Chronotype.dove;
        break;
      case 'lark':
        chronoEnum = Chronotype.lark;
        break;
      default:
        chronoEnum = Chronotype.nightowl;
    }

    // rmeq_score forventes altid at være et heltal (eller 0 som fallback)
    final int rme = (json['rmeq_score'] as num?)?.toInt() ?? 0;

    // meq_score kan være null, så vi tjekker først
    final int? meq = (json['meq_score'] as num?)?.toInt();

    // Registrations‐dato: vi antager, at JSON‐feltet er en ISO‐8601‐streng
    DateTime regDate;
    try {
      regDate = DateTime.parse(json['registration_date'] as String);
    } catch (_) {
      // Hvis parse fejler, kan vi sætte en default‐værdi.
      regDate = DateTime.now();
    }

    return Customer(
      id: json['id'] as int,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      passwordHash: json['password_hash'] as String? ?? '',
      birthYear: (json['birth_year'] as num?)?.toInt() ?? 0,
      gender: genderEnum,
      chronotype: chronoEnum,
      registrationDate: regDate,
      rmeqScore: rme,
      meqScore: meq,
    );
  }

  /// Konverter til JSON‐map (brug fx til PUT/POST). Hvis meqScore er null,
  /// bliver der sendt `"meq_score": null`. Ellers sendes det faktiske heltal.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'password_hash': passwordHash,
      'birth_year': birthYear,
      'gender': describeEnum(gender),
      'chronotype': describeEnum(chronotype),
      'registration_date': registrationDate.toIso8601String(),
      'rmeq_score': rmeqScore,
      'meq_score': meqScore,
    };
  }
}
