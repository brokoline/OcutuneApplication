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
      id: json['id'],
      patientId: json['patient_id'],
      eventType: json['event_type'],
      note: json['note'],
      startTime: DateTime.tryParse(json['start_time'] ?? ''),
      endTime: DateTime.tryParse(json['end_time'] ?? ''),
      durationMinutes: json['duration_minutes'],
      eventTimestamp: DateTime.tryParse(json['event_timestamp'] ?? ''),
    );
  }
}
