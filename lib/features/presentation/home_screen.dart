import 'package:flutter/material.dart';
import 'package:ui_testing/core/services/api_service.dart';
import 'package:ui_testing/features/data/model/student.dart';
import 'package:ui_testing/widgets/app_theme.dart';
import 'package:ui_testing/widgets/widgets.dart';

import 'student_detail_screen.dart';
import 'student_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Student> _students = [];
  List<Student> _filtered = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterStatus = 'All'; // All, Active, Inactive

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    final res = await ApiService.getStudents();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (res.isSuccess) {
        _students = res.data ?? [];
        _applyFilter();
      } else {
        SnackBarHelper.showError(context, res.error ?? 'Failed to load');
      }
    });
  }

  void _applyFilter() {
    setState(() {
      _filtered = _students.where((s) {
        final matchSearch =
            s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            s.studentId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            s.course.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            s.city.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchStatus =
            _filterStatus == 'All' ||
            (_filterStatus == 'Active' && s.isActive) ||
            (_filterStatus == 'Inactive' && !s.isActive);
        return matchSearch && matchStatus;
      }).toList();
    });
  }

  int get _activeCount => _students.where((s) => s.isActive).length;
  double get _avgCgpa => _students.isEmpty
      ? 0.0
      : _students.map((s) => s.cgpa).reduce((a, b) => a + b) / _students.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadStudents,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const StudentFormScreen()),
          );
          if (result == true) _loadStudents();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Student',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadStudents,
        color: AppTheme.accent,
        backgroundColor: AppTheme.card,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.accent),
              )
            : CustomScrollView(
                slivers: [
                  // Stats Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _StatsRow(
                            total: _students.length,
                            active: _activeCount,
                            avgCgpa: _avgCgpa,
                          ),
                          const SizedBox(height: 20),
                          // Search Field
                          TextField(
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                            ),
                            onChanged: (v) {
                              _searchQuery = v;
                              _applyFilter();
                            },
                            decoration: InputDecoration(
                              hintText: 'Search by name, ID, course, city...',
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: AppTheme.textSecondary,
                                size: 20,
                              ),
                              filled: true,
                              fillColor: AppTheme.surface,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppTheme.accent.withOpacity(0.2),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppTheme.accent,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Filter Chips
                          Row(
                            children: ['All', 'Active', 'Inactive']
                                .map(
                                  (f) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: _FilterChip(
                                      label: f,
                                      isSelected: _filterStatus == f,
                                      onTap: () {
                                        _filterStatus = f;
                                        _applyFilter();
                                      },
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${_filtered.length} result${_filtered.length != 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),

                  // Student List
                  if (_filtered.isEmpty)
                    SliverFillRemaining(
                      child: _EmptyState(
                        hasSearch: _searchQuery.isNotEmpty,
                        onAdd: () async {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const StudentFormScreen(),
                            ),
                          );
                          if (result == true) _loadStudents();
                        },
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _StudentCard(
                              student: _filtered[i],
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StudentDetailScreen(
                                      student: _filtered[i],
                                      onRefresh: _loadStudents,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          childCount: _filtered.length,
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

// ─── Sub-widgets ────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int total;
  final int active;
  final double avgCgpa;

  const _StatsRow({
    required this.total,
    required this.active,
    required this.avgCgpa,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatItem(
          value: total.toString(),
          label: 'Total',
          color: AppTheme.accent,
        ),
        const SizedBox(width: 10),
        _StatItem(
          value: active.toString(),
          label: 'Active',
          color: AppTheme.accentGreen,
        ),
        const SizedBox(width: 10),
        _StatItem(
          value: avgCgpa.toStringAsFixed(2),
          label: 'Avg CGPA',
          color: AppTheme.warning,
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accent.withOpacity(0.2)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.accent
                : AppTheme.accent.withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.accent : AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final Student student;
  final VoidCallback onTap;

  const _StudentCard({required this.student, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cgpaColor = student.cgpa >= 3.5
        ? AppTheme.success
        : student.cgpa >= 2.5
        ? AppTheme.warning
        : AppTheme.error;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: student.isActive
                ? AppTheme.accent.withOpacity(0.2)
                : AppTheme.textSecondary.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          student.name,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!student.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Inactive',
                            style: TextStyle(
                              color: AppTheme.error,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${student.studentId} · ${student.course}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${student.city} · Sem ${student.semester}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // CGPA Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  student.cgpa.toStringAsFixed(2),
                  style: TextStyle(
                    color: cgpaColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'CGPA',
                  style: TextStyle(
                    color: cgpaColor.withOpacity(0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onAdd;

  const _EmptyState({required this.hasSearch, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasSearch ? Icons.search_off_rounded : Icons.school_outlined,
            color: AppTheme.textSecondary,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            hasSearch ? 'No results found' : 'No students yet',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearch
                ? 'Try a different search term'
                : 'Tap the button below to add your first student',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          if (!hasSearch) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Student'),
            ),
          ],
        ],
      ),
    );
  }
}
