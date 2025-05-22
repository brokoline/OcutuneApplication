class Patient {
  final int id;
  final String firstName;
  final String lastName;
  final String? cpr;
  final String? uuid;
  final String? simUserid;
  final String? simPassword;
  final DateTime? createdAt;

  Patient({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.cpr,
    this.uuid,
    this.simUserid,
    this.simPassword,
    this.createdAt,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      cpr: json['cpr'],
      uuid: json['uuid'],
      simUserid: json['sim_userid'],
      simPassword: json['sim_password'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'cpr': cpr,
      'uuid': uuid,
      'sim_userid': simUserid,
      'sim_password': simPassword,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  String toString() => '$firstName $lastName';
}
