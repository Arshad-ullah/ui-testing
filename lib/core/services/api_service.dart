import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:ui_testing/features/data/model/student.dart';

class ApiService {
  // TODO: Change this to your actual backend URL
  static const String baseUrl = 'http://localhost:8000/v2';

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  // CREATE Student
  static Future<ApiResponse<Student>> createStudent(Student student) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/createStudent'),
            headers: _headers,
            body: jsonEncode(student.toJson()),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return ApiResponse.success(Student.fromJson(data['data']));
      } else {
        return ApiResponse.error(data['message'] ?? 'Failed to create student');
      }
    } catch (e) {
      return ApiResponse.error('Connection error: ${e.toString()}');
    }
  }

  // READ all Students
  static Future<ApiResponse<List<Student>>> getStudents() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/students'), headers: _headers)
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> list = data['data'];
        final students = list.map((e) => Student.fromJson(e)).toList();
        return ApiResponse.success(students);
      } else {
        return ApiResponse.error(data['message'] ?? 'Failed to fetch students');
      }
    } catch (e) {
      return ApiResponse.error('Connection error: ${e.toString()}');
    }
  }

  // UPDATE Student
  static Future<ApiResponse<Student>> updateStudent(
    String studentId,
    Student student,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/updateStudent/$studentId'),
            headers: _headers,
            body: jsonEncode(student.toJson()),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(Student.fromJson(data['data']));
      } else {
        return ApiResponse.error(data['message'] ?? 'Failed to update student');
      }
    } catch (e) {
      return ApiResponse.error('Connection error: ${e.toString()}');
    }
  }

  // DELETE Student
  static Future<ApiResponse<bool>> deleteStudent(String studentId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/students'),
            headers: _headers,
            body: jsonEncode({'studentId': studentId}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(true);
      } else {
        return ApiResponse.error(data['message'] ?? 'Failed to delete student');
      }
    } catch (e) {
      return ApiResponse.error('Connection error: ${e.toString()}');
    }
  }

  // SEARCH Student
  static Future<ApiResponse<List<Student>>> searchStudent(String search) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/searchStudent'),
            headers: _headers,
            body: jsonEncode({'search': search}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      log('Search Response: ${response.body}');

      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> list = data['data'];

        final students = list.map((e) => Student.fromJson(e)).toList();

        return ApiResponse.success(students);
      } else {
        return ApiResponse.error(
          data['message'] ?? 'Failed to search students',
        );
      }
    } catch (e) {
      return ApiResponse.error('Connection error: ${e.toString()}');
    }
  }
}

class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  ApiResponse.success(this.data) : isSuccess = true, error = null;

  ApiResponse.error(this.error) : isSuccess = false, data = null;
}
