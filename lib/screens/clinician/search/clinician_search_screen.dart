import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../models/patient.dart';
import '../../../services/controller/clinician_root_controller.dart';
import '../../../theme/colors.dart';
import '../../../widgets/ocutune_textfield.dart';
import 'clinician_patient_detail_screen.dart';


class ClinicianSearchScreen extends StatelessWidget {
  const ClinicianSearchScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: generalBackground,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Søg efter patient',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 24.h),
            OcutuneTextField(
              label: 'Søg...',
              controller: TextEditingController(),
              onChanged: (query) {
                final controller = Provider.of<ClinicianDashboardController>(
                  context,
                  listen: false,
                );
                controller.searchPatient(query);
              },
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: Consumer<ClinicianDashboardController>(
                builder: (context, controller, _) {
                  if (controller.searchResults.isEmpty) {
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
                    itemCount: controller.searchResults.length,
                    separatorBuilder: (context, index) =>
                        SizedBox(height: 8.h),
                    itemBuilder: (context, index) {
                      final Patient patient = controller.searchResults[index];
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
                            controller.selectPatient(patient);
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
