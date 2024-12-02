import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../widgets/message_bubble.dart';
import '../models/message.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ChatScreen extends StatefulWidget {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  ChatScreen({required this.flutterLocalNotificationsPlugin});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Message> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _isTyping = false;

  final Map<String, String> _staticResponses = {
    'hello': 'Hi there! How can I help you today?',
    'how are you': 'I am just a program, but I’m here for you!',
    'what is your name': 'My name is Partner. Nice to meet you!',
    'bye': 'Goodbye! Have a great day!',
  };

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones(); // Initialize time zones
    _scheduleDailyNotifications();
  }

  void _sendMessage(String text) {
    if (text.isEmpty) return;

    setState(() {
      _messages.add(Message(text: text, isUser: true));
      _isTyping = true;
    });

    _controller.clear();

    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _isTyping = false;
        String response = _staticResponses[text.toLowerCase()] ?? "I'm not sure how to respond to that.";
        _messages.add(Message(text: response, isUser: false));
      });
    });
  }

  void _scheduleDailyNotifications() {
    _scheduleNotification(13, 0, "Did you have lunch?");
    _scheduleNotification(18, 0, "Time to relax and have dinner!");
    _scheduleNotification(22, 0, "Good night! Time to rest.");
  }

  void _scheduleNotification(int hour, int minute, String message) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_reminder_channel',
      'Daily Reminders',
      channelDescription: 'Notifications for daily reminders',
      importance: Importance.max,
      priority: Priority.high,
    );

    final NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    await widget.flutterLocalNotificationsPlugin.zonedSchedule(
      hour * 100 + minute, // Unique ID for each notification
      'Partner Reminder',
      message,
      _nextInstanceOfTime(hour, minute),
      notificationDetails,
      androidAllowWhileIdle: true,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.wallClockTime,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(Duration(days: 1));
    }
    return scheduledDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Partner')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _messages.length) {
                  return MessageBubble(
                    message: Message(text: '...', isUser: false),
                  );
                }
                return MessageBubble(message: _messages[index]);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Ask something...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
