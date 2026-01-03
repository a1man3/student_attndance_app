import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';

class StudentDashboard extends StatefulWidget {
  final String studentId; // Updated to String for Firebase
  final String studentName;

  const StudentDashboard({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  List attendanceRecords = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAttendance();
  }

  // Fetches attendance from Firestore using the String studentId
  void fetchAttendance() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .where('studentId', isEqualTo: widget.studentId)
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        attendanceRecords = snapshot.docs.map((doc) => doc.data()).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Error fetching attendance: $e");
    }
  }

  void logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome, ${widget.studentName}"),
        backgroundColor: const Color(0xFF1A237E),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : attendanceRecords.isEmpty
          ? const Center(child: Text("No attendance records found."))
          : ListView.builder(
              itemCount: attendanceRecords.length,
              itemBuilder: (context, index) {
                var record = attendanceRecords[index];
                bool isPresent = record['status'] == 'present';
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: Icon(
                      isPresent ? Icons.check_circle : Icons.cancel,
                      color: isPresent ? Colors.green : Colors.red,
                    ),
                    title: Text(record['course_name'] ?? "Unknown Course"),
                    subtitle: Text("Date: ${record['date']}"),
                    trailing: Text(
                      record['status'].toString().toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isPresent ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
