import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  Future<Map<String, dynamic>> registerUser(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to register user: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> loginUser(Map<String, dynamic> loginData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(loginData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to login user: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getUserProfile(int userId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch user profile: ${response.statusCode} - ${response.body}');
    }
  }


  // Metodo per verificare se l'utente è un medico
  Future<bool> isUserDoctor(int userId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/$userId/role'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['isDoctor'] ?? false; // Restituisci true se è un medico, altrimenti false
    } else {
      throw Exception('Failed to check user role: ${response.statusCode} - ${response.body}');
    }
  }

  Future<List<String>> getDoctorSpecializations(int userId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId/specializations'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['specializations']); // Assicurati che la risposta contenga la lista delle specializzazioni
    } else {
      throw Exception('Failed to fetch specializations: ${response.statusCode} - ${response.body}');
    }
  }
  Future<List<Map<String, dynamic>>> getDoctors(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/discovery'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['doctors']);
    } else {
      throw Exception('Failed to fetch doctors: ${response.statusCode} - ${response.body}');
    }
  }
  Future<List<Map<String, dynamic>>> getDoctorAvailability(int userId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/calendar/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['availability']);
    } else {
      throw Exception('Failed to fetch availability: ${response.statusCode} - ${response.body}');
    }
  }
}
