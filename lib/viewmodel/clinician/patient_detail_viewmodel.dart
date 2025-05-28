import 'package:flutter/material.dart';

import '../../../models/patient_model.dart';
import '../../../models/diagnose_model.dart';
import '../../../models/light_data_model.dart';
import '../../../services/services/api_services.dart';
import '../../../models/patient_event_model.dart';


class PatientDetailViewModel extends ChangeNotifier {
  final String patientId;

  late Future<Patient> patientFuture;
  late Future<List<Diagnosis>> diagnosisFuture;
  late Future<List<LightData>> lightDataFuture;
  late Future<List<PatientEvent>> patientEventsFuture;



  PatientDetailViewModel(this.patientId) {
    fetchData();
  }

  void fetchData() {
    patientFuture = ApiService.getPatientDetails(patientId);
    diagnosisFuture = ApiService.getPatientDiagnoses(patientId)
        .then((list) => list.map((e) => Diagnosis.fromJson(e)).toList());
    lightDataFuture = ApiService.getPatientLightData(patientId)
        .then((list) => list.map((e) => LightData.fromJson(e)).toList());
    patientEventsFuture = ApiService.fetchActivities(patientId)
        .then((list) => list.map((e) => PatientEvent.fromJson(e)).toList());
  }
}