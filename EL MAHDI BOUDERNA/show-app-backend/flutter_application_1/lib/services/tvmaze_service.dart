import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class TVMazeService {
  static const String baseUrl = 'https://api.tvmaze.com';

  // Recherche de séries
  static Future<List<Map<String, dynamic>>> searchShows(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/search/shows?q=${Uri.encodeComponent(query)}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = jsonDecode(response.body);
        return results.map((result) => result['show'] as Map<String, dynamic>).toList();
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('Erreur de recherche TVMaze: $e');
      throw Exception('Échec de la recherche: $e');
    }
  }

  // Obtenir les séries populaires (par page)
  static Future<List<Map<String, dynamic>>> getShows(int page) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/shows?page=$page'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(results);
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('Erreur TVMaze shows: $e');
      throw Exception('Échec de la récupération des shows: $e');
    }
  }

  // Convertir un élément TVMaze en format pour notre BDD
  static Map<String, dynamic> convertToLocalShow(Map<String, dynamic> tvmazeItem) {
    final String title = tvmazeItem['name'] ?? 'Sans titre';
    final String description = tvmazeItem['summary'] != null 
        ? _stripHtmlTags(tvmazeItem['summary']) 
        : 'Aucune description disponible';
    
    final imageData = tvmazeItem['image'];
    final String? posterUrl = imageData != null ? (imageData['medium'] ?? imageData['original']) : null;
    
    // Détermine la catégorie
    String category;
    final genres = tvmazeItem['genres'] ?? [];
    if (genres.contains('Anime')) {
      category = 'anime';
    } else if (title.toLowerCase().contains('movie') || description.toLowerCase().contains('film')) {
      category = 'movie';
    } else {
      category = 'serie';
    }
    
    return {
      'title': title,
      'description': description,
      'category': category,
      'poster_url': posterUrl,
      'tvmaze_id': tvmazeItem['id'],
    };
  }

  // Fonction utilitaire pour supprimer les balises HTML
  static String _stripHtmlTags(String htmlString) {
    // Version très simple, à améliorer si nécessaire
    return htmlString.replaceAll(RegExp(r'<[^>]*>'), '');
  }
}