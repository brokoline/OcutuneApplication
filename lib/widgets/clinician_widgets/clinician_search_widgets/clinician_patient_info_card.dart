import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../theme/colors.dart';
import '../../../models/patient_model.dart';

class PatientInfoCard extends StatelessWidget {
  final Patient patient;

  const PatientInfoCard({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    final fullName = '${patient.firstName} ${patient.lastName}';

    return _buildTileWrapper(
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
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(label, style: TextStyle(fontSize: 14.sp, color: Colors.white70)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1.h, thickness: 0.5, color: Colors.grey.withAlpha(100));
  }

  Widget _buildTileWrapper({
    required BuildContext context,
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16.w),
          collapsedBackgroundColor: generalBox,
          backgroundColor: generalBox,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          trailing: Icon(Icons.expand_more, color: Colors.white),
          title: Text(
            title,
            style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          children: [Padding(padding: EdgeInsets.all(16.w), child: child)],
        ),
      ),
    );
  }
}
