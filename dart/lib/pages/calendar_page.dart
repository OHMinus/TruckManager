import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:go_router/go_router.dart';
import '../models/capsules.dart' as model;
import '../services/firestore_service.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final FirestoreService _firestoreService = FirestoreService();

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List<model.OrderCapsule>> _groupedOrders = {};
  List<model.OrderCapsule> _selectedEvents = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    _firestoreService.getOrdersStream().listen((orders) {
      if (mounted) {
        setState(() {
          _groupedOrders = _groupOrdersByDate(orders);
          _selectedEvents = _getEventsForDay(_selectedDay!);
        });
      }
    });
  }

  Map<DateTime, List<model.OrderCapsule>> _groupOrdersByDate(List<model.OrderCapsule> orders) {
    Map<DateTime, List<model.OrderCapsule>> data = {};
    for (var order in orders) {
      if (order.date.isNotEmpty) {
        try {
          DateTime parsedDate = DateTime.parse(order.date);
          DateTime date = DateTime.utc(parsedDate.year, parsedDate.month, parsedDate.day);
          if (data[date] == null) data[date] = [];
          data[date]!.add(order);
        } catch (e) {
          debugPrint('Error parsing date: ${order.date}');
        }
      }
    }
    return data;
  }

  List<model.OrderCapsule> _getEventsForDay(DateTime day) {
    DateTime normalizedDay = DateTime.utc(day.year, day.month, day.day);
    return _groupedOrders[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Calendar'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          TableCalendar<model.OrderCapsule>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            eventLoader: _getEventsForDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  _selectedEvents = _getEventsForDay(selectedDay);
                });
              }
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: _selectedEvents.isEmpty
                ? const Center(child: Text('No orders for this day.'))
                : ListView.builder(
                    itemCount: _selectedEvents.length,
                    itemBuilder: (context, index) {
                      final order = _selectedEvents[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                        child: ListTile(
                          title: Text(order.objectName.isNotEmpty ? order.objectName : 'Unknown Event'),
                          subtitle: Text('Price: ${order.price} | State: ${order.state.name}'),
                          onTap: () {
                            context.go('/order/${order.id}');
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
