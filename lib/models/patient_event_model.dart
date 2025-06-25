import 'dart:io';

DateTime? _parseAny(String? s) {
  if (s == null) return null;
  // ISO-8601
  final dt = DateTime.tryParse(s);
  if (dt != null) return dt;
  try {
    // RFC1123 fallback
    return HttpDate.parse(s).toLocal();
  } catch (_) {
    return null;
  }
}

class PatientEvent {
  final int id;
  final String patientId;
  final String eventType;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? durationMinutes;
  final DateTime? eventTimestamp;
  final String? note;

  PatientEvent({
    required this.id,
    required this.patientId,
    required this.eventType,
    this.startTime,
    this.endTime,
    this.durationMinutes,
    this.eventTimestamp,
    this.note,
  });

  factory PatientEvent.fromJson(Map<String, dynamic> json) {
    return PatientEvent(
      id: json['id'] as int,
      patientId: json['patient_id'] as String,
      eventType: json['event_type'] as String,
      note: json['note'] as String?,
      startTime: _parseAny(json['start_time'] as String?),
      endTime:   _parseAny(json['end_time']   as String?),
      durationMinutes: json['duration_minutes'] as int?,
      eventTimestamp:  _parseAny(json['event_timestamp'] as String?),
    );
  }
}
