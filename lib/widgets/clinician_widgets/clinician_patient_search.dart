import 'package:flutter/material.dart';
import '../../screens/clinician/search/clinician_patient_detail_screen.dart';
import '../../services/controller/clinician_dashboard_controller.dart';
import 'package:provider/provider.dart';

class ClinicianPatientSearch extends StatelessWidget {
  const ClinicianPatientSearch({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ClinicianDashboardController>(context);

    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Søg efter en patient',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            filled: true,
          ),
          onChanged: controller.searchPatient,
        ),
        const SizedBox(height: 10),
        ...controller.searchResults.map((patient) => ListTile(
          title: Text('${patient.firstName} ${patient.lastName}'),
          subtitle: patient.cpr != null ? Text('CPR: ${patient.cpr}') : null,
          trailing: const Icon(Icons.arrow_forward),
          onTap: () {
            // Naviger til patientdetaljer
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PatientDetailScreen(patientId: patient.id),
              ),
            );
          },
        )),
      ],
    );
  }
}