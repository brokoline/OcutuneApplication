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
  const PatientDetailScreen({Key? key, required this.patientId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PatientDetailViewModel(patientId),
      child: const PatientDetailView(),
    );
  }
}

class PatientDetailView extends StatelessWidget {
  const PatientDetailView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PatientDetailViewModel>();

    // 1) Vent kun på lysdata
    return FutureBuilder<void>(
      future: vm.lightDataFuture,
      builder: (ctx, lightSnap) {
        if (vm.isFetchingRaw) {
          return _buildLoading();
        }
        if (vm.rawFetchError != null) {
          return _buildError('Fejl ved lysdata: ${vm.rawFetchError}');
        }
        // 2) Lysdata klar → hent patient og vis resten
        return FutureBuilder<Patient>(
          future: vm.fetchPatientDetails(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return _buildLoading();
            }
            if (snap.hasError) {
              return _buildError('Fejl: ${snap.error}');
            }
            final patient = snap.data!;

            return Scaffold(
              backgroundColor: generalBackground,
              appBar: const ClinicianAppBar(showBackButton: true),
              body: SingleChildScrollView(
                padding:
                EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
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
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${patient.firstName} ${patient.lastName}',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 14.sp),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // ─── Kronotype + diagnoser ──────────────────────
                    FutureBuilder<List<Diagnosis>>(
                      future: vm.fetchDiagnoses(),
                      builder: (ctx, diagSnap) {
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
                      future: vm.fetchPatientEvents(),
                      builder: (ctx, evtSnap) {
                        if (evtSnap.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                                color: Colors.white),
                          );
                        }
                        if (evtSnap.hasError) {
                          return Text(
                            'Fejl ved aktiviteter: ${evtSnap.error}',
                            style: TextStyle(
                                color: Colors.red, fontSize: 14.sp),
                          );
                        }
                        final events = evtSnap.data!;
                        if (events.isEmpty) {
                          return Text(
                            'Ingen registrerede aktiviteter.',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 14.sp),
                          );
                        }
                        return PatientActivityCard(events: events);
                      },
                    ),
                    SizedBox(height: 16.h),

                    // ─── Lysdata (samlet oversigt) ─────────────────
                    LightSummarySection(
                      patientId: patient.id,
                      rmeqScore: vm.rmeqScore.toInt(),
                      meqScore: vm.storedMeqScore,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLoading() => const Scaffold(
    backgroundColor: generalBackground,
    appBar: ClinicianAppBar(showBackButton: true),
    body: Center(child: CircularProgressIndicator(color: Colors.white)),
  );

  Widget _buildError(String message) => Scaffold(
    backgroundColor: generalBackground,
    appBar: const ClinicianAppBar(showBackButton: true),
    body: Center(
      child: Text(message,
          style: const TextStyle(color: Colors.red, fontSize: 16)),
    ),
  );
}
