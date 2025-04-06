import 'package:flutter/material.dart';
import '/config/api_config.dart';
import '../services/user_service.dart';
import '/screens/update_show_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<dynamic> favoriteShows = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => isLoading = true);
    try {
      final favorites = await UserService.getFavorites();
      setState(() {
        favoriteShows = favorites;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: $e")),
      );
    }
  }

  Future<void> _removeFavorite(Map<String, dynamic> show) async {
    try {
      await UserService.toggleFavorite(show);
      _loadFavorites();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${show['title']} retiré des favoris")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: $e")),
      );
    }
  }

  Future<void> _navigateToUpdateShow(Map<String, dynamic> show) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UpdateShowPage(show: show)),
    );
    
    if (result == true) {
      _loadFavorites();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes Favoris"),
        backgroundColor: Colors.blueAccent,
      ),
      body: RefreshIndicator(
        onRefresh: _loadFavorites,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : favoriteShows.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          "Aucun favori",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text("Retour à l'accueil"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: favoriteShows.length,
                    itemBuilder: (context, index) {
                      final show = favoriteShows[index];
                      return Dismissible(
                        key: Key(show['id'].toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.centerRight,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _removeFavorite(show),
                        confirmDismiss: (_) async => true,
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                ApiConfig.baseUrl + (show['image'] ?? ''),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 50,
                                  height: 50,
                                  color: _getCategoryColor(show['category']),
                                  child: Center(
                                    child: Text(
                                      show['title'][0],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              show['title'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              show['description'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.favorite, color: Colors.red),
                              onPressed: () => _removeFavorite(show),
                            ),
                            onTap: () => _navigateToUpdateShow(show),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'movie':
        return Colors.redAccent;
      case 'anime':
        return Colors.purpleAccent;
      case 'serie':
        return Colors.greenAccent;
      default:
        return Colors.blueGrey;
    }
  }
}