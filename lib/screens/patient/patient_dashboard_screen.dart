import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/services/auth_storage.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/ocutune_patient_dashboard_tile.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  late Future<String> _nameFuture;

  @override
  void initState() {
    super.initState();
    _nameFuture = AuthStorage.getName().then((name) {
      if (name.trim().isEmpty) return 'Bruger';
      return name.split(' ').first; // Kun fornavn
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: generalBackground,
      body: SafeArea(
        child: FutureBuilder<String>(
          future: _nameFuture,
          builder: (context, snapshot) {
            final greeting = 'Hej ${snapshot.data ?? 'Bruger'}';

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
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    greeting,
                                    style: const TextStyle(
                                      color: Colors.white70,
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
                              label: 'Registrér en aktivitet',
                              iconAsset: 'assets/icon/activity-log-icon.png',
                              onPressed: () {
                                Navigator.pushNamed(context, '/patient/activities');
                              },
                            ),
                            const SizedBox(height: 16),
                            OcutunePatientDashboardTile(
                              label: 'Kontakt din behandler',
                              iconAsset: 'assets/icon/mail-outline.png',
                              onPressed: () {
                                Navigator.pushNamed(context, '/patient/inbox');
                              },
                            ),

                            const Spacer(),

                            // Ny log ud knap
                            Center(
                              child: SizedBox(
                                width: 100,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await AuthStorage.logout();
                                    if (!context.mounted) return;
                                    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                                  },
                                  icon: const Icon(Icons.logout),
                                  label: const Text('Log ud'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    foregroundColor: Colors.white70,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
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
