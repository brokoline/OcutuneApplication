import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../theme/colors.dart';
import '../../../widgets/clinician_widgets/clinician_search_widgets/clinician_patient_search.dart';
import '../../../widgets/ocutune_textfield.dart';
import '../../../widgets/clinician_widgets/clinician_app_bar.dart';
import 'clinician_search_controller.dart';

class ClinicianSearchScreen extends StatefulWidget {
  const ClinicianSearchScreen({super.key});

  @override
  State<ClinicianSearchScreen> createState() => _ClinicianSearchScreenState();
}

class _ClinicianSearchScreenState extends State<ClinicianSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<ClinicianSearchController>(context, listen: false);
      controller.fetchPatients().then((_) {
        final lastQuery = controller.currentQuery;
        if (lastQuery.isNotEmpty) {
          _searchController.text = lastQuery;
          controller.searchPatients(lastQuery);
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ClinicianSearchController(),
      child: Scaffold(
        backgroundColor: generalBackground,
        appBar: const ClinicianAppBar(
          title: 'Søg efter patient',
          showLogout: false,
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8.h),
              Consumer<ClinicianSearchController>(
                builder: (context, controller, _) {
                  return OcutuneTextField(
                    label: 'Søg...',
                    controller: _searchController,
                    textColor: Colors.black,
                    onChanged: controller.searchPatients,
                  );
                },
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: ClinicianPatientSearch(controller: _searchController),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
