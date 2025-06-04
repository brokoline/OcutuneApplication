// lib/screens/customer/dashboard/customer_root_screen.dart

import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/theme/colors.dart';

// ─── Customer‐skalagswidgets ────────────────────────────────────────────────
import '../../../widgets/customer_widgets/customer_app_bar.dart';
import '../../../widgets/customer_widgets/customer_nav_bar.dart';

// ─── Patient‐widgets ───────────────────────────────────────────────────────
import '../../../widgets/clinician_widgets/patient_light_data_widgets/light_score_card.dart';
import '../../../widgets/clinician_widgets/patient_light_data_widgets/light_recommendations_card.dart';
import '../../../widgets/clinician_widgets/patient_light_data_widgets/light_slide_bar_chart.dart';
import '../../../widgets/clinician_widgets/patient_light_data_widgets/light_summary_section.dart';
import '../../../widgets/clinician_widgets/patient_light_data_widgets/light_latest_events_list.dart';

class CustomerRootScreen extends StatelessWidget {
  const CustomerRootScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: generalBackground,
      appBar: const CustomerAppBar(
        title: 'Kunde Lys-Dashboard',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),

            // 1) Lys-Score Kort
            const LightScoreCard(
              rmeqScore: 0,
              meqScore: 0,
            ),
            const SizedBox(height: 20),

            // 2) Lys-Anbefalinger Kort
            const LightRecommendationsCard(
              recommendations: [
                '08:00 – Gå en morgentur i dagslys',
                '21:00 – Undgå skærmlys før sengetid',
              ],
            ),
            const SizedBox(height: 20),

            // 3) Lys-Eksponering: Slide-graf
            const Text(
              'Lys-eksponering',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const LightSlideBarChart(
              patientId: 'P3',
              rmeqScore: 0,
            ),
            const SizedBox(height: 30),

            // 4) Sammenfatnings‐Sektion
            const Text(
              'Sammenfatning',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const LightSummarySection(
              patientId: 'P3',
              rmeqScore: 0,
              meqScore: 0,
            ),
            const SizedBox(height: 30),

            // 5) Seneste Lys-Events
            const Text(
              'Seneste lys-events',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const LightLatestEventsList(
              lightData: [],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: CustomerNavBar(
        currentIndex: 0,
        onTap: (_) {
          // I fremtiden kan du håndtere navigation til andre faner her
        },
      ),
    );
  }
}