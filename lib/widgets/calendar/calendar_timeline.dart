import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:workaton/models/calendar_event.dart';
import 'package:workaton/widgets/calendar/calendar_event_card.dart';

class CalendarTimeline extends StatelessWidget {
  final DateTime selectedDay;
  final List<CalendarEvent> events;

  const CalendarTimeline({
    super.key,
    required this.selectedDay,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Hour markers
        ListView.builder(
          itemCount: 24,
          itemBuilder: (context, hour) {
            return Container(
              height: 97, // Fixed height for each hour slot
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[800]!,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Hour label
                  SizedBox(
                    width: 60,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        _formatHour(hour),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  // Time slot
                  Expanded(
                    child: Container(
                      color: Colors.transparent,
                      child: Stack(
                        children: [
                          // Events for this hour
                          ..._getEventsForHour(hour).map((event) {
                            final startHour = event.start.hour;
                            final startMinute = event.start.minute;
                            final endHour = event.end.hour;
                            final endMinute = event.end.minute;
                            
                            final top = startMinute * (97 / 60);
                            final height = ((endHour - startHour) * 60 + (endMinute - startMinute)) * (97 / 60);
                            
                            return Positioned(
                              top: top,
                              left: 0,
                              right: 0,
                              child: CalendarEventCard(
                                event: event,
                                height: height,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        
        // Current time indicator
        if (_isToday(selectedDay)) _buildCurrentTimeIndicator(),
      ],
    );
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour == 12) return '12 PM';
    if (hour < 12) return '$hour AM';
    return '${hour - 12} PM';
  }

  List<CalendarEvent> _getEventsForHour(int hour) {
    return events.where((event) {
      final eventStart = event.start;
      final eventEnd = event.end;
      return (eventStart.hour <= hour && eventEnd.hour >= hour) ||
          (eventStart.hour == hour || eventEnd.hour == hour);
    }).toList();
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Widget _buildCurrentTimeIndicator() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final top = (hour * 97) + (minute * (97 / 60));

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Container(
        height: 2,
        color: Colors.red,
        child: Row(
          children: [
            Container(
              width: 60,
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                DateFormat('h:mm a').format(now),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 2,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 