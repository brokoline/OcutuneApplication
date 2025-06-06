// lib/screens/customer/dashboard/customer_root_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/services/services/api_services.dart';
import 'package:ocutune_light_logger/widgets/customer_widgets/customer_app_bar.dart';
import 'package:ocutune_light_logger/widgets/customer_widgets/customer_nav_bar.dart';

import '../../../models/customer_model.dart';
import '../../../models/rmeq_chronotype_model.dart';
import '../customer_root_controller.dart';

import 'customer_overview_screen.dart';
import 'customer_light_detail_screen.dart';
import 'customer_chrono_insight_screen.dart';
import 'customer_profile_screen.dart';

class CustomerRootScreen extends StatelessWidget {
  const CustomerRootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CustomerRootController>(
      create: (_) => CustomerRootController(),
      child: const CustomerRootView(),
    );
  }
}

class CustomerRootView extends StatelessWidget {
  const CustomerRootView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CustomerRootController>();

    return FutureBuilder<Pair<Customer, ChronotypeModel?>>(
      future: ApiService.fetchCustomerProfile(),
      builder: (context, snapshot) {
        // ─── Loader ─────────────────────────────────────────────
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: generalBackground,
            appBar: const PreferredSize(
              preferredSize: Size.fromHeight(80),
              child: CustomerAppBar(title: ''),
            ),
            body: const Center(child: CircularProgressIndicator()),
            bottomNavigationBar: CustomerNavBar(
              currentIndex: controller.currentIndex,
              onTap: (idx) => controller.setIndex(idx),
            ),
          );
        }

        // ─── Fejl ───────────────────────────────────────────────
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: generalBackground,
            appBar: const PreferredSize(
              preferredSize: Size.fromHeight(80),
              child: CustomerAppBar(title: ''),
            ),
            body: Center(
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
            ),
            bottomNavigationBar: CustomerNavBar(
              currentIndex: controller.currentIndex,
              onTap: (idx) => controller.setIndex(idx),
            ),
          );
        }

        // ─── Ingen data ────────────────────────────────────────
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: generalBackground,
            appBar: const PreferredSize(
              preferredSize: Size.fromHeight(80),
              child: CustomerAppBar(title: ''),
            ),
            body: const Center(
              child: Text(
                'Ingen brugerdata fundet.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ),
            bottomNavigationBar: CustomerNavBar(
              currentIndex: controller.currentIndex,
              onTap: (idx) => controller.setIndex(idx),
            ),
          );
        }

        // ─── Profil‐data er hentet ─────────────────────────────
        final Customer profile = snapshot.data!.first;
        final ChronotypeModel? chronoModel = snapshot.data!.second;

        final String name = '${profile.firstName} ${profile.lastName}';
        final List<String> recommendations = [
          '08:00 – Gå en morgentur i dagslys',
          '21:00 – Undgå skærmlys før sengetid',
        ];

        // Fire separate undersider, lagt i en liste:
        final pages = [
          // 0: Oversigt
          CustomerOverviewScreen(
            profile: profile,
            recommendations: recommendations,
          ),

          // 1: Lysdetalje
          const CustomerLightDetailScreen(),

          // 2: Nørdeside
          const CustomerChronoInsightScreen(),

          // 3: Profil – her sender vi både customer + chronoModel
          CustomerProfileScreen(
            profile: profile,
            chronoModel: chronoModel,
          ),
        ];

        final titles = [
          "$name’s oversigt",
          'Lysdetalje',
          'Nørdeside',
          'Profil',
        ];

        return Scaffold(
          backgroundColor: generalBackground,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(80),
            child: CustomerAppBar(
              title: titles[controller.currentIndex],
            ),
          ),

          // Vis valgt underside
          body: pages[controller.currentIndex],

          bottomNavigationBar: CustomerNavBar(
            currentIndex: controller.currentIndex,
            onTap: (idx) => controller.setIndex(idx),
          ),
        );
      },
    );
  }
}
