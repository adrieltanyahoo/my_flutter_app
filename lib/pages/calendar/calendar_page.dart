import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/calendar_event.dart';
import '../../providers/calendar_provider.dart';
import 'event_form_dialog.dart';
import 'meeting_rsvp_dialog.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage>
    with TickerProviderStateMixin {
  late ScrollController _dayViewScrollController;
  Timer? _timeUpdateTimer;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _dayViewScrollController = ScrollController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Start time update timer for real-time indicator
    _startTimeUpdateTimer();
    
    // Auto-scroll to current time in day view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime();
    });

    // Load initial events
    _loadInitialEvents();
  }

  Future<void> _loadInitialEvents() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    await ref.read(eventsProvider.notifier).loadEvents(startOfDay, endOfDay);
  }

  @override
  void dispose() {
    _dayViewScrollController.dispose();
    _timeUpdateTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  void _startTimeUpdateTimer() {
    _timeUpdateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && ref.read(viewTypeProvider) == ViewType.day) {
        setState(() {});
      }
    });
  }

  void _scrollToCurrentTime() {
    if (ref.read(viewTypeProvider) == ViewType.day) {
      final now = DateTime.now();
      final hour = now.hour;
      final minute = now.minute;
      
      // Calculate scroll position (60px per hour + 1px per minute)
      final scrollPosition = (hour * 60.0) + minute;
      
      _dayViewScrollController.animateTo(
        scrollPosition,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final viewType = ref.watch(viewTypeProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final events = ref.watch(eventsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(viewType, selectedDate),
      body: Column(
        children: [
          _buildViewControls(viewType, selectedDate),
          Expanded(
            child: _buildCalendarView(viewType, selectedDate, events),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(),
        backgroundColor: const Color(0xFF3B82F6),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ViewType viewType, DateTime selectedDate) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      title: Row(
        children: [
          const Icon(Icons.calendar_today, color: Color(0xFF3B82F6)),
          const SizedBox(width: 8),
          Text(
            _getAppBarTitle(viewType),
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.black54),
          onPressed: _showSearchDialog,
        ),
        IconButton(
          icon: const Icon(Icons.today, color: Colors.black54),
          onPressed: _goToToday,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.black54),
          onSelected: _handleMenuSelection,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'tasks',
              child: ListTile(
                leading: Icon(Icons.check_box),
                title: Text('My Tasks'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.settings),
                title: Text('Settings'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildViewControls(ViewType viewType, DateTime selectedDate) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _previousPeriod(viewType),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _nextPeriod(viewType),
              ),
              const SizedBox(width: 16),
              Text(
                _getDateRangeText(viewType, selectedDate),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildViewButton('Day', ViewType.day),
              const SizedBox(width: 8),
              _buildViewButton('Month', ViewType.month),
              const SizedBox(width: 8),
              _buildViewButton('Year', ViewType.year),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewButton(String label, ViewType viewType) {
    final isSelected = ref.watch(viewTypeProvider) == viewType;
    return GestureDetector(
      onTap: () => _changeView(viewType),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarView(ViewType viewType, DateTime selectedDate, List<CalendarEvent> events) {
    switch (viewType) {
      case ViewType.day:
        return _buildDayView(selectedDate, events);
      case ViewType.month:
        return _buildMonthView(selectedDate, events);
      case ViewType.year:
        return _buildYearView(selectedDate, events);
    }
  }

  // ... (rest of the UI building methods remain the same, just update them to use the events from the provider)

  void _showAddEventDialog({int? hour}) {
    showDialog(
      context: context,
      builder: (context) => EventFormDialog(
        initialDate: ref.read(selectedDateProvider),
        initialHour: hour,
        onSave: (CalendarEvent event) async {
          await ref.read(eventsProvider.notifier).addEvent(event);
        },
      ),
    );
  }

  void _showEventDetails(CalendarEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Time: ${DateFormat('HH:mm').format(event.start)} - ${DateFormat('HH:mm').format(event.end)}'),
            if (event.location != null) Text('Location: ${event.location}'),
            if (event.description != null) Text('Description: ${event.description}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditEventDialog(event);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  void _showEditEventDialog(CalendarEvent event) {
    showDialog(
      context: context,
      builder: (context) => EventFormDialog(
        event: event,
        onSave: (CalendarEvent updatedEvent) async {
          await ref.read(eventsProvider.notifier).updateEvent(updatedEvent);
        },
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Events'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Search for events...',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (query) async {
            final results = await ref.read(eventsProvider.notifier).searchEvents(query);
            // Show results in a new dialog or navigate to a results page
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _changeView(ViewType newView) {
    ref.read(viewTypeProvider.notifier).state = newView;
    
    if (newView == ViewType.day) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentTime();
      });
    }
  }

  void _goToToday() {
    final now = DateTime.now();
    ref.read(selectedDateProvider.notifier).state = now;
    
    if (ref.read(viewTypeProvider) == ViewType.day) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentTime();
      });
    }
  }

  void _previousPeriod(ViewType viewType) {
    final selectedDate = ref.read(selectedDateProvider);
    DateTime newDate;
    
    switch (viewType) {
      case ViewType.day:
        newDate = selectedDate.subtract(const Duration(days: 1));
        break;
      case ViewType.month:
        newDate = DateTime(selectedDate.year, selectedDate.month - 1, 1);
        break;
      case ViewType.year:
        newDate = DateTime(selectedDate.year - 1, selectedDate.month, 1);
        break;
    }
    
    ref.read(selectedDateProvider.notifier).state = newDate;
  }

  void _nextPeriod(ViewType viewType) {
    final selectedDate = ref.read(selectedDateProvider);
    DateTime newDate;
    
    switch (viewType) {
      case ViewType.day:
        newDate = selectedDate.add(const Duration(days: 1));
        break;
      case ViewType.month:
        newDate = DateTime(selectedDate.year, selectedDate.month + 1, 1);
        break;
      case ViewType.year:
        newDate = DateTime(selectedDate.year + 1, selectedDate.month, 1);
        break;
    }
    
    ref.read(selectedDateProvider.notifier).state = newDate;
  }

  String _getAppBarTitle(ViewType viewType) {
    switch (viewType) {
      case ViewType.day:
        return 'Calendar - Day View';
      case ViewType.month:
        return 'Calendar - Month View';
      case ViewType.year:
        return 'Calendar - Year View';
    }
  }

  String _getDateRangeText(ViewType viewType, DateTime date) {
    switch (viewType) {
      case ViewType.day:
        return DateFormat('EEEE, MMMM d, y').format(date);
      case ViewType.month:
        return DateFormat('MMMM y').format(date);
      case ViewType.year:
        return date.year.toString();
    }
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'tasks':
        // Navigate to tasks page
        break;
      case 'settings':
        // Navigate to settings page
        break;
    }
  }
} 