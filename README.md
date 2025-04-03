# ShowApp - Application Mobile Flutter

## Développeur
**EL MAHDI BOUDERNA (elmahdi-bouderna)**

## Vue d'ensemble du projet
Ce référentiel contient une application mobile complète développée avec Flutter qui interagit avec un backend Node.js via des API RESTful. L'application permet aux utilisateurs de parcourir, créer, mettre à jour et supprimer du contenu multimédia (films, séries et anime) avec une interface intuitive et réactive, implémentant ainsi une fonctionnalité CRUD complète.

## Fonctionnalités implémentées

### 1. Page de mise à jour des shows
- ✅ Formulaire intuitif pour éditer les détails des shows existants (titre, description, catégorie)
- ✅ Sélection d'images depuis la galerie et l'appareil photo avec fonctionnalité d'aperçu
- ✅ Champs pré-remplis avec les données existantes pour une expérience d'édition fluide
- ✅ Gestion complète des erreurs et validation des saisies
- ✅ Intégration robuste avec l'API via des requêtes PUT et formulaires multipart pour le téléchargement d'images
- ✅ Indicateurs de chargement pendant le processus de mise à jour avec notifications de succès/erreur

### 2. Page d'accueil dynamique avec actualisation automatique
- ✅ Actualisation automatique après ajout, mise à jour ou suppression de shows sans intervention manuelle
- ✅ Fonctionnalité de "pull-to-refresh" pour des mises à jour immédiates
- ✅ Gestion efficace des états pour maintenir la position de défilement après les mises à jour
- ✅ Affichage catégorisé par type de show (films, anime, séries) avec des onglets dédiés
- ✅ Suppression par glissement avec boîte de dialogue de confirmation pour éviter les suppressions accidentelles
- ✅ Interface utilisateur attrayante basée sur des cartes avec aperçus miniatures
- ✅ Gestion des états vides avec des messages appropriés

### 3. Page de connexion fonctionnelle
- ✅ Authentification par email et mot de passe avec validation sécurisée côté backend
- ✅ Messages d'erreur détaillés pour identifiants invalides et problèmes réseau
- ✅ Indicateurs de chargement animés pendant les processus d'authentification
- ✅ Stockage sécurisé des tokens via SharedPreferences pour les requêtes API ultérieures
- ✅ Fonctionnalité de connexion automatique si un token valide existe
- ✅ Gestion appropriée des tokens pour des requêtes API sécurisées
- ✅ Interface utilisateur attrayante avec fond en dégradé et design responsive

## Détails de l'implémentation technique

### Architecture
- Implémentation d'une architecture basée sur les services séparant l'interface utilisateur, la logique métier et l'accès aux données
- Création de widgets réutilisables pour des éléments d'interface utilisateur cohérents dans toute l'application
- Utilisation stratégique de widgets stateful pour les composants nécessitant une gestion d'état dynamique

### Intégration API
- Conception d'un intercepteur de token pour gérer l'authentification pour toutes les requêtes API
- Implémentation d'une gestion appropriée des erreurs pour les pannes réseau et les erreurs serveur
- Utilisation de requêtes multipart pour le téléchargement d'images avec suivi de la progression

### Gestion d'état
- Utilisation de la gestion d'état intégrée de Flutter pour la portée de ce projet
- Création de mécanismes de rafraîchissement efficaces pour mettre à jour uniquement les composants nécessaires
- Implémentation de modèles de callback pour propager les changements entre les écrans

### Considérations UI/UX
- Conception d'un schéma de couleurs et d'une typographie cohérents dans toute l'application
- Inclusion d'états de chargement, d'erreur et d'états vides pour une meilleure expérience utilisateur
- Ajout d'animations pour les transitions et les états de chargement
- Design responsive fonctionnant sur différentes tailles d'écran

## Instructions d'installation

### Prérequis
- Flutter SDK (2.0 ou plus récent)
- Dart SDK
- Android Studio ou VS Code avec plugins Flutter
- Node.js et npm (pour le backend)

### Installation

1. Cloner le référentiel :
```bash
git clone https://github.com/elmahdi-bouderna/mobile-flutter-td-tp.git
cd mobile-flutter-td-tp
