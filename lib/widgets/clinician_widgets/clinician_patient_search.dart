import 'package:flutter/material.dart';
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
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
            filled: true,
          ),
          onChanged: controller.searchPatient,
        ),
        SizedBox(height: 10),
        ...controller.searchResults.map((p) => ListTile(
          title: Text(p),
          onTap: () {
            // TODO: Naviger til patient-detaljer
          },
        )),
      ],
    );
  }
}
