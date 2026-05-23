import 'package:flutter/material.dart';
import 'package:ui_testing/core/services/api_service.dart';
import 'package:ui_testing/features/data/model/student.dart';
import 'package:ui_testing/widgets/app_theme.dart';
import 'package:ui_testing/widgets/widgets.dart';

import 'student_form_screen.dart';

class StudentDetailScreen extends StatelessWidget {
  final Student student;
  final VoidCallback onRefresh;

  const StudentDetailScreen({
    super.key,
    required this.student,
    required this.onRefresh,
  });

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Student?',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will permanently remove ${student.name} from the system.',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'ID: ${student.studentId}',
              style: const TextStyle(
                color: AppTheme.accent,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final res = await ApiService.deleteStudent(student.studentId);
    if (!context.mounted) return;

    if (res.isSuccess) {
      SnackBarHelper.showSuccess(context, 'Student deleted successfully');
      onRefresh();
      Navigator.pop(context);
    } else {
      SnackBarHelper.showError(context, res.error ?? 'Delete failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cgpaColor = student.cgpa >= 3.5
        ? AppTheme.success
        : student.cgpa >= 2.5
        ? AppTheme.warning
        : AppTheme.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Detail'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: AppTheme.accent),
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentFormScreen(student: student),
                ),
              );
              if (result == true) {
                onRefresh();
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded, color: AppTheme.error),
            onPressed: () => _confirmDelete(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.card, AppTheme.accent.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.accent.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        student.name.isNotEmpty
                            ? student.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    student.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    student.studentId,
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Chip(label: student.course, color: AppTheme.accent),
                      const SizedBox(width: 8),
                      _Chip(
                        label: student.isActive ? 'Active' : 'Inactive',
                        color: student.isActive
                            ? AppTheme.success
                            : AppTheme.error,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stats Row
            Row(
              children: [
                _StatCard(
                  label: 'CGPA',
                  value: student.cgpa.toStringAsFixed(2),
                  color: cgpaColor,
                  icon: Icons.bar_chart_rounded,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Grade',
                  value: student.grade,
                  color: AppTheme.accent,
                  icon: Icons.grade_rounded,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Semester',
                  value: 'Sem ${student.semester}',
                  color: AppTheme.warning,
                  icon: Icons.school_rounded,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Personal Info
            _InfoCard(
              title: 'PERSONAL INFO',
              children: [
                InfoRow(label: 'Age', value: '${student.age} years'),
                InfoRow(label: 'Gender', value: student.gender),
                InfoRow(label: 'City', value: student.city),
              ],
            ),
            const SizedBox(height: 14),

            // Contact Info
            _InfoCard(
              title: 'CONTACT',
              children: [
                InfoRow(label: 'Email', value: student.email),
                InfoRow(label: 'Phone', value: student.phone),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accent.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [SectionTitle(title), ...children],
      ),
    );
  }
}
