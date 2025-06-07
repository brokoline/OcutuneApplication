// lib/models/customer.dart

import 'package:flutter/foundation.dart';

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
  final int? meqScore;

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


  factory Customer.fromJson(Map<String, dynamic> json) {
    // ─── Parse køn som enum ──────────────────────────────────────────
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


    final int rme = (json['rmeq_score'] as num?)?.toInt() ?? 0;
    final int? meq = (json['meq_score'] as num?)?.toInt();

    DateTime regDate;
    try {
      regDate = DateTime.parse(json['registration_date'] as String);
    } catch (_) {
      regDate = DateTime.now();
    }

    return Customer(
      id: (json['id'] as num).toInt(),
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

   Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'password_hash': passwordHash,
      'birth_year': birthYear,
      'gender': gender,
      'chronotype': chronotype,
      'registration_date': registrationDate.toIso8601String(),
      'rmeq_score': rmeqScore,
      'meq_score': meqScore,
    };
  }
}
