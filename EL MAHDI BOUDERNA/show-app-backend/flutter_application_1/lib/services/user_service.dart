import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'package:http/http.dart' as http;

class UserService {
  // Clés pour le stockage local
  static const String _userKey = 'user_data';
  static const String _favoritesKey = 'favorite_shows';
  static const String _myShowsKey = 'my_shows';
  
  // Données utilisateur par défaut
  static final Map<String, dynamic> _defaultUser = {
    'name': 'John Doe',
    'email': 'johndoe@email.com',
    'avatar': 'https://i.pravatar.cc/300',
  };

  // Récupérer les données utilisateur
  static Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString(_userKey);
    
    if (userData != null) {
      return json.decode(userData);
    }
    
    // Si aucune donnée n'existe, retourne les données par défaut
    await prefs.setString(_userKey, json.encode(_defaultUser));
    return _defaultUser;
  }

  // Mettre à jour les données utilisateur
  static Future<bool> updateUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, json.encode(userData));
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour des données utilisateur: $e');
      return false;
    }
  }

  // Récupérer les favoris
  static Future<List<dynamic>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? favoritesData = prefs.getString(_favoritesKey);
    
    if (favoritesData != null) {
      return json.decode(favoritesData);
    }
    return [];
  }

  // Ajouter ou supprimer des favoris
  static Future<bool> toggleFavorite(Map<String, dynamic> show) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = await getFavorites();
      
      // Vérifier si le show est déjà dans les favoris
      final index = favorites.indexWhere((fav) => fav['id'] == show['id']);
      
      if (index >= 0) {
        // Supprimer des favoris
        favorites.removeAt(index);
      } else {
        // Ajouter aux favoris
        favorites.add(show);
      }
      
      await prefs.setString(_favoritesKey, json.encode(favorites));
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la gestion des favoris: $e');
      return false;
    }
  }

  // Vérifier si un show est dans les favoris
  static Future<bool> isFavorite(int showId) async {
    final favorites = await getFavorites();
    return favorites.any((fav) => fav['id'] == showId);
  }

  // Récupérer les shows ajoutés par l'utilisateur
  static Future<List<dynamic>> getMyShows() async {
    try {
      // Dans une vraie application, on ferait une requête API
      // Ici, on simule avec un stockage local
      final prefs = await SharedPreferences.getInstance();
      final String? myShowsData = prefs.getString(_myShowsKey);
      
      if (myShowsData != null) {
        return json.decode(myShowsData);
      }
      
      // Si aucun show n'existe localement, on peut essayer de récupérer
      // depuis l'API (si l'API permet de filtrer par utilisateur)
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/shows'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(ApiConfig.timeoutDuration);

      if (response.statusCode == 200) {
        final allShows = json.decode(response.body);
        // Simuler que les 2 premiers shows sont ceux de l'utilisateur
        final myShows = allShows.take(2).toList();
        await prefs.setString(_myShowsKey, json.encode(myShows));
        return myShows;
      }
      
      return [];
    } catch (e) {
      debugPrint('Erreur lors de la récupération de mes shows: $e');
      return [];
    }
  }

  // Déconnexion (effacer les données de session)
  static Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Dans une vraie application avec authentification,
      // vous appelleriez également une API pour invalider le token
      await prefs.remove(_userKey);
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la déconnexion: $e');
      return false;
    }
  }
}