import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../screens/clinician/root/clinician_root_controller.dart';

class ClinicianNotificationsWidget extends StatelessWidget {
  const ClinicianNotificationsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ClinicianRootController>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Notifikationer",
          style: Theme.of(context).textTheme.titleLarge,
        ),
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
