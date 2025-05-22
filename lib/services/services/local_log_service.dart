import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LocalLogService {
  static Future<File> _getLogFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/ocutune_log.txt');
  }

  static Future<void> log(String message) async {
    final file = await _getLogFile();
    final timestamp = DateTime.now().toIso8601String();
    await file.writeAsString('$timestamp - $message\n', mode: FileMode.append);
  }

  static Future<String> readLog() async {
    final file = await _getLogFile();
    return await file.readAsString();
  }

  static Future<void> clear() async {
    final file = await _getLogFile();
    await file.writeAsString('');
  }
}
