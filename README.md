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

