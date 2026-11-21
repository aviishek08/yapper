import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/calender_model.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; 

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  List<CalendarEventModel> _events = [];
  late String _userId;
  late String _userName; // Current user's name

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _userId = FirebaseAuth.instance.currentUser!.uid;
    _userName = FirebaseAuth.instance.currentUser!.displayName ?? 'Anonymous'; // Get the current user's name
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('events')
        .where('date', isEqualTo: Timestamp.fromDate(DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day)))
        .get();
    setState(() {
      _events = snapshot.docs
          .map((doc) => CalendarEventModel.fromMap(doc.data()))
          .toList();
    });
  }

  Future<void> _addEvent(String title, String? description) async {
    final event = CalendarEventModel(
      eventId: FirebaseFirestore.instance.collection('events').doc().id,
      title: title,
      date: DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day),
      description: description,
      userId: _userId,
      creatorName: _userName, // Include the current user's name
    );
    await event.saveToFirestore();
    _loadEvents(); 
  }

  Future<void> _editEvent(CalendarEventModel event, String title, String? description) async {
    event.title = title;
    event.description = description;
    await event.updateInFirestore();
    _loadEvents(); 
  }

  Future<void> _deleteEvent(CalendarEventModel event) async {
    await event.deleteFromFirestore();
    _loadEvents(); 
  }

  void _showEventDialog({CalendarEventModel? event}) {
    final titleController = TextEditingController(text: event?.title ?? '');
    final descriptionController = TextEditingController(text: event?.description ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(event == null ? 'Add Event' : 'Edit Event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Event Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Event Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (event == null) {
                  _addEvent(titleController.text, descriptionController.text);
                } else {
                  _editEvent(event, titleController.text, descriptionController.text);
                }
                Navigator.pop(context);
              },
              child: Text(event == null ? 'Add' : 'Save'),
            ),
            if (event != null)
              TextButton(
                onPressed: () {
                  _deleteEvent(event);
                  Navigator.pop(context);
                },
                child: Text('Delete'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar'),
      ),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _loadEvents();
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            firstDay: DateTime.utc(2000, 01, 01),
            lastDay: DateTime.utc(2100, 12, 31),
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.orangeAccent,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleTextStyle: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Selected Date: ${DateFormat('yyyy-MM-dd').format(_selectedDay)}',
            style: TextStyle(fontSize: 18.0),
          ),
          ElevatedButton(
            onPressed: () => _showEventDialog(),
            child: Text('Add Event'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _events.length,
              itemBuilder: (context, index) {
                final event = _events[index];
                return ListTile(
                  title: Text(event.title),
                  subtitle: Text('${event.description ?? ''}\nCreated by: ${event.creatorName}'),
                  onTap: () => _showEventDialog(event: event),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
