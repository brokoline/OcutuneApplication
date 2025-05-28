import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:ocutune_light_logger/controller/inbox_controller.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/messages/inbox_list_tile.dart';
import 'package:ocutune_light_logger/widgets/clinician_widgets/clinician_app_bar.dart';

class InboxScreen extends StatelessWidget {
  final InboxType inboxType;
  final bool useClinicianAppBar;
  final bool showNewMessageButton;

  const InboxScreen({
    super.key,
    required this.inboxType,
    this.useClinicianAppBar = false,
    this.showNewMessageButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InboxController(inboxType: inboxType)..fetchInbox(),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: generalBackground,
          appBar: useClinicianAppBar
              ? const ClinicianAppBar(title: 'Indbakke', showLogout: false)
              : AppBar(
            backgroundColor: generalBackground,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white70),
            title: const Text(
              'Indbakke',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
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
                    'Ingen beskeder endnu.',
                    style: TextStyle(color: Colors.white54),
                  ),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: controller.messages.length,
                      itemBuilder: (context, index) {
                        final msg = controller.messages[index];
                        return InboxListTile(
                          msg: msg,
                          onTap: () async {
                            final changed = await Navigator.pushNamed(
                              context,
                              inboxType == InboxType.clinician
                                  ? '/clinician/message_detail'
                                  : '/patient/message_detail',
                              arguments: msg.threadId,
                            );

                            if (changed == true && context.mounted) {
                              await context.read<InboxController>().fetchInbox();
                            }
                          },
                        );
                      },
                    ),
                  ),
                  if (showNewMessageButton)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final changed = await Navigator.pushNamed(
                            context,
                            inboxType == InboxType.clinician
                                ? '/clinician/new_message'
                                : '/patient/new_message',
                          );
                          if (changed == true && context.mounted) {
                            await context.read<InboxController>().fetchInbox();
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Ny besked'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white70,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
