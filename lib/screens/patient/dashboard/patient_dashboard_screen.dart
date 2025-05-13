import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/ocutune_button.dart';
import 'package:ocutune_light_logger/widgets/ocutune_patient_dashboard_tile.dart';
import 'package:ocutune_light_logger/services/api_services.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  late Future<Map<String, String>> _nameFuture;

  @override
  void initState() {
    super.initState();
    _nameFuture = ApiService.fetchLatestPatientName();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: generalBackground,
      body: SafeArea(
        child: FutureBuilder<Map<String, String>>(
          future: _nameFuture,
          builder: (context, snapshot) {
            final firstName = snapshot.data?['first_name'] ?? 'Bruger';
            final greeting = 'Hej $firstName';

            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 48),

                            // Logo + navn
                            Center(
                              child: Column(
                                children: [
                                  Image.asset(
                                    'assets/logo/logo_ocutune.png',
                                    height: 100,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    greeting,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 48),

                            // Knapper
                            OcutunePatientDashboardTile(
                              label: 'Sensorindstillinger',
                              iconAsset: 'assets/icon/BLE-sensor-ikon.png',
                              onPressed: () {
                                Navigator.pushNamed(context, '/patient_sensor_settings');
                              },
                            ),
                            const SizedBox(height: 16),
                            OcutunePatientDashboardTile(
                              label: 'Opret en aktivitet',
                              iconAsset: 'assets/icon/activity-log-icon.png',
                              onPressed: () {
                                // Tilføj senere: Navigator.pushNamed(context, '/patient_create_activity');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('➡️ Går til: Opret aktivitet (ikke implementeret endnu)'),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            OcutunePatientDashboardTile(
                              label: 'Kontakt din behandler',
                              icon: Icons.mail_outline,
                              onPressed: () {
                                // Tilføj senere: Navigator.pushNamed(context, '/patient_contact_clinician');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('➡️ Går til: Kontakt din behandler (ikke implementeret endnu)'),
                                  ),
                                );
                              },
                            ),

                            const Spacer(),

                            // Log ud-knap
                            Center(
                              child: TextButton.icon(
                                onPressed: () {
                                  // TODO: Log ud funktionalitet
                                },
                                icon: const Icon(Icons.logout, color: Colors.white),
                                label: const Text(
                                  'Log ud',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.red.shade600,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
