import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:ui_testing/core/services/api_service.dart';
import 'package:ui_testing/features/data/model/student.dart';
import 'package:ui_testing/widgets/app_theme.dart';
import 'package:ui_testing/widgets/widgets.dart';

import 'student_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Student> _students = [];
  bool _isLoading = false;
  String _query = '';
  Timer? _debounceTimer;

  Future<void> _searchStudents() async {
    if (_query.trim().isEmpty) return;

    setState(() => _isLoading = true);

    final res = await ApiService.searchStudent(_query);

    if (!mounted) return;

    setState(() {
      _isLoading = false;

      if (res.isSuccess) {
        _students = res.data ?? [];
      } else {
        SnackBarHelper.showError(
          context,
          res.error ?? 'Failed to search students',
        );
      }
    });
  }

  void _onSearchChanged(String value) {
    _query = value;

    _debounceTimer?.cancel();

    if (value.trim().isEmpty) {
      setState(() => _students = []);
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchStudents();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Students')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppTheme.textPrimary),
              onChanged: _onSearchChanged,
              onSubmitted: (_) {
                log('Search submitted: $_query');
                _debounceTimer?.cancel();
                _searchStudents();
              },
              decoration: InputDecoration(
                hintText: 'Search by name, ID, course...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppTheme.textSecondary,
                ),
                suffixIcon: IconButton(
                  onPressed: () {
                    _debounceTimer?.cancel();
                    _searchStudents();
                  },
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
                filled: true,
                fillColor: AppTheme.surface,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: AppTheme.accent.withOpacity(0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.accent),
                ),
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.accent),
                  )
                : _students.isEmpty
                ? const _EmptySearchState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: _students.length,
                    itemBuilder: (context, index) {
                      final student = _students[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SearchStudentCard(
                          student: student,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StudentDetailScreen(
                                  student: student,
                                  onRefresh: () {},
                                ),
                              ),
                            );
                          },
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

class _SearchStudentCard extends StatelessWidget {
  final Student student;
  final VoidCallback onTap;

  const _SearchStudentCard({required this.student, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.accent.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    student.studentId,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    student.course,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppTheme.textSecondary.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: AppTheme.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            'Search students',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Search students from API',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
