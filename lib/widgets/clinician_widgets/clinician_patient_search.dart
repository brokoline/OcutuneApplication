import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../models/patient_model.dart';
import '../../../theme/colors.dart';
import '../../../screens/clinician/search/clinician_patient_detail_screen.dart';
import '../../../screens/clinician/search/clinician_search_controller.dart';

class ClinicianPatientSearch extends StatelessWidget {
  final TextEditingController controller;

  const ClinicianPatientSearch({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Consumer<ClinicianSearchController>(
      builder: (context, searchController, _) {
        if (searchController.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (searchController.error != null) {
          return Center(
            child: Text(
              'Fejl: ${searchController.error}',
              style: TextStyle(color: Colors.red, fontSize: 14.sp),
            ),
          );
        }

        if (controller.text.trim().isEmpty) {
          return const SizedBox();
        }

        final List<Patient> patients = searchController.filteredPatients;

        if (patients.isEmpty) {
          return Center(
            child: Text(
              'Ingen patienter fundet',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16.sp,
              ),
            ),
          );
        }

        return ListView.separated(
          itemCount: patients.length,
          separatorBuilder: (_, __) => SizedBox(height: 8.h),
          itemBuilder: (context, index) {
            final patient = patients[index];
            return Container(
              decoration: BoxDecoration(
                color: generalBox,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: darkGray),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 8.h,
                ),
                title: Text(
                  '${patient.firstName} ${patient.lastName}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                  ),
                ),
                subtitle: patient.cpr != null
                    ? Text(
                  patient.cpr!,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.sp,
                  ),
                )
                    : null,
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16.sp,
                  color: Colors.white70,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PatientDetailScreen(
                        patientId: patient.id,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
