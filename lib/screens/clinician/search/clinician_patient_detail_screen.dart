import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../models/patient_model.dart';
import '../../../models/diagnose_model.dart';
import '../../../models/light_data_model.dart';
import '../../../models/patient_event_model.dart';
import '../../../theme/colors.dart';
import '../../../viewmodel/clinician/patient_detail_viewmodel.dart';
import '../../../widgets/clinician_widgets/clinician_app_bar.dart';
import '../../../widgets/clinician_widgets/clinician_search_widgets/clinician_combined_patient_card.dart';
import '../../../widgets/clinician_widgets/clinician_search_widgets/clinician_patient_activity_card.dart';
import '../../../widgets/clinician_widgets/patient_light_data_widgets/light_summary_section.dart';

class PatientDetailScreen extends StatelessWidget {
  final String patientId;

  const PatientDetailScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PatientDetailViewModel(patientId),
      child: const PatientDetailView(),
    );
  }
}

class PatientDetailView extends StatelessWidget {
  const PatientDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<PatientDetailViewModel>(context);

    return FutureBuilder<Patient>(
      future: viewModel.patientFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        if (snapshot.hasError) {
          return _buildErrorScreen(snapshot.error.toString());
        }

        return _buildPatientDetailScreen(context, snapshot.data!, viewModel);
      },
    );
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      backgroundColor: generalBackground,
      appBar: ClinicianAppBar(
        showBackButton: true,
      ),
      body: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      backgroundColor: generalBackground,
      appBar: const ClinicianAppBar(
        showBackButton: true,
      ),
      body: Center(
        child: Text(
          'Fejl: $error',
          style: TextStyle(color: Colors.red, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildPatientDetailScreen(BuildContext context, Patient patient, PatientDetailViewModel viewModel) {
    final fullName = '${patient.firstName} ${patient.lastName}';

    return Scaffold(
      backgroundColor: generalBackground,
      appBar: const ClinicianAppBar(
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Patient detaljer',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    fullName,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // Patient Info & diagnoser
            FutureBuilder<List<Diagnosis>>(
              future: viewModel.diagnosisFuture,
              builder: (context, snapshot) {
                final diagnoses = snapshot.data ?? [];

                return CombinedPatientInfoCard(
                  patient: patient,
                  diagnoses: diagnoses,
                );
              },
            ),
            SizedBox(height: 8.h),

            // Aktiviteter
            FutureBuilder<List<PatientEvent>>(
              future: viewModel.patientEventsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }
                if (snapshot.hasError) {
                  return Text(
                    'Fejl ved aktiviteter: ${snapshot.error}',
                    style: TextStyle(color: Colors.red, fontSize: 14.sp),
                  );
                }

                final events = snapshot.data ?? [];
                if (events.isEmpty) {
                  return Text(
                    'Ingen registrerede aktiviteter.',
                    style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                  );
                }

                return PatientActivityCard(events: events);
              },
            ),
            SizedBox(height: 8.h),

            // Lysdata
            FutureBuilder<List<LightData>>(
              future: viewModel.lightDataFuture,
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
                return LightSummarySection(
                  data: data,
                  totalScore: patient.totalScore ?? 0, // fallback hvis null
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
