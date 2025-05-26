import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/patient.dart';
import '../../../services/services/api_services.dart';
import '../../../theme/colors.dart';
import '../../../widgets/clinician_widgets/clinician_app_bar.dart';

class PatientDetailScreen extends StatelessWidget {
  final String patientId;

  const PatientDetailScreen({Key? key, required this.patientId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Patient>(
      future: ApiService.getPatientDetails(patientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
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

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: generalBackground,
            appBar: const ClinicianAppBar(
              title: 'Patient detaljer',
              showLogout: false,
              showBackButton: true,
            ),
            body: Center(
              child: Text(
                'Fejl: ${snapshot.error}',
                style: TextStyle(color: Colors.red, fontSize: 16.sp),
              ),
            ),
          );
        }

        final patient = snapshot.data!;
        final fullName = '${patient.firstName} ${patient.lastName}';

        return Scaffold(
          backgroundColor: generalBackground,
          appBar: ClinicianAppBar(
            title: 'Detaljer: $fullName',
            showLogout: false,
            showBackButton: true,
          ),
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildField('Navn', fullName),
                _buildField('CPR', patient.cpr),
                _buildField('Adresse', patient.street),
                _buildField('Postnummer', patient.zipCode),
                _buildField('By', patient.city),
                _buildField('Telefon', patient.phone),
                _buildField('Email', patient.email),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildField(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox();
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
