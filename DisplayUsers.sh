#!/bin/bash

while IFS=: read -r username _ _ uid _ _ _; do
    user_info=$(getent passwd "$username")
    IFS=':' read -ra info <<< "$user_info"
    login="${info[0]}"
    full_name="${info[4]}"
    home_directory="${info[5]}"
    
    primary_group=$(getent group | awk -F: '$3 == '"$(id -g "$username")"' {print $1}')

    secondary_groups=$(id -nG "$username" | sed -e "s/$primary_group//" -e "s/ /,/g")

    sudo_status=""
    if groups "$username" | grep -qw "sudo"; then
        sudo_status="OUI"
    else
        sudo_status="NON"
    fi

    #ptet remettre le s
    dir_size=$(du -h "$home_directory" 2>/dev/null | cut -f1)

    echo "Utilisateur: $login"
    echo "Prénom: ${full_name%% *}"
    echo "Nom: ${full_name##* }"
    echo "Groupe primaire: $primary_group"
    echo "Groupes secondaires: $secondary_groups"
    echo "Répertoire personnel: $dir_size"
    echo "Sudoer: $sudo_status"
    echo "-----------------------------------"
done < <(getent passwd | grep -vE "nologin|false")