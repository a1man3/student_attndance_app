// server.js - Updated to Support Expanded Schema and Features

const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
// Using mysql2 for robust features like prepared statements (better security)
const mysql = require('mysql2'); 
const app = express();

// Middleware setup
app.use(cors());
app.use(bodyParser.json());

// ------------------------------------------------------------------
// 1. DATABASE CONNECTION
// ------------------------------------------------------------------
const db = mysql.createConnection({
    host: "localhost",
    user: "root",
    password: "", // IMPORTANT: Change this if you set a MySQL password in XAMPP
    database: "attendance_db"
});

db.connect((err) => {
    if (err) {
        console.log("Database connection failed:", err);
    } else {
        console.log("Database connected successfully!");
    }
});

// Start the server
const PORT = 3000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});

// Test Route (Feature 7: REST API Integration)
app.get("/", (req, res) => {
    res.send("Attendance Server Running");
});

// ===============================================
// 2. AUTHENTICATION (Feature 1 & 10: Role-Based Dashboard)
// ===============================================

/**
 * Handles Teacher and Student Login. Uses dummy password check for now.
 */
app.post("/login", (req, res) => {
    const { email, password } = req.body;
    
    // Attempt Teacher Login
    let query = "SELECT id, name, email FROM teachers WHERE email = ? AND password_hash = ?"; 
    db.query(query, [email, password], (err, result) => {
        if (err) return res.status(500).send(err);
        if (result && result.length > 0) {
            // Teacher Found
            return res.json({ role: "teacher", user: result[0] });
        }

        // Attempt Student Login
        query = "SELECT id, name, roll_no, current_semester_id FROM students WHERE email = ? AND password_hash = ?";
        db.query(query, [email, password], (err, result) => {
            if (err) return res.status(500).send(err);
            if (result && result.length > 0) {
                // Student Found
                return res.json({ role: "student", user: result[0] });
            }
            
            // Login Failed
            res.status(401).json({ message: "Invalid credentials" });
        });
    });
});

// ===============================================
// 3. TEACHER ROUTES (Features 2, 3, 4, 5)
// ===============================================

/**
 * Route to fetch courses a specific teacher is assigned to.
 * Needed for Teacher Dashboard to select which course attendance to mark.
 */
// ===============================================
// New Route to fetch courses taught by a specific teacher
// ===============================================
// ===============================================
// FIXED: Fetch courses taught by a specific teacher
// ===============================================
app.get("/teacher/courses/:teacherId", (req, res) => {
    const teacherId = req.params.teacherId;

    const query = `
        SELECT 
            sc.id AS semester_course_id, 
            c.id AS course_id, 
            c.course_code, 
            c.course_name,
            s.name AS semester_name  -- CHANGED from s.semester_name to s.name
        FROM 
            semester_courses sc
        JOIN 
            courses c ON sc.course_id = c.id
        JOIN 
            semesters s ON sc.semester_id = s.id
        WHERE 
            sc.teacher_id = ?
    `;

    db.query(query, [teacherId], (err, result) => {
        if (err) {
            console.error("[ERROR] Teacher courses query failed:", err);
            return res.status(500).send(err);
        }
        res.json(result);
    });
});

/**
 * Route to fetch all students enrolled in a course associated with a specific semester/batch.
 * (Feature 2: View All Students - now filtered by course for efficiency)
 * NOTE: For simplicity, this currently fetches ALL students. A true scalable app would filter 
 * by the semester_course_id to ensure only relevant students appear.
 */
/**
 * Route to fetch all students enrolled in the same semester as the course.
 * This ensures the teacher only sees relevant students.
 */
app.get("/students/course/:semesterCourseId", (req, res) => {
    const semesterCourseId = req.params.semesterCourseId;

    // 1. Get the semester_id associated with the requested semester_course_id
    const findSemesterQuery = `
        SELECT semester_id FROM semester_courses WHERE id = ?`;
    
    db.query(findSemesterQuery, [semesterCourseId], (err, semesterResult) => {
        if (err) return res.status(500).send(err);
        
        if (semesterResult.length === 0) {
            return res.json([]); // Course not found
        }
        
        const semesterId = semesterResult[0].semester_id;

        // 2. Fetch all students who are currently in that semester
        const studentsQuery = `
            SELECT id, name, roll_no 
            FROM students 
            WHERE current_semester_id = ? 
            ORDER BY roll_no`;
        
        db.query(studentsQuery, [semesterId], (err, studentsResult) => {
            if (err) return res.status(500).send(err);
            res.json(studentsResult);
        });
    });
});

