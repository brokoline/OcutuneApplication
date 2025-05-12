import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/ocutune_button.dart';
import 'package:ocutune_light_logger/widgets/ocutune_patient_dashboard_tile.dart';

class PatientDashboardScreen extends StatelessWidget {
  const PatientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: generalBackground,
      appBar: AppBar(
        backgroundColor: generalBackground,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Ocutune',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),

                      // Logo
                      Image.asset(
                        'assets/logo/logo_ocutune.png',
                        height: 100,
                        color: Colors.white,
                      ),

                      const SizedBox(height: 32),

                      // Knapper
                      OcutunePatientDashboardTile(
                        label: 'Forbind med sensor',
                        iconAsset: 'assets/icon/BLE-sensor-ikon.png',
                        onPressed: () {
                          // TODO: Naviger til BLE
                        },
                      ),
                      OcutunePatientDashboardTile(
                        label: 'Opret en aktivitet',
                        iconAsset: 'assets/icon/activity-log-icon.png',
                        onPressed: () {
                          // TODO: Naviger til aktivitet
                        },
                      ),
                      OcutunePatientDashboardTile(
                        label: 'Kontakt din behandler',
                        iconAsset: 'assets/icon/mail-outline.png',
                        onPressed: () {
                          // TODO: Naviger til kontakt
                        },
                      ),

                      const Spacer(),

                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: OcutuneButton(
                          text: 'Log ud',
                          onPressed: () {
                            // TODO: Naviger til login
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
