import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/controller/clinician_dashboard_controller.dart';
import '../../../widgets/ocutune_card.dart';
import '../../../widgets/ocutune_textfield.dart';
import '../../../widgets/ocutune_button.dart';
import '../../../services/auth_storage.dart';

class ClinicianDashboardScreen extends StatefulWidget {
  const ClinicianDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ClinicianDashboardScreen> createState() => _ClinicianDashboardScreenState();
}

class _ClinicianDashboardScreenState extends State<ClinicianDashboardScreen> {
  String clinicianName = '';
  String clinicianRole = '';
  late ClinicianDashboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ClinicianDashboardController();
    _loadClinicianData();
  }

  Future<void> _loadClinicianData() async {
    final name = await AuthStorage.getClinicianName();
    final role = await AuthStorage.getUserRole();
    setState(() {
      clinicianName = name;
      clinicianRole = role ?? 'Kliniker';
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => _controller,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('ocutune'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$clinicianRole: $clinicianName',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 20),

                OcutuneTextField(
                  label: 'Søg efter patient...',
                  controller: TextEditingController(),
                ),

                const SizedBox(height: 16),

                /// Søgeresultater
                Consumer<ClinicianDashboardController>(
                  builder: (context, controller, child) {
                    return Column(
                      children: controller.searchResults.map((patient) {
                        return Padding(
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
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 24),

                /// Notifikationer
                Text('Notifikationer', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),

                Consumer<ClinicianDashboardController>(
                  builder: (context, controller, child) {
                    return Column(
                      children: controller.notifications.map((note) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: OcutuneCard(
                            child: ListTile(
                              title: Text(note),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                // TODO: Gå til besked/aktivitet
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const Spacer(),

                /// Skriv besked knap
                OcutuneButton(
                  text: 'Skriv ny besked',
                  onPressed: () {
                    Navigator.pushNamed(context, '/clinician/new-message');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
