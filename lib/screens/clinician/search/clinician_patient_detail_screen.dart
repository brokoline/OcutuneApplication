import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/patient_model.dart';
import '../../../models/diagnose_model.dart';
import '../../../models/light_data_model.dart';
import '../../../services/services/api_services.dart';
import '../../../theme/colors.dart';
import '../../../utils/light_utils.dart';
import '../../../widgets/clinician_widgets/clinician_app_bar.dart';
import '../../../widgets/clinician_widgets/clinician_search_widgets/clinician_patient_diagnose_card.dart';
import '../../../widgets/clinician_widgets/clinician_search_widgets/clinician_patient_contact_card.dart';
import '../../../widgets/clinician_widgets/clinician_search_widgets/clinician_patient_info_card.dart';
import '../../../widgets/clinician_widgets/clinician_search_widgets/patient_data_widgets/light_score_card.dart';
import '../../../widgets/clinician_widgets/clinician_search_widgets/patient_data_widgets/light_daily_line_chart.dart';
import '../../../widgets/clinician_widgets/clinician_search_widgets/patient_data_widgets/light_weekly_bar_chart.dart';
import '../../../widgets/clinician_widgets/clinician_search_widgets/patient_data_widgets/light_latest_events_list.dart';
import '../../../widgets/clinician_widgets/clinician_search_widgets/patient_data_widgets/light_recommendations_card.dart';

class PatientDetailScreen extends StatefulWidget {
  final String patientId;

  const PatientDetailScreen({super.key, required this.patientId});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  late Future<Patient> _patientFuture;
  late Future<List<Diagnosis>> _diagnosisFuture;
  late Future<List<LightData>> _lightDataFuture;

  @override
  void initState() {
    super.initState();
    _patientFuture = ApiService.getPatientDetails(widget.patientId);
    _diagnosisFuture = ApiService.getPatientDiagnoses(widget.patientId)
        .then((list) => list.map((e) => Diagnosis.fromJson(e)).toList());
    _lightDataFuture = ApiService.getPatientLightData(widget.patientId)
        .then((list) => list.map((e) => LightData.fromJson(e)).toList());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Patient>(
      future: _patientFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        if (snapshot.hasError) {
          return _buildErrorScreen(snapshot.error.toString());
        }

        return _buildPatientDetailScreen(snapshot.data!);
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: generalBackground,
      appBar: const ClinicianAppBar(
        title: 'Patient detaljer',
        showLogout: false,
        showBackButton: true,
      ),
      body: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      backgroundColor: generalBackground,
      appBar: const ClinicianAppBar(
        title: 'Patient detaljer',
        showLogout: false,
        showBackButton: true,
      ),
      body: Center(
        child: Text(
          'Fejl: $error',
          style: TextStyle(color: Colors.red, fontSize: 16.sp),
        ),
      ),
    );
  }

  Widget _buildPatientDetailScreen(Patient patient) {
    final fullName = '${patient.firstName} ${patient.lastName}';

    return Scaffold(
      backgroundColor: generalBackground,
      appBar: ClinicianAppBar(
        title: 'Patient detaljer',
        subtitle: fullName,
        showLogout: false,
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PatientInfoCard(patient: patient),
            SizedBox(height: 8.h),
            PatientContactCard(patient: patient),
            SizedBox(height: 8.h),

            // Diagnoser
            FutureBuilder<List<Diagnosis>>(
              future: _diagnosisFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }
                if (snapshot.hasError) {
                  return Text(
                    'Fejl ved hentning af diagnoser: ${snapshot.error}',
                    style: TextStyle(color: Colors.red, fontSize: 14.sp),
                  );
                }
                return DiagnosisCard(diagnoses: snapshot.data ?? []);
              },
            ),
            SizedBox(height: 8.h),

            // Lysdata – visuelle widgets
            FutureBuilder<List<LightData>>(
              future: _lightDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }
                if (snapshot.hasError) {
                  return Text(
                    'Fejl ved lysdata: ${snapshot.error}',
                    style: TextStyle(color: Colors.red, fontSize: 14.sp),
                  );
                }

                final data = snapshot.data ?? [];
                final score = data.isEmpty
                    ? 0.0
                    : data.map((d) => d.exposureScore).reduce((a, b) => a + b) / data.length;

                final weekMap = groupLuxByDay(data);
                final recs = generateRecommendations(data);

                return Column(
                  children: [
                    LightScoreCard(score: score),
                    SizedBox(height: 8.h),
                    LightDailyLineChart(lightData: data),
                    SizedBox(height: 8.h),
                    LightWeeklyBarChart(luxPerDay: weekMap),
                    SizedBox(height: 8.h),
                    LightLatestEventsList(lightData: data),
                    SizedBox(height: 8.h),
                    LightRecommendationsCard(recommendations: recs),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
