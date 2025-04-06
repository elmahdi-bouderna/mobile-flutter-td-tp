class ApiConfig {
  // Pour les émulateurs Android
  // static const String baseUrl = "http://10.0.2.2:5000";
  
  // Pour les appareils physiques et émulateurs
  static const String baseUrl = "http://localhost:5000";
  
  // Augmentation du délai d'attente
  static const Duration timeoutDuration = Duration(seconds: 30);
  
  // Fonction pour obtenir l'URL adaptée au contexte d'exécution
  static String getBaseUrl() {
    // En production, nous retournerions l'URL appropriée selon la plateforme
    return baseUrl;
  }
}