import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

/// Service de validation et de lancement d'URLs sécurisé
/// Évite les problèmes comme "about:bank" en validant toutes les URLs
class SecureUrlLauncher {
  /// Lance une URL de manière sécurisée
  /// Retourne true si succès, false sinon
  static Future<bool> launchUrl(String? urlString,
      {bool externalApplication = false}) async {
    // Validation 1: L'URL ne doit pas être nulle ou vide
    if (urlString == null || urlString.trim().isEmpty) {
      print('❌ Erreur: URL vide ou nulle');
      return false;
    }

    // Validation 2: Vérifier que l'URL commence par un schéma valide
    final url = urlString.trim();
    if (!_isValidUrl(url)) {
      print('❌ Erreur: URL invalide: $url');
      return false;
    }

    // Bloquer explicitement les URL HTML dangereuses ou non prises en charge
    if (url.startsWith('about:') || url.startsWith('javascript:')) {
      print('❌ Erreur: Schéma non autorisé: $url');
      return false;
    }

    // Vérification spécifique pour les URLs de paiement
    if (url.contains('about:bank') || url == 'about:bank') {
      print('❌ Erreur: URL de paiement invalide détectée: $url');
      print('💡 Conseil: Vérifiez que l\'API du fournisseur de paiement retourne une URL valide');
      return false;
    }

    try {
      final uri = Uri.parse(url);

      // En web, LaunchMode.externalApplication peut provoquer des tabs vides.
      final mode = kIsWeb && externalApplication
          ? url_launcher.LaunchMode.platformDefault
          : externalApplication
              ? url_launcher.LaunchMode.externalApplication
              : url_launcher.LaunchMode.platformDefault;

      // Validation 3: Vérifier avec canLaunchUrl avant de lancer
      if (await url_launcher.canLaunchUrl(uri)) {
        await url_launcher.launchUrl(uri, mode: mode);
        print('✅ URL lancée avec succès: $url');
        return true;
      } else {
        print('❌ Erreur: Impossible de lancer l\'URL: $url');
        return false;
      }
    } catch (e) {
      print('❌ Erreur lors du lancement de l\'URL: $e');
      return false;
    }
  }

  /// Valide qu'une URL a un schéma valide
  static bool _isValidUrl(String url) {
    // Liste des schémas autorisés
    const validSchemes = [
      'http://',
      'https://',
      'tel:',
      'mailto:',
      'sms:',
      'whatsapp://',
      'whatsapp:',
    ];

    // Liste des schémas personnalisés autorisés uniquement sur mobile
    const customMobileSchemes = [
      'bank://',
      'paymentgateway://',
    ];

    final startsWithValidScheme = validSchemes.any((scheme) => url.startsWith(scheme));
    final startsWithMobileScheme =
        customMobileSchemes.any((scheme) => url.startsWith(scheme));

    if (kIsWeb && startsWithMobileScheme) {
      print('⚠️ Schéma mobile non pris en charge sur le web: $url');
      return false;
    }

    if (!startsWithValidScheme && !startsWithMobileScheme) {
      print('⚠️ Schéma d\'URL non valide: $url');
      return false;
    }

    return true;
  }

  /// Crée une URL de paiement sécurisée
  /// S'assure que la URL n'est jamais nulle ou malformée
  static String? createPaymentUrl({
    required String? baseUrl,
    required String paymentId,
    required double amount,
    required String currency,
    required String returnUrl,
  }) {
    // Validation de la baseUrl
    if (baseUrl == null || baseUrl.trim().isEmpty) {
      print('❌ Erreur: Base URL vide pour le paiement');
      return null;
    }

    try {
      // Construire l'URL avec les paramètres
      final uri = Uri.parse(baseUrl)
          .replace(queryParameters: {
        'payment_id': paymentId,
        'amount': amount.toString(),
        'currency': currency,
        'return_url': returnUrl,
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      final fullUrl = uri.toString();

      // Vérifier que l'URL résultante est valide
      if (!_isValidUrl(fullUrl)) {
        print('❌ Erreur: URL de paiement générée invalide: $fullUrl');
        return null;
      }

      print('✅ URL de paiement créée: $fullUrl');
      return fullUrl;
    } catch (e) {
      print('❌ Erreur lors de la création de l\'URL: $e');
      return null;
    }
  }

  /// Valide une URL de callback/retour
  static bool isValidCallbackUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;

    // S'assurer que c'est une URL HTTPS pour les callbacks
    return url.startsWith('https://') || url.startsWith('http://');
  }
}
