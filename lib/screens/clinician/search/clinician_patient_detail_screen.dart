import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../models/patient.dart';
import '../../../services/controller/clinician_dashboard_controller.dart';
import '../../../theme/colors.dart';

class PatientDetailScreen extends StatelessWidget {
  final int patientId;

  const PatientDetailScreen({Key? key, required this.patientId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ClinicianDashboardController>(context, listen: false);
    controller.loadPatientDetails(patientId); // Forvent at denne nu returnerer en Patient model

    return Scaffold(
      backgroundColor: generalBackground,
      appBar: AppBar(
        title: const Text('Patient detaljer'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<ClinicianDashboardController>(
        builder: (context, controller, _) {
          if (controller.selectedPatient == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final Patient patient = controller.selectedPatient!;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basisoplysninger
                  Text(
                    'Patientoplysninger',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _buildDetailItem('Navn', '${patient.firstName} ${patient.lastName}'),
                  if (patient.cpr != null) _buildDetailItem('CPR', patient.cpr!),
                  if (patient.simUserid != null) _buildDetailItem('OPT', patient.simUserid!),

                  SizedBox(height: 24.h),

                  // Sensor data
                  Text(
                    'Sensorer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Tilføj sensor data her baseret på patientens id eller separate kald

                  SizedBox(height: 24.h),

                  // Seneste events
                  Text(
                    'Seneste begivenheder',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Tilføj events baseret på patient ID
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorCard(String name, String status, String battery) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: generalBox,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: darkGray),
      ),
      child: Row(
        children: [
          Icon(Icons.sensors, color: Colors.white70),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: TextStyle(color: Colors.white, fontSize: 14.sp)),
              Text(status, style: TextStyle(color: Colors.green, fontSize: 12.sp)),
            ],
          ),
          Spacer(),
          Text(battery, style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
        ],
      ),
    );
  }
}
