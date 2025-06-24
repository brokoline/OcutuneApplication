import 'package:flutter/material.dart';
import '../../../utils/meq_response_summary.dart';

class MeqResultScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final summary = MeqResponseSummary.fromGlobal();

    return Scaffold(
      appBar: AppBar(title: const Text('Dine MEQ-resultater')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('rMEQ: ${summary.rmeq}', style: TextStyle(fontSize: 24)),
            SizedBox(height: 16),
            Text(
              'MEQ: ${summary.meqDisplay}',
              style: TextStyle(fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }
}
