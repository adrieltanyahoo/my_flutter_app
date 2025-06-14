import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:workaton/models/calendar_event.dart';

class CalendarEventCard extends StatelessWidget {
  final CalendarEvent event;
  final double height;

  const CalendarEventCard({
    super.key,
    required this.event,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: event.color.withOpacity(0.2),
        border: Border.all(
          color: event.color,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Show event details dialog
          },
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event title
                Text(
                  event.title,
                  style: TextStyle(
                    color: event.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // Event time
                Text(
                  '${DateFormat('h:mm a').format(event.start)} - ${DateFormat('h:mm a').format(event.end)}',
                  style: TextStyle(
                    color: event.color.withOpacity(0.8),
                    fontSize: 10,
                  ),
                ),
                
                // Location (if available)
                if (event.location != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 10,
                        color: event.color.withOpacity(0.8),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          event.location!,
                          style: TextStyle(
                            color: event.color.withOpacity(0.8),
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Video call indicator (if applicable)
                if (event.isVideoCall == true) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.videocam,
                        size: 10,
                        color: event.color.withOpacity(0.8),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'Video Call',
                        style: TextStyle(
                          color: event.color.withOpacity(0.8),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Team name (if available)
                if (event.teamName != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.group,
                        size: 10,
                        color: event.color.withOpacity(0.8),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          event.teamName!,
                          style: TextStyle(
                            color: event.color.withOpacity(0.8),
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
} 