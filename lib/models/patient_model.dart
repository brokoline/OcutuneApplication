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

  // 👉 Erstat totalScore med to felter:
  final int? meqScore;    // 19-spørgsmålsscoren
  final int? rmeqScore;   // 5-spørgsmålsscoren

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
    this.meqScore,
    this.rmeqScore,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id:        json['id'],
      firstName: json['first_name'],
      lastName:  json['last_name'],
      cpr:       json['cpr'],
      street:    json['street'],
      zipCode:   json['zip_code'],
      city:      json['city'],
      phone:     json['phone'],
      email:     json['email'],
      uuid:      json['uuid'],
      simUserid:   json['sim_userid'],
      simPassword: json['sim_password'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,


      meqScore:  json['meq_score']  as int?,
      rmeqScore: json['rmeq_score'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id':           id,
      'first_name':   firstName,
      'last_name':    lastName,
      'cpr':          cpr,
      'street':       street,
      'zip_code':     zipCode,
      'city':         city,
      'phone':        phone,
      'email':        email,
      'uuid':         uuid,
      'sim_userid':   simUserid,
      'sim_password': simPassword,
      'created_at':   createdAt?.toIso8601String(),

      'meq_score':   meqScore,
      'rmeq_score':  rmeqScore,
    };
  }

  @override
  String toString() => '$firstName $lastName';
}
