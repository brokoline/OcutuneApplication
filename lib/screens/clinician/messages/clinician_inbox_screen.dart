import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:ocutune_light_logger/controller/inbox_controller.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/messages/inbox_list_tile.dart';

import '../../../widgets/messages/message_thread_screen.dart';

class ClinicianInboxScreen extends StatelessWidget {
  const ClinicianInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InboxController(inboxType: InboxType.clinician)..loadMessages(),
      child: Scaffold(
        backgroundColor: generalBackground,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 24.h),
            Center(
              child: Text(
                'Indbakke',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: Consumer<InboxController>(
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
                        'Ingen beskeder endnu.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemCount: controller.messages.length,
                    itemBuilder: (context, index) {
                      final msg = controller.messages[index];
                      return InboxListTile(
                        msg: msg,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MessageThreadScreen(
                                threadId: msg.threadId.toString(),
                              ),
                            ),
                          );
                          await controller.refresh();
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final changed = await Navigator.pushNamed(
              context,
              '/clinician/new_message',
            );
            if (changed == true) {
              context.read<InboxController>().loadMessages();
            }
          },
          backgroundColor: Colors.white70,
          foregroundColor: Colors.black,
          icon: const Icon(Icons.add),
          label: const Text('Ny besked'),
        ),
      ),
    );
  }
}
