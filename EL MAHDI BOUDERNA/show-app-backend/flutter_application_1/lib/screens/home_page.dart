import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '/screens/add_show_page.dart';
import '/screens/profile_page.dart';
import '/screens/update_show_page.dart';
import '/screens/debug_page.dart';
import '/services/user_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  List<dynamic> movies = [];
  List<dynamic> anime = [];
  List<dynamic> series = [];
  bool isLoading = true;
  bool isError = false;
  String errorMessage = "";
  int retryCount = 0;
  bool useTestData = false;
  Map<int, bool> favorites = {};

  @override
  void initState() {
    super.initState();
    fetchShows();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final favs = await UserService.getFavorites();
      final Map<int, bool> favMap = {};
      for (var show in favs) {
        favMap[show['id']] = true;
      }
      setState(() {
        favorites = favMap;
      });
    } catch (e) {
      // Gérer silencieusement les erreurs lors du chargement des favoris
      debugPrint('Erreur lors du chargement des favoris: $e');
    }
  }

  Future<void> fetchShows() async {
    setState(() {
      isLoading = true;
      isError = false;
      errorMessage = "";
    });
    
    try {
      if (useTestData) {
        await Future.delayed(const Duration(seconds: 1));
        _loadTestData();
        return;
      }

      // Essayer de se connecter avec différentes configurations d'URL
      List<String> urlsToTry = [
        '${ApiConfig.baseUrl}/shows',
        'http://10.0.2.2:5000/shows',
        'http://localhost:5000/shows',
        'http://127.0.0.1:5000/shows',
      ];
      
      debugPrint("Tentative de connexion à plusieurs URLs...");
      
      bool connected = false;
      http.Response? successResponse;
      
      // Essayer chaque URL jusqu'à succès
      for (String url in urlsToTry) {
        try {
          debugPrint("Tentative: $url");
          final response = await http.get(
            Uri.parse(url),
            headers: {'Connection': 'keep-alive'},
          ).timeout(const Duration(seconds: 10));
          
          if (response.statusCode == 200) {
            debugPrint("Connexion réussie à $url");
            connected = true;
            successResponse = response;
            break;
          }
        } catch (e) {
          debugPrint("Échec pour $url: $e");
          // Continue avec l'URL suivante
        }
      }
      
      if (connected && successResponse != null) {
        List<dynamic> allShows = jsonDecode(successResponse.body);
        
        setState(() {
          movies = allShows.where((show) => show['category'] == 'movie').toList();
          anime = allShows.where((show) => show['category'] == 'anime').toList();
          series = allShows.where((show) => show['category'] == 'serie').toList();
          isLoading = false;
          retryCount = 0;
        });
        
        debugPrint("Données récupérées avec succès: ${allShows.length} shows");
        await _loadFavorites();
      } else {
        throw Exception('Échec de la connexion à toutes les URLs');
      }
    } catch (e) {
      debugPrint("Erreur finale: $e");
      setState(() {
        isLoading = false;
        isError = true;
        errorMessage = "Erreur de connexion: $e\nActivez le mode démo pour continuer.";
      });
    }
  }

  void _loadTestData() {
    // Données de test pour démonstration
    List<dynamic> testData = [
      {
        'id': 1,
        'title': 'Inception',
        'description': 'Un film sur les rêves et la réalité',
        'category': 'movie',
        'image': '/uploads/inception.jpg'
      },
      {
        'id': 2,
        'title': 'Attack on Titan',
        'description': 'L\'humanité lutte contre des titans',
        'category': 'anime',
        'image': '/uploads/aot.jpg'
      },
      {
        'id': 3,
        'title': 'Breaking Bad',
        'description': 'Un professeur de chimie devient un criminel',
        'category': 'serie',
        'image': '/uploads/breaking_bad.jpg'
      },
      {
        'id': 4,
        'title': 'The Dark Knight',
        'description': 'Batman affronte le Joker à Gotham City',
        'category': 'movie',
        'image': '/uploads/batman.jpg'
      },
      {
        'id': 5,
        'title': 'One Piece',
        'description': 'Les aventures de pirates à la recherche d\'un trésor légendaire',
        'category': 'anime',
        'image': '/uploads/onepiece.jpg'
      },
    ];

    setState(() {
      movies = testData.where((show) => show['category'] == 'movie').toList();
      anime = testData.where((show) => show['category'] == 'anime').toList();
      series = testData.where((show) => show['category'] == 'serie').toList();
      isLoading = false;
    });
  }

  void toggleTestMode() {
    setState(() {
      useTestData = !useTestData;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(useTestData 
            ? "Mode démo activé avec données de test" 
            : "Mode normal activé, tentative de connexion au serveur"
        ),
      ),
    );
    fetchShows();
  }

  Future<void> retryConnection() async {
    setState(() {
      retryCount++;
    });
    fetchShows();
  }

  Future<void> deleteShow(int id) async {
    if (useTestData) {
      // En mode test, simulons juste la suppression
      setState(() {
        movies = movies.where((show) => show['id'] != id).toList();
        anime = anime.where((show) => show['id'] != id).toList();
        series = series.where((show) => show['id'] != id).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Show supprimé avec succès (mode démo)")),
      );
      return;
    }
    
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/shows/$id'),
      ).timeout(ApiConfig.timeoutDuration);

      if (response.statusCode == 200) {
        fetchShows();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Show supprimé avec succès")),
        );
      } else {
        throw Exception('Erreur lors de la suppression');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Échec de la suppression: $e")),
      );
    }
  }

  Future<void> _toggleFavorite(Map<String, dynamic> show) async {
    try {
      await UserService.toggleFavorite(show);
      await _loadFavorites();
      
      final isFav = await UserService.isFavorite(show['id']);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFav
                ? "${show['title']} ajouté aux favoris"
                : "${show['title']} retiré des favoris"
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de gestion des favoris: $e")),
      );
    }
  }

  void confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Supprimer le show"),
        content: const Text("Êtes-vous sûr de vouloir supprimer ce show?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              deleteShow(id);
            },
            child: const Text("Oui, supprimer"),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToAddShow() async {
    final result = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => const AddShowPage())
    );
    
    if (result == true) {
      fetchShows();
    }
  }

  Future<void> _navigateToUpdateShow(Map<String, dynamic> show) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UpdateShowPage(show: show))
    );
    
    if (result == true) {
      fetchShows();
    }
  }

  Widget _getErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 20),
            const Text(
              "Erreur de connexion au serveur",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              errorMessage,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: retryConnection,
              icon: const Icon(Icons.refresh),
              label: Text("Réessayer (${retryCount + 1})"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: toggleTestMode,
              child: const Text("Utiliser des données de test"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (isError) {
      return _getErrorWidget();
    }

    switch (_selectedIndex) {
      case 0:
        return ShowList(
          shows: movies, 
          onDelete: confirmDelete,
          onEdit: _navigateToUpdateShow,
          onToggleFavorite: _toggleFavorite,
          favorites: favorites,
          isTestMode: useTestData,
        );
      case 1:
        return ShowList(
          shows: anime, 
          onDelete: confirmDelete,
          onEdit: _navigateToUpdateShow,
          onToggleFavorite: _toggleFavorite,
          favorites: favorites,
          isTestMode: useTestData,
        );
      case 2:
        return ShowList(
          shows: series, 
          onDelete: confirmDelete,
          onEdit: _navigateToUpdateShow,
          onToggleFavorite: _toggleFavorite,
          favorites: favorites,
          isTestMode: useTestData,
        );
      default:
        return const Center(child: Text("Page inconnue"));
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Show App"), 
        backgroundColor: Colors.blueAccent,
        actions: [
          if (useTestData)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "DÉMO",
                style: TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchShows,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blueAccent),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Colors.blueAccent),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Menu",
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Profil"),
              onTap: () {
                Navigator.pop(context); // Fermer le drawer
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const ProfilePage())
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text("Ajouter un Show"),
              onTap: () {
                Navigator.pop(context); // Fermer le drawer
                _navigateToAddShow();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text("Diagnostic de connexion"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const DebugPage())
                );
              },
            ),
            ListTile(
              leading: Icon(useTestData ? Icons.cloud : Icons.offline_bolt),
              title: Text(useTestData ? "Désactiver mode démo" : "Activer mode démo"),
              onTap: () {
                Navigator.pop(context);
                toggleTestMode();
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: fetchShows,
        child: _getBody(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddShow,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.movie), label: "Films"),
          BottomNavigationBarItem(icon: Icon(Icons.animation), label: "Anime"),
          BottomNavigationBarItem(icon: Icon(Icons.tv), label: "Séries"),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        onTap: _onItemTapped,
      ),
    );
  }
}

