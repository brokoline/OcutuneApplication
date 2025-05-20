import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/ocutune_textfield.dart';
import '../../../widgets/ocutune_card.dart';
import '../../../services/clinician_dashboard_controller.dart';

class ClinicianSearchScreen extends StatelessWidget {
  const ClinicianSearchScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ClinicianDashboardController(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Søg efter patient')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Consumer<ClinicianDashboardController>(
            builder: (context, controller, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OcutuneTextField(
                  label: 'Søg...',
                  controller: TextEditingController(),
                  onChanged: controller.searchPatient,
                ),
                const SizedBox(height: 16),
                ...controller.searchResults.map((patient) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OcutuneCard(
                    child: ListTile(
                      title: Text(patient),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // TODO: Naviger til patientdetaljer
                      },
                    ),
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
