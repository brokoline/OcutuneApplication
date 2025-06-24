import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'meq_question_controller.dart';

class MeqResultScreen extends StatefulWidget {
  final String participantId;
  const MeqResultScreen({ required this.participantId, Key? key }) : super(key: key);

  @override
  _MeqResultScreenState createState() => _MeqResultScreenState();
}

class _MeqResultScreenState extends State<MeqResultScreen> {
  late MeqQuestionController ctrl;

  @override
  void initState() {
    super.initState();
    // Hent controller via Provider
    ctrl = Provider.of<MeqQuestionController>(context, listen: false);
    // Send svarene og hent scoren:
    ctrl.submitAnswers(widget.participantId).catchError((e){
      // evt. vis en fejl-dialog
      debugPrint("Fejl ved submit: $e");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dine MEQ‐resultater')),
      body: Center(
        child: Consumer<MeqQuestionController>(
          builder: (context, c, _) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('rMEQ: 0', style: TextStyle(fontSize: 24)),
                const SizedBox(height: 16),
                Text('MEQ: ${c.meqScore}', style: TextStyle(fontSize: 32)),
              ],
            );
          },
        ),
      ),
    );
  }
}
