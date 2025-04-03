const express = require('express');
const bodyParser = require('body-parser');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = 3000;

// Middleware pour parser le JSON
app.use(bodyParser.json());

// Chemin vers le fichier de données
const dataPath = path.join(__dirname, 'data.json');

// Créer le fichier data.json s'il n'existe pas
if (!fs.existsSync(dataPath)) {
  fs.writeFileSync(dataPath, JSON.stringify({ products: [], orders: [] }, null, 2));
}

// Fonction pour charger les données
const loadData = () => {
  const rawData = fs.readFileSync(dataPath);
  return JSON.parse(rawData);
};

// Fonction pour sauvegarder les données
const saveData = (data) => {
  fs.writeFileSync(dataPath, JSON.stringify(data, null, 2));
};

// Route pour la page d'accueil
app.get('/', (req, res) => {
  res.send('API de gestion des produits et commandes - TD1');
});

// Route GET pour récupérer tous les produits
app.get('/products', (req, res) => {
  const data = loadData();
  res.json(data.products);
});

// Route POST pour ajouter un nouveau produit
app.post('/products', (req, res) => {
  const { nom, prix, stock, categorie } = req.body;
  
  // Validation des données
  if (!nom || prix === undefined || stock === undefined || !categorie) {
    return res.status(400).json({ error: 'Tous les champs sont requis (nom, prix, stock, categorie)' });
  }
  
  const data = loadData();
  
  // Création du nouveau produit
  const newProduct = {
    id: data.products.length > 0 ? Math.max(...data.products.map(p => p.id)) + 1 : 1,
    nom,
    prix,
    stock,
    categorie
  };
  
  // Ajout du produit à la liste
  data.products.push(newProduct);
  saveData(data);
  
  res.status(201).json(newProduct);
});

// Route GET pour récupérer toutes les commandes
app.get('/orders', (req, res) => {
  const data = loadData();
  res.json(data.orders);
});

// Route POST pour créer une nouvelle commande
app.post('/orders', (req, res) => {
  const { produits } = req.body;
  
  // Validation des données
  if (!produits || !Array.isArray(produits) || produits.length === 0) {
    return res.status(400).json({ error: 'La commande doit contenir une liste de produits non vide' });
  }
  
  const data = loadData();
  
  // Vérification de la disponibilité des produits et mise à jour des stocks
  let total = 0;
  const commandeDetails = [];
  
  for (const item of produits) {
    const { productId, quantite } = item;
    
    // Recherche du produit dans la base de données
    const produit = data.products.find(p => p.id === productId);
    
    if (!produit) {
      return res.status(404).json({ error: `Produit avec ID ${productId} non trouvé` });
    }
    
    if (produit.stock < quantite) {
      return res.status(400).json({ 
        error: `Stock insuffisant pour ${produit.nom}. Disponible: ${produit.stock}, Demandé: ${quantite}` 
      });
    }
    
    // Mise à jour du stock
    produit.stock -= quantite;
    
    // Calcul du sous-total
    const sousTotal = produit.prix * quantite;
    total += sousTotal;
    
    // Ajout des détails à la commande
    commandeDetails.push({
      produitId: produit.id,
      nom: produit.nom,
      prix: produit.prix,
      quantite,
      sousTotal
    });
  }
  
  // Création de la nouvelle commande
  const newOrder = {
    id: data.orders.length > 0 ? Math.max(...data.orders.map(o => o.id)) + 1 : 1,
    date: new Date().toISOString(),
    produits: commandeDetails,
    total
  };
  
  // Ajout de la commande à la liste
  data.orders.push(newOrder);
  saveData(data);
  
  res.status(201).json(newOrder);
});

// Démarrage du serveur
app.listen(PORT, () => {
  console.log(`Serveur démarré sur http://localhost:${PORT}`);
});