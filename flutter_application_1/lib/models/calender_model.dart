import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarEventModel {
  String? eventId;
  String title;
  DateTime date;
  String? description;
  String userId; // User ID of the creator
  String creatorName; // Name of the event creator

  CalendarEventModel({
    this.eventId,
    required this.title,
    required this.date,
    this.description,
    required this.userId,
    required this.creatorName, // Make creatorName required
  });

  // Convert a CalendarEventModel to a Map
  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'title': title,
      'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)), // Store only the date part
      'description': description,
      'userId': userId,
      'creatorName': creatorName, // Include creatorName in the map
    };
  }

  // Create a CalendarEventModel from a Map
  static CalendarEventModel fromMap(Map<String, dynamic> map) {
    return CalendarEventModel(
      eventId: map['eventId'],
      title: map['title'],
      date: (map['date'] as Timestamp).toDate(),
      description: map['description'],
      userId: map['userId'],
      creatorName: map['creatorName'], // Retrieve creatorName from the map
    );
  }

  // Save event to Firestore
  Future<void> saveToFirestore() async {
    final docRef = FirebaseFirestore.instance.collection('events').doc(eventId);
    await docRef.set(toMap());
  }

  // Delete event from Firestore
  Future<void> deleteFromFirestore() async {
    final docRef = FirebaseFirestore.instance.collection('events').doc(eventId);
    await docRef.delete();
  }

  // Update event in Firestore
  Future<void> updateInFirestore() async {
    final docRef = FirebaseFirestore.instance.collection('events').doc(eventId);
    await docRef.update(toMap());
  }
}
