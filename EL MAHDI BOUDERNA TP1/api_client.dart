import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const String BASE_URL = 'http://localhost:3000';

// Classe Produit inspirée du TD1
class Produit {
  final int? id;
  final String nom;
  final double prix;
  int stock;
  final String categorie;

  Produit({
    this.id,
    required this.nom,
    required this.prix,
    required this.stock,
    required this.categorie,
  });

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'prix': prix,
      'stock': stock,
      'categorie': categorie,
    };
  }

  @override
  String toString() {
    return 'Produit{id: $id, nom: $nom, prix: $prix, stock: $stock, categorie: $categorie}';
  }
}

// Classe pour représenter un élément de commande
class ElementCommande {
  final int productId;
  final int quantite;

  ElementCommande({required this.productId, required this.quantite});

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantite': quantite,
    };
  }
}

// Fonction pour récupérer et afficher tous les produits
Future<List<Produit>> getProducts() async {
  try {
    final response = await http.get(Uri.parse('$BASE_URL/products'));

    if (response.statusCode == 200) {
      List<dynamic> productsJson = jsonDecode(response.body);
      List<Produit> products = productsJson.map((json) => Produit(
        id: json['id'],
        nom: json['nom'],
        prix: json['prix'].toDouble(),
        stock: json['stock'],
        categorie: json['categorie'],
      )).toList();

      print('📦 Liste des produits:');
      print('---------------------------');
      products.forEach((product) {
        print('ID: ${product.id}');
        print('Nom: ${product.nom}');
        print('Prix: ${product.prix}');
        print('Stock: ${product.stock}');
        print('Catégorie: ${product.categorie}');
        print('---------------------------');
      });

      return products;
    } else {
      print('❌ Erreur lors de la récupération des produits: ${response.statusCode}');
      print(response.body);
      return [];
    }
  } catch (e) {
    print('❌ Exception lors de la récupération des produits: $e');
    return [];
  }
}

