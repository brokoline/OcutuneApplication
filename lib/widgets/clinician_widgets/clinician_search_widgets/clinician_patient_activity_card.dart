import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:intl/intl.dart';

import '../../../models/patient_event_model.dart';
import '../../../theme/colors.dart';

class PatientActivityCard extends StatelessWidget {
  final List<PatientEvent> events;

  const PatientActivityCard({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16.w),
        collapsedBackgroundColor: generalBox,
        backgroundColor: generalBox,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r)),
        collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r)),
        trailing: Icon(Icons.expand_more, color: Colors.white70),
        title: Text(
          'Registrerede aktiviteter',
          style: TextStyle(color: Colors.white70,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: events.length > 3 ? 240.h : double.infinity,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: events.length > 3
                    ? const ScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                itemCount: events.length,
                separatorBuilder: (_, __) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  final event = events[index];
                  return _buildEventTile(event);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventTile(PatientEvent event) {
    // Formatter start‐tidspunktet
    final date = DateFormat('dd.MM').format(event.startTime!);
    final time = event.startTime!.hour.toString().padLeft(2,'0')
        + ':' + event.startTime!.minute.toString().padLeft(2,'0');

    // Dur‐tekst
    final dur = event.durationMinutes ?? 0;

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      leading: Icon(FontAwesome5Solid.clock, size: 18.sp, color: Colors.white70),
      title: Text(
        event.eventType,
        style: TextStyle(
          color: Colors.white70,
          fontSize: 15.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        '$dur min registreret • $date • $time',
        style: TextStyle(color: Colors.white70, fontSize: 13.sp),
      ),
    );
  }


  String _renderTime(DateTime? dt) {
    if (dt == null) return '';
    // Formater dato + tid
    final date = DateFormat('dd.MM').format(dt);
    final time = dt.hour.toString().padLeft(2, '0')
        + ':' + dt.minute.toString().padLeft(2, '0');
    return '($date • $time)';
  }


  String _renderDurationLine(PatientEvent e) {
    final hasStart = e.startTime != null;
    final hasEnd = e.endTime != null;
    final hasDuration = e.durationMinutes != null;

    if (!hasStart && !hasEnd && hasDuration) {
      return '${e.durationMinutes} min registreret';
    }

    if (!hasStart && !hasEnd && !hasDuration) {
      return '';
    }

    final start = hasStart
        ? '${e.startTime!.hour.toString().padLeft(2, '0')}:${e.startTime!.minute
        .toString().padLeft(2, '0')}'
        : '--';
    final end = hasEnd
        ? '${e.endTime!.hour.toString().padLeft(2, '0')}:${e.endTime!.minute
        .toString().padLeft(2, '0')}'
        : '--';
    final dur = hasDuration ? '(${e.durationMinutes} min)' : '';

    return '$start → $end $dur';
  }

  bool _shouldShowNote(PatientEvent e) {
    return e.note != null && e.note!.trim().isNotEmpty &&
        e.note != 'Manuelt registreret';
  }
}