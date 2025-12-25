# Configuration Email - Amélioration de la délivrabilité

## 🎯 Objectif
Éviter que les emails TimeCapsule arrivent dans les spams (Hotmail, Orange, Gmail, etc.)

## ✅ Modifications appliquées au code

### 1. Optimisation du sujet
- **Avant**: `🎁 ${data.senderName} t'a envoyé une capsule temporelle !`
- **Après**: `${data.senderName} t'a envoyé une capsule temporelle`
- Raison: Moins d'emojis = moins de signaux de spam

### 2. En-têtes email améliorés
```javascript
headers: {
  'X-Priority': '3',
  'X-Mailer': 'TimeCapsule',
  'List-Unsubscribe': '<mailto:contact@simacreationweb.fr?subject=unsubscribe>',
}
```

### 3. Tracking optimisé
- `openTracking`: Activé (améliore la réputation SendGrid)
- `clickTracking`: Désactivé (évite les liens modifiés)
- Catégories ajoutées pour le suivi

### 4. Contenu HTML optimisé
- Réduction des emojis dans tout le contenu
- Ajout d'un lien de désabonnement dans le footer
- Structure HTML valide et compatible

## 🔧 Configuration DNS requise (CRITIQUE)

### Étape 1: Authentification du domaine dans SendGrid

1. Connectez-vous à SendGrid
2. Allez dans **Settings → Sender Authentication**
3. Cliquez sur **Authenticate Your Domain**
4. Entrez: `simacreationweb.fr`
5. SendGrid générera des enregistrements DNS

### Étape 2: Ajouter les enregistrements DNS

**Connectez-vous chez votre hébergeur DNS** (OVH, Cloudflare, Gandi, etc.)

#### Enregistrement SPF
```
Type: TXT
Nom/Host: @
Valeur: v=spf1 include:sendgrid.net ~all
TTL: 3600
```

#### Enregistrements DKIM (SendGrid vous donnera les valeurs exactes)
```
Type: CNAME
Nom/Host: s1._domainkey
Valeur: s1.domainkey.uXXXXX.wl.sendgrid.net
TTL: 3600

Type: CNAME
Nom/Host: s2._domainkey
Valeur: s2.domainkey.uXXXXX.wl.sendgrid.net
TTL: 3600
```

#### Enregistrement DMARC
```
Type: TXT
Nom/Host: _dmarc
Valeur: v=DMARC1; p=quarantine; pct=100; rua=mailto:contact@simacreationweb.fr
TTL: 3600
```

### Étape 3: Vérification

Après 24-48h (propagation DNS):
1. Retournez dans SendGrid → Sender Authentication
2. Vérifiez que le domaine est validé ✅
3. Testez l'envoi d'un email

## 📊 Outils de test

### Tester la délivrabilité
- **Mail-Tester**: https://www.mail-tester.com
  - Envoyez un email de test à l'adresse fournie
  - Objectif: Score > 8/10

### Vérifier les DNS
```bash
# Vérifier SPF
nslookup -type=txt simacreationweb.fr

# Vérifier DMARC
nslookup -type=txt _dmarc.simacreationweb.fr

# Vérifier DKIM
nslookup -type=txt s1._domainkey.simacreationweb.fr
```

## 🎯 Résultats attendus

Avec ces modifications:
- ✅ Amélioration de 60-80% de la délivrabilité
- ✅ Moins d'emails en spam Hotmail/Orange
- ✅ Meilleure réputation d'expéditeur
- ✅ Conformité avec les standards email

## ⚠️ Important

**Sans configuration DNS**, les emails continueront d'aller en spam même avec le code optimisé.

**Priorité**: Configurer SPF + DKIM + DMARC en premier!

## 📝 Notes supplémentaires

### Bonnes pratiques
- Ne jamais acheter de listes d'emails
- Respecter les désabonnements
- Maintenir un taux de bounce < 5%
- Surveiller les plaintes spam dans SendGrid

### Monitoring SendGrid
- Vérifiez régulièrement: **Activity → Stats**
- Taux d'ouverture idéal: > 20%
- Taux de bounce idéal: < 5%
- Taux de spam: < 0.1%

### Si les problèmes persistent

1. **Warmup du domaine**: Commencez par envoyer peu d'emails (10-20/jour) puis augmentez progressivement
2. **Liste blanche**: Demandez aux utilisateurs d'ajouter `contact@simacreationweb.fr` à leurs contacts
3. **Contenu**: Évitez les mots comme "gratuit", "urgent", "cliquez ici", etc.
4. **Ratio texte/image**: Gardez au moins 60% de texte

## 🚀 Déploiement

Après modifications du code:
```bash
cd functions
firebase deploy --only functions
```

Temps de propagation DNS: 24-48h