// Fonction pour ajouter un nouveau produit
Future<bool> addProduct(Produit produit) async {
  try {
    final response = await http.post(
      Uri.parse('$BASE_URL/products'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(produit.toJson()),
    );

    if (response.statusCode == 201) {
      print('✅ Produit ajouté avec succès!');
      return true;
    } else {
      print('❌ Erreur lors de l\'ajout du produit: ${response.statusCode}');
      print(response.body);
      return false;
    }
  } catch (e) {
    print('❌ Exception lors de l\'ajout du produit: $e');
    return false;
  }
}

// Fonction pour récupérer et afficher toutes les commandes
Future<void> getOrders() async {
  try {
    final response = await http.get(Uri.parse('$BASE_URL/orders'));

    if (response.statusCode == 200) {
      List<dynamic> ordersJson = jsonDecode(response.body);
      
      print('📋 Liste des commandes:');
      print('---------------------------');
      
      for (var order in ordersJson) {
        print('ID commande: ${order['id']}');
        print('Date: ${order['date']}');
        print('Produits:');
        
        for (var item in order['produits']) {
          print('  - ${item['quantite']}x ${item['nom']} (${item['prix']} DH/unité)');
          print('    Sous-total: ${item['sousTotal']} DH');
        }
        
        print('Total: ${order['total']} DH');
        print('---------------------------');
      }
    } else {
      print('❌ Erreur lors de la récupération des commandes: ${response.statusCode}');
      print(response.body);
    }
  } catch (e) {
    print('❌ Exception lors de la récupération des commandes: $e');
  }
}

// Fonction pour créer une nouvelle commande
Future<bool> createOrder(List<ElementCommande> elements) async {
  try {
    final Map<String, dynamic> orderData = {
      'produits': elements.map((e) => e.toJson()).toList(),
    };

    final response = await http.post(
      Uri.parse('$BASE_URL/orders'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(orderData),
    );

    if (response.statusCode == 201) {
      final orderJson = jsonDecode(response.body);
      print('✅ Commande créée avec succès!');
      print('ID: ${orderJson['id']}');
      print('Total: ${orderJson['total']} DH');
      return true;
    } else {
      print('❌ Erreur lors de la création de la commande: ${response.statusCode}');
      print(response.body);
      return false;
    }
  } catch (e) {
    print('❌ Exception lors de la création de la commande: $e');
    return false;
  }
}

// Menu interactif pour tester toutes les fonctionnalités
Future<void> showMenu() async {
  while (true) {
    print('\n🛠️ SYSTÈME DE GESTION DE COMMANDES 🛠️');
    print('1. Afficher tous les produits');
    print('2. Ajouter un nouveau produit');
    print('3. Afficher toutes les commandes');
    print('4. Créer une nouvelle commande');
    print('0. Quitter');
    print('Choisissez une option (0-4):');
    
    final input = stdin.readLineSync();
    switch (input) {
      case '1':
        await getProducts();
        break;
      case '2':
        await addProductInteractive();
        break;
      case '3':
        await getOrders();
        break;
      case '4':
        await createOrderInteractive();
        break;
      case '0':
        print('Au revoir!');
        return;
      default:
        print('Option invalide, veuillez réessayer.');
    }
  }
}

// Fonction interactive pour ajouter un produit
Future<void> addProductInteractive() async {
  print('\n📝 AJOUTER UN NOUVEAU PRODUIT');
  print('Nom du produit:');
  final nom = stdin.readLineSync() ?? '';
  
  print('Prix:');
  double prix = 0;
  try {
    prix = double.parse(stdin.readLineSync() ?? '0');
  } catch (e) {
    print('Prix invalide, utilisation de 0.');
  }
  
  print('Stock:');
  int stock = 0;
  try {
    stock = int.parse(stdin.readLineSync() ?? '0');
  } catch (e) {
    print('Stock invalide, utilisation de 0.');
  }
  
  print('Catégorie:');
  final categorie = stdin.readLineSync() ?? '';
  
  final newProduct = Produit(
    nom: nom,
    prix: prix,
    stock: stock,
    categorie: categorie,
  );
  
  await addProduct(newProduct);
}

// Fonction interactive pour créer une commande
Future<void> createOrderInteractive() async {
  final products = await getProducts();
  if (products.isEmpty) {
    print('Aucun produit disponible. Veuillez d\'abord ajouter des produits.');
    return;
  }
  
  List<ElementCommande> orderElements = [];
  bool addMore = true;
  
  while (addMore) {
    print('\nChoisissez un produit par ID:');
    final productIdStr = stdin.readLineSync() ?? '';
    int productId = 0;
    try {
      productId = int.parse(productIdStr);
    } catch (e) {
      print('ID invalide.');
      continue;
    }
    
    final selectedProduct = products.firstWhere(
      (product) => product.id == productId,
      orElse: () => Produit(id: -1, nom: '', prix: 0, stock: 0, categorie: ''),
    );
    
    if (selectedProduct.id == -1) {
      print('Produit non trouvé.');
      continue;
    }
    
    print('Quantité (disponible: ${selectedProduct.stock}):');
    int quantity = 0;
    try {
      quantity = int.parse(stdin.readLineSync() ?? '0');
    } catch (e) {
      print('Quantité invalide.');
      continue;
    }
    
    if (quantity <= 0 || quantity > selectedProduct.stock) {
      print('Quantité invalide ou insuffisante en stock.');
      continue;
    }
    
    orderElements.add(ElementCommande(
      productId: productId,
      quantite: quantity,
    ));
    
    print('Ajouter un autre produit? (o/n)');
    final response = stdin.readLineSync()?.toLowerCase() ?? 'n';
    addMore = response == 'o';
  }
  
  if (orderElements.isNotEmpty) {
    await createOrder(orderElements);
  } else {
    print('La commande est vide. Opération annulée.');
  }
}

// Fonction principale
void main() async {
  print('Connexion à $BASE_URL...');
  try {
    final response = await http.get(Uri.parse(BASE_URL));
    if (response.statusCode == 200) {
      print('✅ Connexion établie!');
      await showMenu();
    } else {
      print('❌ Serveur accessible mais erreur: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Impossible de se connecter au serveur. Assurez-vous que le serveur Express est en cours d\'exécution.');
    print('Erreur: $e');
  }
}