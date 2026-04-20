class AppStrings {
  AppStrings._();

  static const String appName = 'LogiTrack';
  static const String login = 'Connexion';
  static const String register = "S'inscrire";
  static const String email = 'Adresse email';
  static const String password = 'Mot de passe';
  static const String fullName = 'Nom complet';
  static const String phoneNumber = 'Numéro de téléphone';
  static const String noAccount = "Pas encore de compte ?";
  static const String alreadyAccount = 'Déjà un compte ?';
  static const String loading = 'Chargement...';
  static const String errorOccurred = 'Une erreur est survenue';
  static const String required = 'Ce champ est obligatoire';
  static const String invalidEmail = 'Adresse email invalide';
  static const String weakPassword = 'Minimum 6 caractères';
  static const String passwordMismatch = 'Les mots de passe ne correspondent pas';

  static String getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return 'En attente';
      case 'confirmed': return 'Confirmée';
      case 'active': return 'En cours';
      case 'completed': return 'Terminée';
      case 'cancelled': return 'Annulée';
      case 'pickedup': return 'Pris en charge';
      case 'intransit': return 'En transit';
      case 'delivered': return 'Livré';
      default: return status;
    }
  }
}