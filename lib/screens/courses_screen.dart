import 'package:flutter/material.dart';

import '../models/course_model.dart';
import '../services/course_service.dart';
import 'course_form_screen.dart';

/// Courses screen — the home of all CRUD operations.
///
/// * READ:   fetches courses from the API with loading + error handling.
/// * CREATE: opens the form, then inserts the returned course into the list.
/// * UPDATE: opens the pre-filled form, then replaces the course in the list.
/// * DELETE: confirms, calls the API, then removes the course from the list.
class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final CourseService _service = CourseService();

  bool _loading = true;
  String? _error;
  List<Course> _courses = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  // READ

  Future<void> _loadCourses() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final courses = await _service.fetchCourses();
      if (!mounted) return;
      setState(() {
        _courses = courses;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  // CREATE 

  Future<void> _addCourse() async {
    final created = await Navigator.push<Course>(
      context,
      MaterialPageRoute(builder: (_) => const CourseFormScreen()),
    );

    if (created != null) {
      setState(() => _courses.insert(0, created));
      _toast("Course added successfully", const Color(0xFF22C55E));
    }
  }

  // UPDATE

  Future<void> _editCourse(Course course) async {
    final updated = await Navigator.push<Course>(
      context,
      MaterialPageRoute(builder: (_) => CourseFormScreen(course: course)),
    );

    if (updated != null) {
      final index = _courses.indexWhere((c) => c.id == updated.id);
      setState(() {
        if (index != -1) {
          _courses[index] = updated;
        } else {
          _courses.insert(0, updated);
        }
      });
      _toast("Course updated successfully", const Color(0xFF22C55E));
    }
  }

  // DELETE

  Future<void> _confirmDelete(Course course) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF1E293B)),
        ),
        title: const Text(
          "Delete course?",
          style: TextStyle(
            color: Color(0xFFF8FAFC),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Text(
          'This will remove "${course.title}". This action cannot be undone.',
          style: const TextStyle(color: Color(0xFF94A3B8), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Delete",
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _deleteCourse(course);
    }
  }

  Future<void> _deleteCourse(Course course) async {
    try {
      await _service.deleteCourse(course.id);
      if (!mounted) return;
      setState(() => _courses.removeWhere((c) => c.id == course.id));
      _toast("Course deleted", const Color(0xFF22C55E));
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(e.message, const Color(0xFFEF4444));
    }
  }

  // Helpers

  void _toast(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // UI 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: const Color(0xFF020617),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: const Icon(
              Icons.arrow_back_ios,
              color: Color(0xFFF8FAFC),
              size: 16,
            ),
          ),
        ),
        title: const Text(
          "Courses",
          style: TextStyle(
            color: Color(0xFFF8FAFC),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_loading && _error == null)
            IconButton(
              tooltip: "Refresh",
              onPressed: _loadCourses,
              icon: const Icon(Icons.refresh, color: Color(0xFF94A3B8)),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCourse,
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add Course",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) return _buildLoading();
    if (_error != null) return _buildError();
    if (_courses.isEmpty) return _buildEmpty();
    return _buildList();
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFF6366F1)),
          SizedBox(height: 16),
          Text(
            "Loading courses...",
            style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off,
                color: Color(0xFFEF4444),
                size: 30,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "Couldn't load courses",
              style: TextStyle(
                color: Color(0xFFF8FAFC),
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? "Unknown error",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF94A3B8), height: 1.5),
            ),
            const SizedBox(height: 22),
            OutlinedButton.icon(
              onPressed: _loadCourses,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6366F1),
                side: const BorderSide(color: Color(0xFF6366F1)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text("Try Again"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox, color: Color(0xFF475569), size: 56),
            const SizedBox(height: 14),
            const Text(
              "No courses yet",
              style: TextStyle(
                color: Color(0xFFF8FAFC),
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Tap “Add Course” to create your first one.",
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      color: const Color(0xFF6366F1),
      backgroundColor: const Color(0xFF0F172A),
      onRefresh: _loadCourses,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        itemCount: _courses.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _courseCard(_courses[i]),
      ),
    );
  }

  Widget _courseCard(Course course) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withAlpha(30),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.menu_book,
                  color: Color(0xFF6366F1),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: const TextStyle(
                        color: Color(0xFFF8FAFC),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "ID #${course.id}",
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            course.description,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFF1E293B), height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _editCourse(course),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF06B6D4),
                ),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text("Edit"),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: () => _confirmDelete(course),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                ),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text("Delete"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
