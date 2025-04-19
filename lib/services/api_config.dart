import 'dart:io';

const bool useProdApi = false; // ← Skift til true når vi går live

String get baseUrl {
  if (useProdApi) {
    return 'https://ocutune-api.onrender.com'; // ← fx hvis vi deployer
  } else {
    final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
    return 'http://$host:5000';
  }
}
