import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../models/patient_model.dart';

class PatientInfoCard extends StatelessWidget {
  final Patient patient;

  const PatientInfoCard({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    final fullName = '${patient.firstName} ${patient.lastName}';

    return Column(
      children: [
        _buildTileWrapper(
          context: context,
          title: 'Patientinformation',
          child: Column(
            children: [
              _buildInfoRow('Navn', fullName),
              _buildDivider(),
              _buildInfoRow('CPR', patient.cpr ?? ''),
              if (patient.street != null && patient.street!.isNotEmpty) ...[
                _buildDivider(),
                _buildInfoRow('Adresse', patient.street!),
              ],
              if (patient.zipCode != null && patient.city != null) ...[
                _buildDivider(),
                _buildInfoRow('Postnummer & By', '${patient.zipCode} ${patient.city}'),
              ],
              if (patient.phone != null && patient.phone!.isNotEmpty)
                _buildIconRow(Icons.phone, patient.phone!),
              if (patient.email != null && patient.email!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 12.h),
                  child: _buildIconRow(Icons.email, patient.email!),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTileWrapper({required BuildContext context, required String title, required Widget child}) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white70,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8.r,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 12.h),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
        Text(value),
      ],
    );
  }

  Widget _buildIconRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: Colors.grey),
        SizedBox(width: 8.w),
        Expanded(child: Text(value)),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Divider(height: 1.h, color: Colors.grey),
    );
  }
}
