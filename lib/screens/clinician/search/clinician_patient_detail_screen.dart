// lib/screens/clinician/search/clinician_patient_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../models/patient_model.dart';
import '../../../models/diagnose_model.dart';
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
    return ChangeNotifierProvider<PatientDetailViewModel>(
      create: (_) => PatientDetailViewModel(patientId),
      child: const PatientDetailView(),
    );
  }
}

class PatientDetailView extends StatelessWidget {
  const PatientDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<PatientDetailViewModel>(context);

    return FutureBuilder<Patient>(
      future: vm.patientFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }
        if (snapshot.hasError) {
          return _buildError(snapshot.error.toString());
        }
        final patient = snapshot.data!;

        return _buildBody(context, patient, vm);
      },
    );
  }

  Widget _buildLoading() {
    return const Scaffold(
      backgroundColor: generalBackground,
      appBar: ClinicianAppBar(showBackButton: true),
      body: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }

  Widget _buildError(String error) {
    return Scaffold(
      backgroundColor: generalBackground,
      appBar: const ClinicianAppBar(showBackButton: true),
      body: Center(
        child: Text('Fejl: $error', style: const TextStyle(color: Colors.red, fontSize: 16)),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context,
      Patient patient,
      PatientDetailViewModel vm,
      ) {
    final fullName = '${patient.firstName} ${patient.lastName}';

    return Scaffold(
      backgroundColor: generalBackground,
      appBar: const ClinicianAppBar(showBackButton: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ────────────────────────────────────
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
                    style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // ─── Diagnoser ─────────────────────────────────
            FutureBuilder<List<Diagnosis>>(
              future: vm.diagnosisFuture,
              builder: (context, diagSnap) {
                final diagnoses = diagSnap.data ?? [];
                return CombinedPatientInfoCard(
                  patient: patient,
                  diagnoses: diagnoses,
                );
              },
            ),
            SizedBox(height: 8.h),

            // ─── Aktiviteter ───────────────────────────────
            FutureBuilder<List<PatientEvent>>(
              future: vm.patientEventsFuture,
              builder: (context, evtSnap) {
                if (evtSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }
                if (evtSnap.hasError) {
                  return Text(
                    'Fejl ved aktiviteter: ${evtSnap.error}',
                    style: TextStyle(color: Colors.red, fontSize: 14.sp),
                  );
                }
                final events = evtSnap.data ?? [];
                if (events.isEmpty) {
                  return Text(
                    'Ingen registrerede aktiviteter.',
                    style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                  );
                }
                return PatientActivityCard(events: events);
              },
            ),
            SizedBox(height: 16.h),

            // ─── Lysdata (samlet oversigt) ─────────────────
            FutureBuilder<void>(
              future: vm.getLightDataFuture,
              builder: (context, lightSnap) {
                // a) If we’re still fetching raw data:
                if (vm.isFetchingRaw) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }
                // b) If there was an error fetching raw data:
                if (vm.rawFetchError != null) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Text(
                      'Fejl ved lysdata: ${vm.rawFetchError}',
                      style: TextStyle(color: Colors.red, fontSize: 14.sp),
                    ),
                  );
                }

                // c) Otherwise, we have both rawData AND ML‐processing done:
                final rmeq    = vm.rmeqScore;        // int
                final meq     = vm.storedMeqScore;   // int? (may be null)

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    // 2) LightSummarySection: grafer + ML + anbefalinger
                    LightSummarySection(
                      patientId: vm.patient!.id,
                      rmeqScore: rmeq.toInt(),
                      meqScore: meq,
                    ),

                    SizedBox(height: 16.h),
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
