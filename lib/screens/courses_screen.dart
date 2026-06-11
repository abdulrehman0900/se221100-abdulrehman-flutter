import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course_model.dart';
import '../providers/course_provider.dart';
import '../utils/enums.dart';
import 'course_form_screen.dart';

/// Courses screen — the home of all CRUD operations.
///
/// This screen is intentionally "dumb": it only renders state and forwards
/// user intent to [CourseProvider]. All data loading, caching, offline
/// fallback and optimistic updates live in the provider/repository layers.
class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Kick off the first load after the first frame so notifyListeners()
    // never fires during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CourseProvider>().loadCourses();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // CREATE

  Future<void> _addCourse() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CourseFormScreen()),
    );
    if (added == true && mounted) {
      _toast("Course added successfully", const Color(0xFF22C55E));
    }
  }

  // UPDATE

  Future<void> _editCourse(Course course) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CourseFormScreen(course: course)),
    );
    if (updated == true && mounted) {
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
    // Optimistic: the provider removes the row immediately and only tells us
    // here if the API rejected it (in which case it has already rolled back).
    final error = await context.read<CourseProvider>().deleteCourse(course);
    if (!mounted) return;
    if (error == null) {
      _toast("Course deleted", const Color(0xFF22C55E));
    } else {
      _toast(error, const Color(0xFFEF4444));
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
    final provider = context.watch<CourseProvider>();

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
          if (provider.state != ViewState.loading)
            IconButton(
              tooltip: "Refresh",
              onPressed: provider.refresh,
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
      body: SafeArea(child: _buildBody(provider)),
    );
  }

  Widget _buildBody(CourseProvider provider) {
    switch (provider.state) {
      case ViewState.loading:
        return _buildLoading();
      case ViewState.error:
        return _buildError(provider);
      case ViewState.empty:
        return _buildEmpty();
      case ViewState.success:
        return _buildContent(provider);
    }
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

  Widget _buildError(CourseProvider provider) {
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
              provider.error ?? "Unknown error",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF94A3B8), height: 1.5),
            ),
            const SizedBox(height: 22),
            OutlinedButton.icon(
              onPressed: provider.refresh,
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

  Widget _buildContent(CourseProvider provider) {
    final courses = provider.courses;

    return Column(
      children: [
        if (provider.isOffline) _offlineBanner(),
        _searchField(provider),
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFF6366F1),
            backgroundColor: const Color(0xFF0F172A),
            onRefresh: provider.refresh,
            child: courses.isEmpty
                ? _buildNoResults()
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                    itemCount: courses.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _courseCard(courses[i]),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _offlineBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withAlpha(28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B).withAlpha(90)),
      ),
      child: const Row(
        children: [
          Icon(Icons.wifi_off, color: Color(0xFFF59E0B), size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "You're offline — showing saved courses.",
              style: TextStyle(color: Color(0xFFFCD34D), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField(CourseProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: TextField(
        controller: _searchController,
        onChanged: provider.search,
        style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 14),
        decoration: InputDecoration(
          hintText: "Search courses...",
          hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
          suffixIcon: provider.query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 18),
                  onPressed: () {
                    _searchController.clear();
                    provider.clearSearch();
                  },
                ),
          isDense: true,
          filled: true,
          fillColor: const Color(0xFF0F172A),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF1E293B)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF1E293B)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    // Scrollable so pull-to-refresh still works when there are no matches.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        const Icon(Icons.search_off, color: Color(0xFF475569), size: 52),
        const SizedBox(height: 14),
        const Center(
          child: Text(
            "No matching courses",
            style: TextStyle(
              color: Color(0xFFF8FAFC),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Center(
          child: Text(
            "Try a different search term.",
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
        ),
      ],
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
