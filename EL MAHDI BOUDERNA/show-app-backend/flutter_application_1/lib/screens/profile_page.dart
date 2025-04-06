import 'package:flutter/material.dart';
import '/screens/login_page.dart';
import '/screens/my_shows_page.dart';
import '/screens/favorites_page.dart';
import '../services/user_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 0;
  Map<String, dynamic> userData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final data = await UserService.getUserData();
      setState(() {
        userData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
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
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Profil",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _selectedIndex == 0
              ? ProfileView(
                  userData: userData,
                  onRefresh: _loadUserData,
                )
              : UpdateProfileView(
                  userData: userData,
                  onUpdateSuccess: _loadUserData,
                ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
          BottomNavigationBarItem(
              icon: Icon(Icons.edit), label: "Modifier Profil"),
        ],
      ),
    );
  }
}

class ProfileView extends StatelessWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onRefresh;

  const ProfileView({
    super.key,
    required this.userData,
    required this.onRefresh,
  });

  // Méthode pour gérer les actions du profil
  void _handleProfileAction(BuildContext context, String action) async {
    switch (action) {
      case 'my_shows':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyShowsPage()),
        );
        break;
      case 'favorites':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FavoritesPage()),
        );
        break;
      case 'settings':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Paramètres non implémentés")),
        );
        break;
      case 'logout':
        _confirmLogout(context);
        break;
    }
  }

  // Boîte de dialogue de confirmation de déconnexion
  Future<void> _confirmLogout(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Déconnexion"),
        content: const Text("Êtes-vous sûr de vouloir vous déconnecter?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Déconnexion"),
          ),
        ],
      ),
    );

    if (result == true) {
      final success = await UserService.logout();
      if (success) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(userData['avatar'] ?? 'https://i.pravatar.cc/300'),
              onBackgroundImageError: (_, __) {
                // Fallback si l'image ne charge pas
              },
            ),
            const SizedBox(height: 20),
            Text(
              userData['name'] ?? "Utilisateur",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              userData['email'] ?? "email@exemple.com",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  profileItem(
                    context,
                    Icons.movie,
                    "Mes Shows",
                    () => _handleProfileAction(context, 'my_shows'),
                  ),
                  profileItem(
                    context,
                    Icons.favorite,
                    "Favoris",
                    () => _handleProfileAction(context, 'favorites'),
                  ),
                  profileItem(
                    context,
                    Icons.settings,
                    "Paramètres",
                    () => _handleProfileAction(context, 'settings'),
                  ),
                  profileItem(
                    context,
                    Icons.logout,
                    "Déconnexion",
                    () => _handleProfileAction(context, 'logout'),
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget profileItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color color = Colors.blueAccent,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}

class UpdateProfileView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onUpdateSuccess;

  const UpdateProfileView({
    super.key,
    required this.userData,
    required this.onUpdateSuccess,
  });

  @override
  _UpdateProfileViewState createState() => _UpdateProfileViewState();
}

class _UpdateProfileViewState extends State<UpdateProfileView> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _avatarController = TextEditingController();
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userData['name'] ?? "";
    _emailController.text = widget.userData['email'] ?? "";
    _avatarController.text = widget.userData['avatar'] ?? "";
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Le nom et l'email sont obligatoires")),
      );
      return;
    }

    setState(() => _isUpdating = true);

    try {
      final updatedData = {
        'name': _nameController.text,
        'email': _emailController.text,
        'avatar': _avatarController.text.isNotEmpty
            ? _avatarController.text
            : widget.userData['avatar'],
      };

      final success = await UserService.updateUserData(updatedData);

      setState(() => _isUpdating = false);

      if (success) {
        widget.onUpdateSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil mis à jour avec succès!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors de la mise à jour du profil")),
        );
      }
    } catch (e) {
      setState(() => _isUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Modifier Profil",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(_avatarController.text.isNotEmpty
                  ? _avatarController.text
                  : widget.userData['avatar'] ?? 'https://i.pravatar.cc/300'),
              onBackgroundImageError: (_, __) {
                // Fallback en cas d'erreur
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Nom complet",
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Email",
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _avatarController,
              decoration: InputDecoration(
                labelText: "URL de l'avatar (optionnel)",
                prefixIcon: const Icon(Icons.image),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 30),
            _isUpdating
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _updateProfile,
                      child: const Text(
                        "Enregistrer les modifications",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}