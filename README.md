# Student Attendance App (Teacher Portal) 🎓

A modern, responsive Flutter application designed for teachers to manage course-wise student attendance seamlessly. The app utilizes **Firebase Firestore** for real-time data management and **Firebase Authentication** for secure teacher access.



## 🚀 Features

* **Secure Authentication**: Teacher login via Firebase Auth.
* **Responsive Dashboard**: Adaptive UI that works perfectly in portrait and landscape modes using a Material Design Drawer.
* **Course-Based Filtering**: Automatically fetches and displays only the courses assigned to the logged-in teacher.
* **One-Tap Attendance**: Quick "Present" (Green) or "Absent" (Red) marking system with instant feedback via SnackBar.
* **Real-time Database**: Powered by Cloud Firestore with sub-collection architecture for optimized data retrieval.
* **Modern Build System**: Fully migrated to **Kotlin DSL (`.kts`)** and **AndroidX** for high performance and stability.

## 🛠️ Tech Stack

* **Frontend**: [Flutter](https://flutter.dev/) (Dart)
* **Backend**: [Firebase Firestore](https://firebase.google.com/docs/firestore) (NoSQL Database)
* **Auth**: [Firebase Authentication](https://firebase.google.com/docs/auth)
* **Architecture**: Stateful Widgets & Reactive UI

## 📂 Project Structure

```text
lib/
├── main.dart             # Entry point & Routing
├── teacher_dashboard.dart # Core dashboard logic & Responsive UI
└── ...                   # Other helper widgets
```
 Installation & Setup
 Clone the repository:Bashgit clone [https://a1man3/student_attndance_app.)
Install dependencies:Bashflutter pub get
Firebase Setup:Create a Firebase project at Firebase Console.Add an Android app with package name com.example.student_attendance_app.Download google-services.json and place it in android/app/.Run the app:Bashflutter run
📝 Firestore Data SchemaThe app expects the following structure in Firestore:courses (Collection)course_name (String)teacherId (String)students (Sub-collection)studentName (String)roll_no (String)studentId (String)📸 ScreenshotsLogin ScreenTeacher DashboardMark Attendance🤝 ContributingContributions, issues, and feature requests are welcome!Developed by Your Name
---

### Tips for your GitHub Upload:
1.  **Add Real Screenshots**: In the `README`, replace the "placeholder" links with actual screenshots you take from your phone. People love to see the app in action!
2.  **The .gitignore file**: Ensure you have a `.gitignore` file so you don't upload your `build/` folder or `google-services.json` (if you want to keep your Firebase keys private).
3.  **The "About" Section**: On GitHub, add tags like `#flutter`, `#firebase`, and `#android` to help people find your project.

**Would you like me to show you how to initialize the git repository and push this to
