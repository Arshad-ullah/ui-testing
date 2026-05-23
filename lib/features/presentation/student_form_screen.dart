import 'package:flutter/material.dart';
import 'package:ui_testing/core/services/api_service.dart';
import 'package:ui_testing/features/data/model/student.dart';
import 'package:ui_testing/widgets/app_theme.dart';
import 'package:ui_testing/widgets/widgets.dart';

class StudentFormScreen extends StatefulWidget {
  final Student? student; // null = create, non-null = edit

  const StudentFormScreen({super.key, this.student});

  @override
  State<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends State<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isActive = true;

  late final TextEditingController _studentIdCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _gradeCtrl;
  late final TextEditingController _courseCtrl;
  late final TextEditingController _semesterCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _cgpaCtrl;

  String _selectedGender = 'Male';
  final List<String> _genders = ['Male', 'Female', 'Other'];

  bool get _isEdit => widget.student != null;

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    _studentIdCtrl = TextEditingController(text: s?.studentId ?? '');
    _nameCtrl = TextEditingController(text: s?.name ?? '');
    _ageCtrl = TextEditingController(text: s?.age.toString() ?? '');
    _gradeCtrl = TextEditingController(text: s?.grade ?? '');
    _courseCtrl = TextEditingController(text: s?.course ?? '');
    _semesterCtrl = TextEditingController(text: s?.semester.toString() ?? '');
    _cityCtrl = TextEditingController(text: s?.city ?? '');
    _emailCtrl = TextEditingController(text: s?.email ?? '');
    _phoneCtrl = TextEditingController(text: s?.phone ?? '');
    _cgpaCtrl = TextEditingController(text: s?.cgpa.toString() ?? '');
    if (s != null) {
      _selectedGender = s.gender;
      _isActive = s.isActive;
    }
  }

  @override
  void dispose() {
    _studentIdCtrl.dispose();
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _gradeCtrl.dispose();
    _courseCtrl.dispose();
    _semesterCtrl.dispose();
    _cityCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _cgpaCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final student = Student(
      studentId: _studentIdCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      age: int.parse(_ageCtrl.text.trim()),
      gender: _selectedGender,
      grade: _gradeCtrl.text.trim(),
      course: _courseCtrl.text.trim(),
      semester: int.parse(_semesterCtrl.text.trim()),
      city: _cityCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      cgpa: double.parse(_cgpaCtrl.text.trim()),
      isActive: _isActive,
    );

    if (_isEdit) {
      final res = await ApiService.updateStudent(
        widget.student!.studentId,
        student,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (res.isSuccess) {
        SnackBarHelper.showSuccess(context, 'Student updated successfully!');
        Navigator.pop(context, true);
      } else {
        SnackBarHelper.showError(context, res.error ?? 'Update failed');
      }
    } else {
      final res = await ApiService.createStudent(student);
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (res.isSuccess) {
        SnackBarHelper.showSuccess(context, 'Student created successfully!');
        Navigator.pop(context, true);
      } else {
        SnackBarHelper.showError(context, res.error ?? 'Create failed');
      }
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _validateCgpa(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final d = double.tryParse(v.trim());
    if (d == null) return 'Must be a number';
    if (d < 0 || d > 4.0) return 'CGPA must be 0 – 4.0';
    return null;
  }

  String? _validateAge(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final i = int.tryParse(v.trim());
    if (i == null) return 'Must be a number';
    if (i < 1 || i > 100) return 'Enter a valid age';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(v.trim())) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validateSemester(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final i = int.tryParse(v.trim());
    if (i == null || i < 1 || i > 8) return 'Semester must be 1 – 8';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEdit ? 'Edit Student' : 'New Student'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header Banner
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accent.withOpacity(0.15),
                      AppTheme.accentGreen.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _isEdit ? Icons.edit_rounded : Icons.person_add_rounded,
                        color: AppTheme.accent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEdit ? 'Update Record' : 'Register Student',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _isEdit
                              ? 'Modify student information'
                              : 'Fill all required fields',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Identity Section
              const SectionTitle('IDENTITY'),
              StyledTextField(
                controller: _studentIdCtrl,
                label: 'Student ID',
                hint: 'e.g. STU-001',
                enabled: !_isEdit,
                validator: _required,
              ),
              const SizedBox(height: 14),
              StyledTextField(
                controller: _nameCtrl,
                label: 'Full Name',
                hint: 'e.g. Ahmed Khan',
                validator: _required,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: StyledTextField(
                      controller: _ageCtrl,
                      label: 'Age',
                      keyboardType: TextInputType.number,
                      validator: _validateAge,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedGender,
                      dropdownColor: AppTheme.card,
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                      decoration: const InputDecoration(labelText: 'Gender'),
                      items: _genders
                          .map(
                            (g) => DropdownMenuItem(
                              value: g,
                              child: Text(
                                g,
                                style: const TextStyle(color: Colors.black),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedGender = v ?? 'Male'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Academic Section
              const SectionTitle('ACADEMIC'),
              Row(
                children: [
                  Expanded(
                    child: StyledTextField(
                      controller: _gradeCtrl,
                      label: 'Grade',
                      hint: 'e.g. A',
                      validator: _required,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: StyledTextField(
                      controller: _cgpaCtrl,
                      label: 'CGPA',
                      hint: '0.0 – 4.0',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: _validateCgpa,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              StyledTextField(
                controller: _courseCtrl,
                label: 'Course',
                hint: 'e.g. Computer Science',
                validator: _required,
              ),
              const SizedBox(height: 14),
              StyledTextField(
                controller: _semesterCtrl,
                label: 'Semester',
                hint: '1 – 8',
                keyboardType: TextInputType.number,
                validator: _validateSemester,
              ),
              const SizedBox(height: 24),

              // Contact Section
              const SectionTitle('CONTACT'),
              StyledTextField(
                controller: _emailCtrl,
                label: 'Email',
                hint: 'student@university.edu',
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              const SizedBox(height: 14),
              StyledTextField(
                controller: _phoneCtrl,
                label: 'Phone',
                hint: '+92 300 0000000',
                keyboardType: TextInputType.phone,
                validator: _required,
              ),
              const SizedBox(height: 14),
              StyledTextField(
                controller: _cityCtrl,
                label: 'City',
                hint: 'e.g. Peshawar',
                validator: _required,
              ),
              const SizedBox(height: 24),

              // Status Section
              const SectionTitle('STATUS'),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Active Student',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                  ),
                  subtitle: Text(
                    _isActive ? 'Currently enrolled' : 'Inactive / Alumni',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  value: _isActive,
                  activeColor: AppTheme.accentGreen,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: Icon(_isEdit ? Icons.save_rounded : Icons.add_rounded),
                  label: Text(_isEdit ? 'Save Changes' : 'Create Student'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
