// lib/pages/profile_page.dart
import 'package:flutter/material.dart';
import '../services/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  final int userId;
  final String token; // Aggiungi questo campo

  const ProfilePage({
    Key? key,
    required this.userId,
    required this.token, // Assicurati che il token sia richiesto
  }) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late ApiService apiService;
  Map<String, dynamic>? userProfile;
  String message = '';

  @override
  void initState() {
    super.initState();
    apiService = ApiService(baseUrl: 'http://10.0.2.2:3000');
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    // Usa il token passato dalla pagina di login
    String token = widget.token;
    int userId = widget.userId; // Usa l'ID utente passato dalla pagina di login

    if (token.isNotEmpty) {
      try {
        final profileData = await apiService.getUserProfile(userId, token);
        setState(() {
          userProfile = profileData;
        });
      } catch (e) {
        setState(() {
          message = 'Failed to load user profile: $e';
        });
      }
    } else {
      setState(() {
        message = 'No token found, please login again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: userProfile == null
            ? Text(message)
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('User ID: ${userProfile!['userData']['id']}'),
            Text('Email: ${userProfile!['userData']['email']}'),
            Text('First Name: ${userProfile!['userData']['first_name'] ?? 'N/A'}'),
            Text('Last Name: ${userProfile!['userData']['last_name'] ?? 'N/A'}'),
            // Mostra altri dati dell'utente se necessario
          ],
        ),
      ),
    );
  }
}
