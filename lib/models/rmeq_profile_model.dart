import 'customer_model.dart';
import 'patient_model.dart';

abstract class RmeqProfile {
  int get rmeqScore;
  String get fullName;
}

extension PatientRmeq on Patient {
  int get rmeqScore => this.rmeqScore ?? 0;
  String get fullName => '$firstName $lastName';
}

extension CustomerRmeq on Customer {
  int get rmeqScore => this.rmeqScore;
  String get fullName => '$firstName $lastName';
}
