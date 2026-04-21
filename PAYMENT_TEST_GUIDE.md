# 🧪 Guide de Test Complet - Système de Paiement

## ✅ Tests de Compilation

```bash
# Étape 1: Vérifier qu'il n'y a pas d'erreurs
flutter analyze
# Résultat attendu: ✅ Aucune erreur

# Étape 2: Obtenir les dépendances
flutter pub get
# Résultat attendu: ✅ Got dependencies!

# Étape 3: Compiler pour Android (optionnel)
flutter build apk --debug
# Résultat attendu: ✅ Compilation réussie
```

## 🚀 Tests Manuels - Flux Complet

### **Scénario 1: Paiement par Carte**

1. **Lancer l'app**
   ```bash
   flutter run
   ```

2. **Se connecter**
   - Email: `test@example.com`
   - Mot de passe: `password123`

3. **Naviguer vers les voitures**
   - Cliquer sur l'onglet "Voitures"
   - Cliquer sur une voiture

4. **Réserver la voiture**
   - Cliquer "Réserver cette voiture"
   - Sélectionner la date de début
   - Sélectionner la date de fin
   - Cliquer "Confirmer la réservation"

5. **Écran de Paiement Affiche**
   - ✅ Montant total: `X FCFA`
   - ✅ 3 boutons de méthode: Carte, Mobile Money, Espèces

6. **Choisir Carte Bancaire**
   - Cliquer sur "Carte bancaire"
   - Cliquer "Procéder au paiement"

7. **Formulaire de Carte**
   - Numéro de carte: `4111111111111111`
   - Titulaire: `Test User`
   - Expiration: `12/25`
   - CVV: `123`
   - Cliquer "Payer XXX FCFA"

8. **Résultats Attendus**
   - ✅ Message: "Paiement effectué avec succès"
   - ✅ Navigation automatique vers "Mes réservations"
   - ✅ Réservation affichée avec statut "En attente"

---

### **Scénario 2: Paiement Mobile Money**

1. **Suivre les étapes 1-5 ci-dessus**

2. **Choisir Mobile Money**
   - Cliquer sur "Mobile Money"
   - Cliquer "Procéder au paiement"

3. **Écran Mobile Money**
   - ✅ Affiche: "Montant à payer: X FCFA"
   - ✅ 3 boutons de fournisseur

4. **Sélectionner un Fournisseur**
   - Cliquer sur "MTN Mobile Money" (ou autre)

5. **Entrer Numéro de Téléphone**
   - Numéro: `+22900000000`
   - Cliquer "Procéder au paiement"

6. **Résultats Attendus**
   - ✅ Message: "Paiement Mobile Money effectué avec succès"
   - ✅ Navigation automatique vers "Mes réservations"
   - ✅ Réservation affichée avec statut "En attente"

---

### **Scénario 3: Paiement en Espèces**

1. **Suivre les étapes 1-5 du Scénario 1**

2. **Choisir Espèces**
   - Cliquer sur "Paiement à la livraison"
   - Cliquer "Procéder au paiement"

3. **Résultats Attendus**
   - ✅ Message: "Paiement à la livraison confirmé"
   - ✅ Retour à l'écran précédent
   - ✅ Réservation enregistrée dans Firebase

---

## 🔍 Tests de Validation

### **Test 1: Validation Carte - Numéro Invalide**

1. Aller au formulaire de carte
2. Entrer: `1234` (numéro trop court)
3. Cliquer "Payer"
4. ✅ Message d'erreur: "Numéro de carte invalide"

### **Test 2: Validation Carte - Expiration Invalide**

1. Aller au formulaire de carte
2. Numéro: `4111111111111111`
3. Titulaire: `Test`
4. Expiration: `13/25` (mois invalide)
5. CVV: `123`
6. Cliquer "Payer"
7. ✅ Message d'erreur: "Mois invalide"

### **Test 3: Validation Carte - CVV Invalide**

1. Suivre le test 2 mais avec expiration correcte
2. CVV: `12` (trop court)
3. Cliquer "Payer"
4. ✅ Message d'erreur: "CVV invalide"

### **Test 4: Validation Mobile Money - Numéro Invalide**

1. Aller à Mobile Money
2. Choisir un fournisseur
3. Numéro: `123` (trop court)
4. Cliquer "Procéder"
5. ✅ Message d'erreur: "Numéro invalide"

### **Test 5: Mobile Money sur Web**

1. Lancer sur web: `flutter run -d chrome`
2. Aller à Mobile Money
3. Cliquer "Procéder au paiement"
4. ✅ Message d'erreur: "Paiement Mobile Money non pris en charge sur le web"

---

## 📊 Tests de Firebase

### **Vérifier que les Paiements sont Créés**

1. Aller à Firebase Console
2. Firestore → Collection `payments`
3. ✅ Vérifier que chaque paiement a:
   - `userId`: ID de l'utilisateur
   - `type`: "reservation"
   - `refId`: ID de la réservation
   - `amount`: Montant
   - `status`: "success" ou "pending"
   - `method`: "card", "mobileMoney", ou "cash"
   - `createdAt`: Timestamp

### **Vérifier que les Réservations sont Créées**

1. Aller à Firebase Console
2. Firestore → Collection `reservations`
3. ✅ Vérifier que chaque réservation a:
   - `userId`: ID de l'utilisateur
   - `carId`: ID de la voiture
   - `status`: "pending"
   - `totalPrice`: Montant total
   - `createdAt`: Timestamp

---

## 🐛 Débogage

### **Si "Page Blanche" Apparaît**

1. Ouvrir la console:
   ```bash
   flutter run -v
   ```

2. Chercher les erreurs:
   - `SecureUrlLauncher` → Pas d'URLs invalides
   - `about:bank` → Doit être bloqué
   - `Navigation failed` → Vérifier les routes

3. **Solutions Possibles**:
   - Vérifier que `mobile_money_payment_screen.dart` n'importe PAS `secure_url_launcher`
   - Vérifier que `_processPayment()` simule et ne lance pas d'URL
   - Vérifier les routes dans `app_router.dart`

### **Si "Erreur de Paiement" Apparaît**

1. Vérifier Firebase:
   ```bash
   firebase emulator:start
   ```

2. Vérifier les logs:
   - Filtrer par "Paiement" ou "Payment"
   - Chercher `❌ Erreur`

3. **Solutions Possibles**:
   - Vérifier la connexion à Firestore
   - Vérifier que l'utilisateur est bien connecté
   - Vérifier les permissions Firestore

---

## ✨ Checklist de Succès

- [ ] ✅ Compilation sans erreurs
- [ ] ✅ Paiement par Carte fonctionne
- [ ] ✅ Paiement Mobile Money fonctionne
- [ ] ✅ Paiement en Espèces fonctionne
- [ ] ✅ Validations fonctionnent correctement
- [ ] ✅ Paiements créés dans Firebase
- [ ] ✅ Messages de succès affichés
- [ ] ✅ Navigation correcte
- [ ] ✅ Pas de page blanche "about:bank"
- [ ] ✅ Réservations visibles dans "Mes réservations"

---

## 📝 Notes

- La simulation du paiement prend 2-3 secondes
- Les messages de succès/erreur sont clairs
- Le flux est complet et cohérent
- Tous les fichiers compilent sans erreur
