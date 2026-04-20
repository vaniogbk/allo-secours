# 🧪 Guide de Test - Système de Paiement LogiTrack

## 📋 Prérequis

1. **Dépendances installées**
   ```bash
   flutter pub get
   ```

2. **Firebase configuré** (déjà fait)

3. **Emulateur/Device avec accès internet**

---

## ✅ Test 1: Flux Complet de Réservation avec Paiement

### Objectif
Vérifier que tout fonctionne du booking à la confirmation de paiement.

### Étapes

```bash
# 1. Lancer l'application
flutter run

# 2. Se connecter
# Email: test@logitrack.bj
# Mot de passe: Test123456

# 3. Naviguer vers "Voitures"
# Cliquer sur l'icône voiture en bas

# 4. Cliquer sur une voiture disponible
# Ex: "Toyota Corolla"

# 5. Réserver la voiture
# - Sélectionner 2-3 jours de dates
# - Cliquer "Confirmer"

# 6. Écran de paiement s'affiche
# Vérifier:
# ✓ Montant correct affiché
# ✓ Trois méthodes visibles
# ✓ Pas d'erreur "about:bank"

# 7. Tester chaque méthode
```

---

## ✅ Test 2: Paiement par Carte

### Objectif
Valider le formulaire de carte et le traitement.

### Étapes

```bash
# 1. Sur l'écran de paiement
# Cliquer sur "Carte bancaire"

# 2. Remplir le formulaire
Numéro: 4111111111111111  (test Visa)
Nom: Jean Dupont
Expiration: 12/25
CVV: 123

# 3. Cliquer "Payer"

# Résultats attendus:
✓ Validation OK (pas d'erreur)
✓ Message "Paiement effectué"
✓ Redirection vers réservations
✓ Réservation affichée comme "En attente"
```

### Cas d'Erreur à Tester

```bash
# Test 1: Numéro invalide
Numéro: 1234567  (< 13 chiffres)
Résultat attendu: ✗ Erreur "Numéro de carte invalide"

# Test 2: Expiration invalide
Expiration: 13/25  (mois 13 invalide)
Résultat attendu: ✗ Erreur "Mois invalide"

# Test 3: CVV invalide
CVV: 12  (< 3 chiffres)
Résultat attendu: ✗ Erreur "CVV invalide"
```

---

## ✅ Test 3: Paiement Mobile Money

### Objectif
Valider le formulaire et l'URL de paiement.

### Étapes

```bash
# 1. Sur l'écran de paiement
# Cliquer sur "Mobile Money"

# 2. Sélectionner un fournisseur (MTN)
# (Test avec n'importe quel fournisseur)

# 3. Entrer numéro de téléphone
Numéro: +22900000000

# 4. Cliquer "Procéder au paiement"

# Résultats attendus:
✓ Pas d'erreur "about:bank"
✓ URL valide construite
✓ Message "Vérification en cours"
✓ Redirection automatique après 3 sec
```

### Test des Variations

```bash
# Test 1: Numéro vide
Numéro: [vide]
Résultat attendu: ✗ Message d'erreur

# Test 2: Numéro invalide
Numéro: 123  (< 8 chiffres)
Résultat attendu: ✗ Erreur "Numéro invalide"
```

---

## ✅ Test 4: Paiement à la Livraison

### Objectif
Valider le flux d'espèces.

### Étapes

```bash
# 1. Sur l'écran de paiement
# Cliquer sur "Paiement à la livraison"

# 2. Cliquer "Procéder au paiement"

# Résultats attendus:
✓ Message "Paiement à la livraison confirmé"
✓ Pas de formulaire supplémentaire
✓ Redirection vers réservations
✓ Statut: "En attente de confirmation"
```

---

## ✅ Test 5: Validation des URLs

### Objectif
S'assurer que le service `SecureUrlLauncher` rejette les URLs invalides.

### Test Manuel (Debug Console)

