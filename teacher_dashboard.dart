import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';

class TeacherDashboard extends StatefulWidget {
  final String teacherId;
  final String teacherName;

  const TeacherDashboard({
    super.key,
    required this.teacherId,
    required this.teacherName,
  });

  @override
  _TeacherDashboardState createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  List courses = [];
  List students = [];
  bool isLoading = true;
  Map<String, dynamic>? selectedCourse;
  String? selectedCourseId;

  @override
  void initState() {
    super.initState();
    loadCourses();
  }

  void loadCourses() async {
    try {
      var courseSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .where('teacherId', isEqualTo: widget.teacherId)
          .get();

      setState(() {
        courses = courseSnapshot.docs.map((doc) {
          var data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        isLoading = false;
        if (courses.isNotEmpty) selectCourse(courses.first);
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Error loading courses: $e");
    }
  }

  void selectCourse(Map<String, dynamic> course) async {
    setState(() {
      selectedCourse = course;
      selectedCourseId = course['id'];
      students = [];
      isLoading = true;
    });

    try {
      var studentSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .doc(selectedCourseId)
          .collection('students')
          .get();

      setState(() {
        students = studentSnapshot.docs.map((doc) => doc.data()).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Error fetching students: $e");
    }
  }

  void markAttendance(
    String studentId,
    String studentName,
    String status,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('attendance').add({
        'studentId': studentId,
        'studentName': studentName,
        'courseId': selectedCourseId,
        'course_name': selectedCourse?['course_name'] ?? 'Unknown',
        'status': status,
        'date': DateTime.now().toString().split(' ')[0],
        'teacherId': widget.teacherId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${status.toUpperCase()} marked for $studentName"),
          backgroundColor: status == 'present' ? Colors.green : Colors.red,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      debugPrint("Attendance Error: $e");
    }
  }

  void showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
              );
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.teacherName),
        backgroundColor: const Color(0xFF1A237E),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: showLogoutDialog,
          ),
        ],
      ),
      // --- MODIFIED: Added Drawer for Sidebar ---
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF1A237E)),
              accountName: Text(widget.teacherName),
              accountEmail: const Text("Teacher Portal"),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Color(0xFF1A237E)),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "SELECT COURSE",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    selected: selectedCourseId == courses[index]['id'],
                    selectedTileColor: Colors.blue[50],
                    leading: const Icon(Icons.book),
                    title: Text(
                      courses[index]['course_name'] ?? 'Untitled Course',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    onTap: () {
                      selectCourse(courses[index]);
                      Navigator.pop(context); // Close drawer after selection
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // --- MODIFIED: Body is now full width ---
      body: Column(
        children: [
          if (selectedCourse != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: Colors.blue[100],
              child: Text(
                "Marking Attendance: ${selectedCourse!['course_name']}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : students.isEmpty
                ? const Center(
                    child: Text(
                      "No students found. Use menu to select a course.",
                    ),
                  )
                : ListView.builder(
                    itemCount: students.length,
                    padding: const EdgeInsets.only(top: 8, bottom: 20),
                    itemBuilder: (context, index) {
                      var student = students[index];
                      String name = student['studentName'] ?? 'No Name';
                      String roll = student['roll_no'] ?? 'No Roll No';
                      String sId = student['studentId'] ?? '';

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("Roll No: $roll"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 30,
                                ),
                                onPressed: () =>
                                    markAttendance(sId, name, 'present'),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.cancel,
                                  color: Colors.red,
                                  size: 30,
                                ),
                                onPressed: () =>
                                    markAttendance(sId, name, 'absent'),
                              ),
                            ],
                          ),
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