class ShowList extends StatelessWidget {
  final List<dynamic> shows;
  final Function(int) onDelete;
  final Function(Map<String, dynamic>) onEdit;
  final Function(Map<String, dynamic>) onToggleFavorite;
  final Map<int, bool> favorites;
  final bool isTestMode;

  const ShowList({
    super.key, 
    required this.shows,
    required this.onDelete,
    required this.onEdit,
    required this.onToggleFavorite,
    required this.favorites,
    this.isTestMode = false,
  });

  @override
  Widget build(BuildContext context) {
    if (shows.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.movie_filter, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              "Aucun show disponible",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddShowPage())
                );
              },
              icon: const Icon(Icons.add),
              label: const Text("Ajouter un show"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: shows.length,
      itemBuilder: (context, index) {
        final show = shows[index];
        final isFavorite = favorites[show['id']] ?? false;
        
        return Dismissible(
          key: Key(show['id'].toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerRight,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (direction) => onDelete(show['id']),
          confirmDismiss: (direction) async {
            bool? result = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Supprimer le show"),
                content: const Text("Êtes-vous sûr de vouloir supprimer ce show?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Annuler"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Oui, supprimer"),
                  ),
                ],
              ),
            );
            return result ?? false;
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: isTestMode 
                  ? Container(
                      width: 50,
                      height: 50,
                      color: _getCategoryColor(show['category']),
                      child: Center(
                        child: Text(
                          show['title'].substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  : Image.network(
                      ApiConfig.baseUrl + show['image'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                        Container(
                          width: 50,
                          height: 50,
                          color: _getCategoryColor(show['category']),
                          child: Center(
                            child: Text(
                              show['title'].substring(0, 1).toUpperCase(),
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
                style: const TextStyle(fontWeight: FontWeight.bold)
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
                    onPressed: () => onToggleFavorite(show),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Modifier'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Supprimer', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit(show);
                      } else if (value == 'delete') {
                        onDelete(show['id']);
                      }
                    },
                  ),
                ],
              ),
              onTap: () => onEdit(show),
            ),
          ),
        );
      },
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