```dart
// Ajouter ceci dans un test
import 'package:logitrack/services/secure_url_launcher.dart';

void testUrls() {
  // Test 1: URL valide HTTPS
  expect(SecureUrlLauncher.isValidUrl('https://payment.example.com'), true);
  
  // Test 2: URL nulle
  expect(SecureUrlLauncher.isValidUrl(''), false);
  expect(SecureUrlLauncher.isValidUrl(null), false);
  
  // Test 3: URL malformée (about:bank)
  expect(SecureUrlLauncher.isValidUrl('about:bank'), false);
  
  // Test 4: Schémas autorisés
  expect(SecureUrlLauncher.isValidUrl('tel:+22900000000'), true);
  expect(SecureUrlLauncher.isValidUrl('mailto:test@example.com'), true);
  
  // Test 5: Schéma personnalisé autorisé
  expect(SecureUrlLauncher.isValidUrl('bank://payment'), true);
}
```

---

## ✅ Test 6: Navigation via Routes

### Objectif
Tester les routes de paiement via GoRouter.

### Test via Logs

```bash
# Ajouter du logging dans app_router.dart

# Vérifier les logs:
✓ Route '/payment' accessible
✓ Route '/payment/card/:id' accessible  
✓ Route '/payment/mobile-money/:id' accessible
✓ Paramètres passés correctement
```

---

## ✅ Test 7: Sécurité et Erreurs

### Objectif
Vérifier que l'app ne génère JAMAIS "about:bank".

### Scénarios à Tester

```bash
# Scénario 1: Variable nulle
- Modifier PaymentScreen pour passer null en montant
- Résultat: Erreur gracieuse, pas "about:bank"

# Scénario 2: URL malformée
- Modifier SecureUrlLauncher pour ignorer validation
- Résultat: Erreur loggée, pas de crash

# Scénario 3: Firestore erreur
- Arrêter Firestore (mode hors ligne)
- Tenter une réservation
- Résultat: Message d'erreur clair à l'utilisateur

# Scénario 4: Réseau défaillant
- Activer mode avion
- Essayer de lancer URL Mobile Money
- Résultat: Erreur "Impossible de lancer l'URL"
```

---

## 📊 Checklist Complète

### Fonctionnalités
- [ ] Réservation crée correctement
- [ ] Écran paiement s'affiche
- [ ] 3 méthodes visibles
- [ ] Montant affiche correctement
- [ ] Paiement carte valide
- [ ] Paiement Mobile Money valide
- [ ] Paiement espèces valide
- [ ] Redirection réussie après paiement

### Sécurité
- [ ] Pas d'erreur "about:bank"
- [ ] URLs validées avant lancement
- [ ] Formulaires validés
- [ ] Erreurs gérées gracieusement
- [ ] Logs informatifs en console

### UX
- [ ] Messages d'erreur clairs
- [ ] Pas de crashes
- [ ] Transitions fluides
- [ ] Boutons actifs/inactifs corrects
- [ ] États de chargement visibles

---

## 🐛 Dépannage

### Problème: "Route not found"
**Solution**: Vérifier que l'import est fait dans `app_router.dart`
```dart
import '../../features/client/payment/payment_screen.dart';
```

### Problème: "about:bank" toujours présent
**Solution**: 
1. Faire `flutter clean`
2. Faire `flutter pub get`
3. Redémarrer l'app

### Problème: Paiement ne redirige pas
**Solution**: Vérifier la connexion Firestore et les logs console

### Problème: Validation échoue quand elle devrait réussir
**Solution**: Vérifier le format exactement (ex: expiration 12/25, pas 12/2025)

---

## 📝 Rapporter les Bugs

Quand vous trouvez un bug, incluez:

1. **Environnement**
   - Version Flutter
   - Device (Android/iOS/Web)

2. **Étapes**
   - Exactement ce que vous avez fait
   - Les données entrées

3. **Résultat Attendu**
   - Ce qui devrait se passer

4. **Résultat Obtenu**
   - Ce qui s'est vraiment passé

5. **Logs/Screenshots**
   - Console logs
   - Screenshots de l'erreur

---

## ✨ Notes Finales

- Le système est en **simulation** en développement
- Les vraies APIs (Stripe, MTN, Orange, Moov) doivent être intégrées
- Les webhooks doivent être configurés pour les retours de paiement
- Tester régulièrement pour éviter les régressions

**Bon test! 🚀**
