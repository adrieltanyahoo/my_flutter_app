import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/calendar_event.dart';
import '../services/calendar_service.dart';

// Provider for the events box
final eventsBoxProvider = Provider<Box<CalendarEvent>>((ref) {
  throw UnimplementedError('Initialize Hive first');
});

// Provider for the calendar service
final calendarServiceProvider = Provider<CalendarService>((ref) {
  return CalendarService();
});

// Provider for the current view type
final viewTypeProvider = StateProvider<ViewType>((ref) => ViewType.day);

// Provider for the selected date
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// Provider for the events list
final eventsProvider = StateNotifierProvider<EventsNotifier, List<CalendarEvent>>((ref) {
  final box = ref.watch(eventsBoxProvider);
  final service = ref.watch(calendarServiceProvider);
  return EventsNotifier(box, service);
});

// Notifier class for managing events
class EventsNotifier extends StateNotifier<List<CalendarEvent>> {
  final Box<CalendarEvent> _box;
  final CalendarService _service;

  EventsNotifier(this._box, this._service) : super([]) {
    // Load events from Hive on initialization
    state = _box.values.toList();
  }

  // Load events for a specific date range
  Future<void> loadEvents(DateTime start, DateTime end) async {
    try {
      final events = await _service.getEvents(startDate: start, endDate: end);
      // Update Hive box
      await _box.clear();
      await _box.addAll(events);
      // Update state
      state = events;
    } catch (e) {
      print('Error loading events: $e');
      // Fallback to cached events
      state = _box.values.toList();
    }
  }

  // Add a new event
  Future<void> addEvent(CalendarEvent event) async {
    try {
      final created = await _service.createEvent(event);
      if (created != null) {
        await _box.put(created.id, created);
        state = [...state, created];
      }
    } catch (e) {
      print('Error adding event: $e');
    }
  }

  // Update an existing event
  Future<void> updateEvent(CalendarEvent event) async {
    try {
      final updated = await _service.updateEvent(event);
      if (updated != null) {
        await _box.put(updated.id, updated);
        state = state.map((e) => e.id == updated.id ? updated : e).toList();
      }
    } catch (e) {
      print('Error updating event: $e');
    }
  }

  // Delete an event
  Future<void> deleteEvent(String id) async {
    try {
      final success = await _service.deleteEvent(id);
      if (success) {
        await _box.delete(id);
        state = state.where((e) => e.id != id).toList();
      }
    } catch (e) {
      print('Error deleting event: $e');
    }
  }

  // Send RSVP for an event
  Future<void> sendRSVP(String eventId, RSVPStatus status, {String? note}) async {
    try {
      await _service.sendRSVP(
        eventId: eventId,
        status: status,
        note: note,
      );
    } catch (e) {
      print('Error sending RSVP: $e');
    }
  }

  // Search events
  Future<List<CalendarEvent>> searchEvents(String query) async {
    try {
      return await _service.searchEvents(query);
    } catch (e) {
      print('Error searching events: $e');
      return [];
    }
  }
} 