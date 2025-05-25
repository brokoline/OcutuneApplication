import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../theme/colors.dart';
import '../../../widgets/ocutune_textfield.dart';
import '../../../models/patient.dart';
import 'clinician_patient_detail_screen.dart';
import 'clinician_search_controller.dart';

class ClinicianSearchScreen extends StatefulWidget {
  const ClinicianSearchScreen({super.key});

  @override
  State<ClinicianSearchScreen> createState() => _ClinicianSearchScreenState();
}

class _ClinicianSearchScreenState extends State<ClinicianSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ClinicianSearchController()..fetchPatients(),
      child: Scaffold(
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
              Consumer<ClinicianSearchController>(
                builder: (context, controller, _) {
                  return OcutuneTextField(
                    label: 'Søg...',
                    controller: _searchController,
                    textColor: Colors.black38,
                    onChanged: (query) {
                      controller.searchPatients(query);
                    },
                  );
                },
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: Consumer<ClinicianSearchController>(
                  builder: (context, controller, _) {
                    if (controller.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    if (controller.error != null) {
                      return Center(
                        child: Text(
                          'Fejl: ${controller.error}',
                          style: TextStyle(color: Colors.red, fontSize: 14.sp),
                        ),
                      );
                    }

                    final List<Patient> patients = controller.filteredPatients;

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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
