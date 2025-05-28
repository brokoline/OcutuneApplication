class Patient {
  final String id;
  final String firstName;
  final String lastName;
  final String? cpr;
  final String? street;
  final String? zipCode;
  final String? city;
  final String? phone;
  final String? email;
  final String? uuid;
  final String? simUserid;
  final String? simPassword;
  final DateTime? createdAt;
  final int? totalScore; // 👈 tilføjet her

  Patient({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.cpr,
    this.street,
    this.zipCode,
    this.city,
    this.phone,
    this.email,
    this.uuid,
    this.simUserid,
    this.simPassword,
    this.createdAt,
    this.totalScore,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      cpr: json['cpr'],
      street: json['street'],
      zipCode: json['zip_code'],
      city: json['city'],
      phone: json['phone'],
      email: json['email'],
      uuid: json['uuid'],
      simUserid: json['sim_userid'],
      simPassword: json['sim_password'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      totalScore: json['total_score'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'cpr': cpr,
      'street': street,
      'zip_code': zipCode,
      'city': city,
      'phone': phone,
      'email': email,
      'uuid': uuid,
      'sim_userid': simUserid,
      'sim_password': simPassword,
      'created_at': createdAt?.toIso8601String(),
      'total_score': totalScore,
    };
  }

  @override
  String toString() => '$firstName $lastName';
}
