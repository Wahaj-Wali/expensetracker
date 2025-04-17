import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationController {
  final String email;

  NotificationController({
    required this.email,
  });

  Future<void> sendWelcomeNotification(DocumentSnapshot userDoc) async {
    try {
      String title = "Welcome!";
      String description = "Welcome to our app. We're glad to have you here!";

      QuerySnapshot existingNotifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('title', isEqualTo: title)
          .where('email', isEqualTo: email)
          .get();

      if (existingNotifications.docs.isEmpty) {
        await _addNotification(title, description);
        print("Welcome notification added");
      } else {
        print("Welcome notification already exists for $email. Skipping.");
      }
    } catch (e) {
      print("Error in sendWelcomeNotification: $e");
    }
  }

  Future<void> _addNotification(String title, String description) async {
    try {
      QuerySnapshot existingNotifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('title', isEqualTo: title)
          .where('email', isEqualTo: email)
          .get();

      if (existingNotifications.docs.isEmpty) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'title': title,
          'description': description,
          'timestamp': FieldValue.serverTimestamp(),
          'email': email,
        });
        print("Notification added for $title");
      } else {
        print("Notification already exists for $email. Skipping.");
      }
    } catch (e) {
      print("Error adding notification: $e");
    }
  }
}
