import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app2/auth_wrapper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:firebase_app2/screens/add_new_task.dart';
import 'package:firebase_app2/utils.dart';
import 'package:firebase_app2/widgets/date_selector.dart';
import 'package:firebase_app2/widgets/task_card.dart';

import 'dart:convert';
import 'dart:typed_data';

Widget buildImageFromBase64(String base64String) {
  try {
    Uint8List bytes = base64Decode(base64String);
    return ClipOval(
      child: Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: 100,
        height: 100,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/fallback.png',
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          );
        },
      ),
    );
  } catch (e) {
    return ClipOval(
      child: Image.asset(
        'assets/images/fallback.png',
        width: 100,
        height: 100,
        fit: BoxFit.cover,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Tasks', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color.fromARGB(255, 74, 122, 161),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddNewTask()),
                );
              },
              icon: const Icon(CupertinoIcons.add, color: Colors.white),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AuthWrapper()),
            );
          },

          child: const Icon(Icons.logout),
        ),
        body: Column(
          children: [
            DateSelector(
              onDateSelected: (date) {
                setState(() {
                  _selectedDate = date;
                });
              },
            ),
            StreamBuilder(
              stream:
                  FirebaseFirestore.instance
                      .collection("tasks")
                      .where(
                        'creator',
                        isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                      )
                      .orderBy('date')
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Column(
                    children: [
                      SizedBox(height: 200),
                      const Text('No tasks found.'),
                    ],
                  );
                }

                // Filter tasks based on selected date
                final tasks =
                    snapshot.data!.docs.where((doc) {
                      final taskDate = (doc['date'] as Timestamp).toDate();
                      return taskDate.year == _selectedDate.year &&
                          taskDate.month == _selectedDate.month &&
                          taskDate.day == _selectedDate.day;
                    }).toList();

                if (tasks.isEmpty) {
                  return Column(
                    children: [
                      SizedBox(height: 200),
                      const Text(
                        'No tasks for selected date.',
                        style: TextStyle(fontSize: 20),
                      ),
                    ],
                  );
                }

                return Expanded(
                  child: ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index].data();
                      final taskDateTime = (task['date'] as Timestamp).toDate();
                      final formattedDate = formatDateTime(taskDateTime);

                      return Dismissible(
                        direction: DismissDirection.startToEnd,
                        key: Key(task['title']),
                        onDismissed: (direction) {
                          FirebaseFirestore.instance
                              .collection('tasks')
                              .doc(tasks[index].id)
                              .delete();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${task['title']} dismissed'),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Expanded(
                              child: TaskCard(
                                color: hexToColor(task['color']),
                                headerText: task['title'],
                                descriptionText: task['description'],
                                scheduledDate: formattedDate,
                                taskDateTime: taskDateTime,
                              ),
                            ),
                            Container(
                              height: 100,
                              width: 100,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: buildImageFromBase64(task['image']),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String formatDateTime(DateTime dateTime) {
    return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
  }

  String formatTime(DateTime dateTime) {
    int hour = dateTime.hour;
    int minute = dateTime.minute;
    String ampm = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;

    return '$hour:${minute.toString().padLeft(2, '0')} $ampm';
  }
}
