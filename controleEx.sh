#!/bin/bash

previousFile="previousFile.txt"
currentFile="currentFile.txt"

find / -type f \( -perm -4000 -o -perm -2000 \) -exec ls -l {} \; 2>/dev/null > "$currentFile"

if [ -f "$previousFile" ]; then
    echo "Changements:"
    echo "=================================================="
    diff "$previousFile" "$currentFile" | grep ">" | awk '{print $NF " : Modifie le : " $7 " " $8}'
else
    echo "Premier lancement du programme,création du fichier."
fi

cp "$currentFile" "$previousFile"

rm "$currentFile"
