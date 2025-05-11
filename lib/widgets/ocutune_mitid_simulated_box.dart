import 'package:flutter/material.dart';

class SimulatedMitIDBox extends StatefulWidget {
  final String title;
  final String inputLabel;
  final VoidCallback? onContinue;
  final TextEditingController controller;

  const SimulatedMitIDBox({
    super.key,
    required this.title,
    required this.inputLabel,
    required this.controller,
    this.onContinue,
  });

  @override
  State<SimulatedMitIDBox> createState() => _SimulatedMitIDBoxState();
}

class _SimulatedMitIDBoxState extends State<SimulatedMitIDBox> {
  bool rememberMe = false;

  void _showDialogBox({
    required String title,
    required String content,
    required String buttonText,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFF2B2B2B),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(content,
            style: const TextStyle(color: Colors.white70, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(buttonText,
                style: const TextStyle(color: Color(0xFF7F7FBF))),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    _showDialogBox(
      title: 'Hjælp (?!?!)',
      content:
      'Dette er et simuleret MitID-login.\n\n'
          'Vi kan desværre ikke hjælpe dig — fordi vi selv har brug for hjælp 🤯\n\n'
          'Tak til Digitaliseringsstyrelsen, eller .... noget.',
      buttonText: 'Got it 👊',
    );
  }

  void _showForgotDialog() {
    _showDialogBox(
      title: 'Glemt bruger-ID? 🤔',
      content:
      'Tror du vi har adgang til CPR-registret?\n\n'
          'Vi husker intet her – det er trods alt bare en wannabe-simulering',
      buttonText: 'Faiiiiiiir nok',
    );
  }

  void _showRememberMeDialog() {
    _showDialogBox(
      title: 'Husk mig? 🤖',
      content:
      'Hvis du virkelig vil gemmes, må du selv kode det.\n\n'
          'Vi husker intet her – det er trods alt bare en wannabe-simulering',
      buttonText: 'Faiiiiiiir nok',
    );
  }

  void _handleCancel() {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.2),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            overflow: TextOverflow.ellipsis,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Image.asset(
                        'assets/icon/mitid_logo.png',
                        height: 28,
                      ),
                    ],
                  ),
                  const Divider(height: 32, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(
                    widget.inputLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: widget.controller,
                    decoration: InputDecoration(
                      suffixIcon: const Icon(Icons.vpn_key, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF0051A4), width: 2),
                      ),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade400,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('FORTSÆT'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _showForgotDialog,
                    child: const Text(
                      'Glemt bruger-ID?',
                      style: TextStyle(color: Color(0xFF0051A4), fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () {
                      setState(() => rememberMe = !rememberMe);
                      _showRememberMeDialog();
                    },
                    child: Row(
                      children: [
                        Checkbox(
                          value: rememberMe,
                          onChanged: (value) {
                            setState(() {
                              rememberMe = value ?? false;
                            });
                          },
                          activeColor: const Color(0xFF0051A4),
                          visualDensity: VisualDensity.compact,
                        ),
                        const Expanded(
                          child: Text(
                            'Husk mig på denne enhed',
                            style: TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _handleCancel,
                        child: const Text('Afbryd', style: TextStyle(color: Colors.black87)),
                      ),
                      TextButton(
                        onPressed: _showHelpDialog,
                        child: const Text('Hjælp', style: TextStyle(color: Colors.black87)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
