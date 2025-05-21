import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/controller/clinician_dashboard_controller.dart';

class ClinicianNotificationsWidget extends StatelessWidget {
  const ClinicianNotificationsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ClinicianDashboardController>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Notifikationer",
          style: Theme.of(context).textTheme.titleLarge,
        ), // <== Denne manglede lukning
        ...controller.notifications.map((n) => Card(
          margin: EdgeInsets.symmetric(vertical: 5),
          child: ListTile(
            title: Text(n),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              // TODO: Naviger til relevant besked/aktivitet
            },
          ),
        )),
      ],
    );
  }
}
