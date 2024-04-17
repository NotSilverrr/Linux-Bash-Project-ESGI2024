#!/bin/bash

# Vérification de l'existence du fichier source en argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 <fichier_source>"
    exit 1
fi

source_file=$1

# Vérification de l'existence et de la lisibilité du fichier source
if [ ! -f "$source_file" ] || [ ! -r "$source_file" ]; then
    echo "Erreur: Le fichier source '$source_file' est introuvable ou inaccessible."
    exit 1
fi

# Parcourir chaque ligne du fichier source
while IFS=: read -r prenom nom groupes sudo motdepasse || [ -n "$prenom" ]; do
    # Vérifier si toutes les colonnes sont présentes
    if [ -z "$prenom" ] || [ -z "$nom" ] || [ -z "$groupes" ] || [ -z "$sudo" ] || [ -z "$motdepasse" ]; then
        echo "Erreur: Format incorrect dans une ligne du fichier source."
        continue
    fi

    # Créer l'utilisateur
    sudo useradd -m -s /bin/bash -G "$groupes" -p $(openssl passwd -1 "$motdepasse") "$prenom"

    # Vérifier si l'ajout de l'utilisateur a réussi
    if [ $? -eq 0 ]; then
        echo "Utilisateur $prenom créé avec succès."
        # Activer les privilèges sudo si spécifié
        if [ "$sudo" = "yes" ]; then
            sudo usermod -aG sudo "$prenom"
            echo "Privilèges sudo accordés à $prenom."
        fi
    else
        echo "Erreur lors de la création de l'utilisateur $prenom."
    fi
done < "$source_file"