class Student {
  final String? id;
  final String studentId;
  final String name;
  final int age;
  final String gender;
  final String grade;
  final String course;
  final int semester;
  final String city;
  final String email;
  final String phone;
  final double cgpa;
  final bool isActive;

  Student({
    this.id,
    required this.studentId,
    required this.name,
    required this.age,
    required this.gender,
    required this.grade,
    required this.course,
    required this.semester,
    required this.city,
    required this.email,
    required this.phone,
    required this.cgpa,
    this.isActive = true,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['_id']?.toString(),
      studentId: json['studentId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      age: int.tryParse(json['age'].toString()) ?? 0,
      gender: json['gender']?.toString() ?? '',
      grade: json['grade']?.toString() ?? '',
      course: json['course']?.toString() ?? '',
      semester: int.tryParse(json['semester'].toString()) ?? 1,
      city: json['city']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      cgpa: double.tryParse(json['cgpa'].toString()) ?? 0.0,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'name': name,
      'age': age,
      'gender': gender,
      'grade': grade,
      'course': course,
      'semester': semester,
      'city': city,
      'email': email,
      'phone': phone,
      'cgpa': cgpa,
      'isActive': isActive,
    };
  }

  Student copyWith({
    String? id,
    String? studentId,
    String? name,
    int? age,
    String? gender,
    String? grade,
    String? course,
    int? semester,
    String? city,
    String? email,
    String? phone,
    double? cgpa,
    bool? isActive,
  }) {
    return Student(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      grade: grade ?? this.grade,
      course: course ?? this.course,
      semester: semester ?? this.semester,
      city: city ?? this.city,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      cgpa: cgpa ?? this.cgpa,
      isActive: isActive ?? this.isActive,
    );
  }
}
