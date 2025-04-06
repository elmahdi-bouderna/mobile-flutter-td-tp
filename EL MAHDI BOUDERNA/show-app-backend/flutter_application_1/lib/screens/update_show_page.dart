import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class UpdateShowPage extends StatefulWidget {
  final Map<String, dynamic> show;
  
  const UpdateShowPage({super.key, required this.show});

  @override
  _UpdateShowPageState createState() => _UpdateShowPageState();
}

class _UpdateShowPageState extends State<UpdateShowPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedCategory = 'movie';
  final ImagePicker _picker = ImagePicker();
  
  // Variables pour gérer l'image
  File? _imageFile;
  Uint8List? _webImage;
  XFile? _pickedFile;
  String? _currentImagePath;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.show['title'];
    _descriptionController.text = widget.show['description'];
    _selectedCategory = widget.show['category'];
    _currentImagePath = widget.show['image'];
  }

  // Sélection d'image compatible avec toutes les plateformes
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      
      if (pickedFile != null) {
        setState(() {
          _pickedFile = pickedFile;
          
          if (kIsWeb) {
            // Pour le web
            _loadWebImage(pickedFile);
          } else {
            // Pour mobile/desktop
            _imageFile = File(pickedFile.path);
            _webImage = null;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la sélection de l'image: $e")),
      );
    }
  }
  
  // Charger l'image pour le web
  Future<void> _loadWebImage(XFile pickedFile) async {
    try {
      final imageBytes = await pickedFile.readAsBytes();
      setState(() {
        _webImage = imageBytes;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors du chargement de l'image: $e")),
      );
    }
  }

  Future<void> _updateShow() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Le titre et la description sont obligatoires!")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      var request = http.MultipartRequest(
        'PUT', 
        Uri.parse('${ApiConfig.baseUrl}/shows/${widget.show['id']}')
      );
      
      request.fields['title'] = _titleController.text;
      request.fields['description'] = _descriptionController.text;
      request.fields['category'] = _selectedCategory;
      
      // Ajout de l'image au format approprié selon la plateforme
      if (_pickedFile != null) {
        if (kIsWeb) {
          // Pour le web
          if (_webImage != null) {
            final fileName = _pickedFile!.name;
            final http.MultipartFile multipartFile = http.MultipartFile.fromBytes(
              'image',
              _webImage!,
              filename: fileName,
            );
            request.files.add(multipartFile);
          }
        } else {
          // Pour mobile/desktop
          if (_imageFile != null) {
            request.files.add(await http.MultipartFile.fromPath('image', _imageFile!.path));
          }
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      setState(() => _isUploading = false);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Show mis à jour avec succès!")),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception("Statut ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la mise à jour du show: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Modifier le Show"), 
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Titre"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: const [
                DropdownMenuItem(value: "movie", child: Text("Film")),
                DropdownMenuItem(value: "anime", child: Text("Anime")),
                DropdownMenuItem(value: "serie", child: Text("Série")),
              ],
              onChanged: (value) => setState(() => _selectedCategory = value!),
              decoration: const InputDecoration(labelText: "Catégorie"),
            ),
            const SizedBox(height: 20),
            
            // Affichage de l'image
            Center(
              child: _buildImagePreview(),
            ),
            
            const SizedBox(height: 20),
            
            // Boutons pour sélectionner une image
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.image),
                  label: const Text("Galerie"),
                ),
                if (!kIsWeb) // La caméra n'est pas disponible sur le web
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera),
                    label: const Text("Caméra"),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            
            _isUploading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _updateShow,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                      child: const Text(
                        "Mettre à jour", 
                        style: TextStyle(color: Colors.white)
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
  
  // Widget pour afficher l'aperçu de l'image, compatible avec toutes les plateformes
  Widget _buildImagePreview() {
    if (_webImage != null && kIsWeb) {
      // Nouvelle image sur Web
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          _webImage!,
          height: 200,
          fit: BoxFit.cover,
          width: double.infinity,
        ),
      );
    } else if (_imageFile != null && !kIsWeb) {
      // Nouvelle image sur Mobile/Desktop
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          _imageFile!,
          height: 200,
          fit: BoxFit.cover,
          width: double.infinity,
        ),
      );
    } else if (_currentImagePath != null) {
      // Image existante du show
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          ApiConfig.baseUrl + _currentImagePath!,
          height: 200,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 200,
            width: double.infinity,
            color: _getCategoryColor(),
            child: Center(
              child: Text(
                widget.show['title'].substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      // Aucune image
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _getCategoryColor(),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            widget.show['title'].substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }
  
  // Couleur selon la catégorie du show
  Color _getCategoryColor() {
    switch (_selectedCategory) {
      case 'movie':
        return Colors.redAccent;
      case 'anime':
        return Colors.purpleAccent;
      case 'serie':
        return Colors.greenAccent;
      default:
        return Colors.blueAccent;
    }
  }
}