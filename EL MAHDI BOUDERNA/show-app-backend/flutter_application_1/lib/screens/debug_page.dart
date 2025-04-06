import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  _DebugPageState createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  Map<String, String> testResults = {};
  bool isLoading = false;
  String? ipAddress;

  @override
  void initState() {
    super.initState();
    _getDeviceIp();
  }

  Future<void> _getDeviceIp() async {
    try {
      if (!kIsWeb) {
        final List<NetworkInterface> interfaces = await NetworkInterface.list(
            includeLoopback: false, type: InternetAddressType.IPv4);
        
        if (interfaces.isNotEmpty && interfaces[0].addresses.isNotEmpty) {
          setState(() {
            ipAddress = interfaces[0].addresses[0].address;
          });
        }
      } else {
        setState(() {
          ipAddress = "Non disponible sur le web";
        });
      }
    } catch (e) {
      setState(() {
        ipAddress = "Impossible de déterminer l'IP: $e";
      });
    }
  }

  Future<void> _testConnection(String url) async {
    setState(() {
      testResults[url] = "Test en cours...";
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
      
      setState(() {
        testResults[url] = "OK (${response.statusCode}) - " 
            "Taille: ${response.body.length} caractères";
      });
    } catch (e) {
      setState(() {
        testResults[url] = "ÉCHEC: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // URLs à tester
    List<String> urlsToTest = [
      'http://localhost:5000/shows',
      'http://127.0.0.1:5000/shows',
      'http://10.0.2.2:5000/shows',
      '${ApiConfig.baseUrl}/shows',
    ];

    // Si nous avons une IP, ajouter une URL avec cette IP
    if (ipAddress != null && !ipAddress!.startsWith("Impossible") && !ipAddress!.startsWith("Non disponible")) {
      urlsToTest.add('http://$ipAddress:5000/shows');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostic de Connexion'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔍 Diagnostic de Connectivité',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'IP de l\'appareil: $ipAddress',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Test de connexion aux URLs:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...urlsToTest.map((url) {
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(url),
                  subtitle: Text(testResults[url] ?? 'Non testé'),
                  trailing: IconButton(
                    icon: const Icon(Icons.play_circle_fill),
                    onPressed: () => _testConnection(url),
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: isLoading 
                  ? null 
                  : () => urlsToTest.forEach(_testConnection),
              icon: const Icon(Icons.network_check),
              label: const Text('Tester tous les chemins'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              '📋 Instructions:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Assurez-vous que le serveur est en cours d\'exécution\n'
              '2. Pour les émulateurs Android: utilisez 10.0.2.2 au lieu de localhost\n'
              '3. Pour les appareils physiques: utilisez l\'adresse IP de votre ordinateur\n'
              '4. Vérifiez que le port 5000 est accessible et non bloqué par un pare-feu',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚙️ Configuration API', 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                  ),
                  const SizedBox(height: 8),
                  Text('URL de base configurée: ${ApiConfig.baseUrl}'),
                  Text('Délai d\'attente: ${ApiConfig.timeoutDuration.inSeconds} secondes'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}