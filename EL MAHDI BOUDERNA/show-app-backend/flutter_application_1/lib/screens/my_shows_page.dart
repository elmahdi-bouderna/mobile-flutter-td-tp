import 'package:flutter/material.dart';
import '/config/api_config.dart';
import '../services/user_service.dart';
import '/screens/update_show_page.dart';
import '/screens/add_show_page.dart';

class MyShowsPage extends StatefulWidget {
  const MyShowsPage({super.key});

  @override
  _MyShowsPageState createState() => _MyShowsPageState();
}

class _MyShowsPageState extends State<MyShowsPage> {
  List<dynamic> myShows = [];
  bool isLoading = true;
  Map<int, bool> favorites = {};

  @override
  void initState() {
    super.initState();
    _loadMyShows();
  }

  Future<void> _loadMyShows() async {
    setState(() => isLoading = true);
    try {
      final shows = await UserService.getMyShows();
      final Map<int, bool> favMap = {};
      
      // Vérifier quels shows sont des favoris
      for (var show in shows) {
        final isFav = await UserService.isFavorite(show['id']);
        favMap[show['id']] = isFav;
      }
      
      setState(() {
        myShows = shows;
        favorites = favMap;
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

  Future<void> _toggleFavorite(Map<String, dynamic> show) async {
    try {
      await UserService.toggleFavorite(show);
      final isFav = await UserService.isFavorite(show['id']);
      setState(() {
        favorites[show['id']] = isFav;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFav
                ? "${show['title']} ajouté aux favoris"
                : "${show['title']} retiré des favoris"
          ),
        ),
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
      _loadMyShows();
    }
  }

  Future<void> _navigateToAddShow() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddShowPage()),
    );
    
    if (result == true) {
      _loadMyShows();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes Shows"),
        backgroundColor: Colors.blueAccent,
      ),
      body: RefreshIndicator(
        onRefresh: _loadMyShows,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : myShows.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.movie_filter, size: 80, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          "Vous n'avez pas encore de shows",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _navigateToAddShow,
                          icon: const Icon(Icons.add),
                          label: const Text("Ajouter un show"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: myShows.length,
                    itemBuilder: (context, index) {
                      final show = myShows[index];
                      final isFavorite = favorites[show['id']] ?? false;
                      
                      return Card(
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: isFavorite ? Colors.red : null,
                                ),
                                onPressed: () => _toggleFavorite(show),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _navigateToUpdateShow(show),
                              ),
                            ],
                          ),
                          onTap: () => _navigateToUpdateShow(show),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddShow,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
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