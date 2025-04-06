import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AddShowPage extends StatefulWidget {
  const AddShowPage({super.key});

  @override
  _AddShowPageState createState() => _AddShowPageState();
}

class _AddShowPageState extends State<AddShowPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedCategory = 'movie';
  final ImagePicker _picker = ImagePicker();
  
  // Variables pour gérer l'image
  File? _imageFile;
  Uint8List? _webImage;
  XFile? _pickedFile;
  bool _isUploading = false;

  // Sélection d'image compatible avec toutes les plateformes
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      
      if (pickedFile != null) {
        setState(() {
          _pickedFile = pickedFile;
          
          if (kIsWeb) {
            // Pour le web, chargez l'image comme bytes
            _loadWebImage(pickedFile);
          } else {
            // Pour mobile/desktop, utilisez File
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

  Future<void> _addShow() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty || 
        (_imageFile == null && _webImage == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tous les champs sont obligatoires!")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      var request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/shows'));
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

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Show ajouté avec succès!")),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception("Statut ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de l'ajout du show: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ajouter un Show"), backgroundColor: Colors.blueAccent),
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
            
            // Affichage de l'image sélectionnée
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
                      onPressed: _addShow,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                      child: const Text("Ajouter Show", style: TextStyle(color: Colors.white)),
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
      // Pour le Web
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
      // Pour Mobile/Desktop
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          _imageFile!,
          height: 200,
          fit: BoxFit.cover,
          width: double.infinity,
        ),
      );
    } else {
      // Aucune image sélectionnée
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, size: 50, color: Colors.grey),
            SizedBox(height: 8),
            Text("Aucune image sélectionnée", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
  }
}