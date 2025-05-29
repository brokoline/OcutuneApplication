import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ocutune_light_logger/controller/inbox_controller.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/messages/inbox_list_tile.dart';

import '../../../widgets/messages/message_thread_screen.dart';

class PatientInboxScreen extends StatelessWidget {
  const PatientInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InboxController(inboxType: InboxType.patient)..loadMessages(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Patientens Indbakke"),
          backgroundColor: generalBackground,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        backgroundColor: generalBackground,
        body: Consumer<InboxController>(
          builder: (context, controller, _) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.error != null) {
              return Center(
                child: Text(
                  controller.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            if (controller.messages.isEmpty) {
              return const Center(
                child: Text(
                  "Ingen beskeder endnu.",
                  style: TextStyle(color: Colors.white54),
                ),
              );
            }

            return ListView.builder(
              itemCount: controller.messages.length,
              itemBuilder: (context, index) {
                final msg = controller.messages[index];
                return InboxListTile(
                  msg: msg,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MessageThreadScreen(threadId: msg.threadId.toString()),
                      ),
                    );
                    await controller.refresh(); // ⬅️ Henter ny data når man vender tilbage
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