/**
 * Route to mark attendance for a student (Feature 3: Mark Attendance & 4: Automatic Date Logging)
 * Uses INSERT...ON DUPLICATE KEY UPDATE for real-time saving (Feature 5).
 */
app.post("/attendance", (req, res) => {
    const { student_id, course_id, status } = req.body; 
    
    // Feature 4: Automatic Date Logging (CURDATE())
    // Feature 5: Real-Time Sync (ON DUPLICATE KEY UPDATE)
    const query = `
        INSERT INTO attendance (student_id, course_id, date, status) 
        VALUES (?, ?, CURDATE(), ?) 
        ON DUPLICATE KEY UPDATE status = VALUES(status)`;
        
    db.query(query, [student_id, course_id, status], (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).json({ error: "Failed to mark attendance" });
        }
        res.json({ message: "Attendance marked and synced!" });
    });
});

/**
 * Helper route to log the class conducted, required for accurate shortage calculation.
 * A teacher should hit this route once per class session.
 */
app.post("/class_conducted", (req, res) => {
    const { semester_course_id, topic_covered } = req.body;
    const query = `INSERT INTO class_schedule (semester_course_id, class_date, topic_covered) VALUES (?, CURDATE(), ?)`;
    db.query(query, [semester_course_id, topic_covered || ''], (err, result) => {
        if (err) {
             // Avoid primary key duplication error if teacher clicks twice
            if (err.code === 'ER_DUP_ENTRY') {
                return res.json({ message: "Class already logged for today." });
            }
            return res.status(500).send(err);
        }
        res.json({ message: "Class logged successfully." });
    });
});

// ===============================================
// 4. STUDENT ROUTES (Feature 6 & Viva Feature)
// ===============================================

/**
 * Route to fetch attendance history for a specific student (Feature 6: View Attendance History)
 * /attendance/:student_id
 */
app.get("/attendance/:student_id", (req, res) => {
    const studentId = req.params.student_id;
    
    const query = `
        SELECT 
            a.date, 
            a.status,
            c.course_code,
            c.course_name
        FROM attendance a
        JOIN courses c ON a.course_id = c.id
        WHERE a.student_id = ?
        ORDER BY a.date DESC`;
        
    db.query(query, [studentId], (err, result) => {
        if (err) return res.status(500).send(err);
        res.json(result);
    });
});

/**
 * Calculates attendance percentage for the student across all courses 
 * (Impressive Viva Feature: Attendance Analytics/Shortage Check)
 */
app.get("/attendance/summary/:student_id", (req, res) => {
    const studentId = req.params.student_id;

    // This complex query calculates: (Total Present / Total Classes Conducted) * 100
    const query = `
        SELECT
            c.course_code,
            c.course_name,
            -- Count where the student was marked present for that course
            COUNT(CASE WHEN a.status = 'present' THEN 1 END) AS present_count,
            -- Count all classes logged for that course
            COUNT(cs.class_date) AS total_classes,
            -- Calculate percentage, handling division by zero
            IF(COUNT(cs.class_date) > 0, 
                (COUNT(CASE WHEN a.status = 'present' THEN 1 END) / COUNT(cs.class_date)) * 100, 
                0) AS percentage
        FROM students s
        -- Link student to the courses they are enrolled in this semester
        JOIN semester_courses sc ON s.current_semester_id = sc.semester_id
        JOIN courses c ON sc.course_id = c.id
        -- Find all classes conducted for that specific course/semester
        LEFT JOIN class_schedule cs ON sc.id = cs.semester_course_id
        -- Match the student's attendance records to the conducted classes
        LEFT JOIN attendance a ON a.student_id = s.id AND a.course_id = c.id AND a.date = cs.class_date
        WHERE s.id = ?
        GROUP BY c.id, c.course_code, c.course_name
        ORDER BY c.course_code;
    `;

    db.query(query, [studentId], (err, result) => {
        if (err) return res.status(500).send(err);
        
        // Add a 'shortage' flag on the server side (e.g., if below 75%)
        const minimumPercentage = 75;
        const summary = result.map(record => ({
            ...record,
            percentage: parseFloat(record.percentage).toFixed(2),
            is_short: parseFloat(record.percentage) < minimumPercentage
        }));
        
        res.json(summary);
    });
});