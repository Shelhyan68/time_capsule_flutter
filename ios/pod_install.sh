#!/bin/bash

# Script pour installer les pods CocoaPods avec le bon environnement

# Nettoyer les variables d'environnement RVM
unset GEM_PATH
unset GEM_HOME
unset BUNDLE_PATH

# Configurer UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Ajouter Homebrew au PATH en priorité
export PATH="/opt/homebrew/bin:$PATH"

# Aller dans le dossier ios
cd "$(dirname "$0")"

echo "🔧 Installation des CocoaPods..."
/opt/homebrew/bin/pod install

echo "✅ Installation terminée"
