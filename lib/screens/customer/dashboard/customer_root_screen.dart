// lib/screens/customer/dashboard/customer_root_screen.dart

import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/services/services/api_services.dart';
import 'package:ocutune_light_logger/widgets/customer_widgets/customer_app_bar.dart';
import 'package:ocutune_light_logger/widgets/customer_widgets/customer_nav_bar.dart';
import '../../../models/customer_model.dart';
import '../../../widgets/customer_widgets/light_widgets/customer_light_summary_section.dart';

class CustomerRootScreen extends StatelessWidget {
  const CustomerRootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: generalBackground,
      appBar: const CustomerAppBar(
        title: 'Kunde Lys-Dashboard',
      ),
      body: FutureBuilder<Customer>(
        future: ApiService.fetchCustomerProfile(),
        builder: (context, snapshot) {
          // 1) Loader, mens vi venter på profildata
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // 2) Hvis fejl ved hentning af profil
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Fejl ved hentning af profil:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }

          // 3) Hvis ingen data (bør ikke ske, hvis token er gyldigt)
          if (!snapshot.hasData) {
            return const Center(
              child: Text(
                'Ingen brugerdata fundet.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            );
          }

          // 4) Vi har kundens profil
          final Customer profile = snapshot.data!;
          final int rmeq       = profile.rmeqScore;
          final int meq        = profile.meqScore ?? 0;
          final String chrono  = profile.chronotype.name;
          final String name    = '${profile.firstName} ${profile.lastName}';

          // 5) Eksempel-anbefalinger (kan erstattes af dynamisk logik)
          final List<String> recommendations = [
            '08:00 – Gå en morgentur i dagslys',
            '21:00 – Undgå skærmlys før sengetid',
          ];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),

                // Vis kundens navn
                Text(
                  'Velkommen, $name',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Én samlet “summary”-sektion (anbefalinger, score og swipebar-graf)
                CustomerLightSummarySection(
                  rmeqScore:       rmeq,
                  meqScore:        meq,
                  chronotype:      chrono,
                  recommendations: recommendations,
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: CustomerNavBar(
        currentIndex: 0,
        onTap: (_) {
          // Fremtidig navigation, hvis der kommer flere faner
        },
      ),
    );
  }
}
