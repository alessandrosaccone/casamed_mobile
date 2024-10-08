// lib/services/api_service.dart
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

  Future<Map<String, dynamic>> fetchCounter() async {
    final url = Uri.parse('$baseUrl/counter');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch counter: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> incrementCounter() async {
    final url = Uri.parse('$baseUrl/increment');
    final response = await http.post(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to increment counter: ${response.statusCode} - ${response.body}');
    }
  }

  // Metodo per verificare se l'utente è un medico
  Future<bool> isUserDoctor(int userId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/$userId/role'), // Assicurati che l'endpoint sia corretto
      headers: {
        'Authorization': 'Bearer $token', // Usa il token di autorizzazione
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['isDoctor'] ?? false; // Restituisci true se è un medico, altrimenti false
    } else {
      throw Exception('Failed to check user role: ${response.statusCode} - ${response.body}');
    }
  }
}
