#!/bin/bash

while IFS=: read -r username _ _ uid _ _ _; do
    filter=0
    user_info=$(getent passwd "$username")
    IFS=':' read -ra info <<< "$user_info"
    login="${info[0]}"
    full_name="${info[4]}"
    home_directory="${info[5]}"
    
    GroupMain=$(getent group | awk -F: '$3 == '"$(id -g "$username")"' {print $1}')

    secondary_groups=$(id -nG "$username" | sed -e "s/$primary_group//" -e "s/ /,/g")

    sudo_status=""
    if groups "$username" | grep -qw "sudo"; then
        sudo_status="OUI"
    else
        sudo_status="NON"
    fi

    dir_size=$(du -sh "$home_directory" 2>/dev/null | cut -f1)

    IFS=' ' read -r first_name last_name <<< "$full_name"

    if [ "$1" = "-G" ]; then
        if [ "$GroupMain" != "$2" ]; then
            filter=1
        fi
    fi

    if [ "$1" = "-g" ]; then
        if ! echo "$secondary_groups" | grep -q "$2"; then
            filter=1
        fi
    fi

    if [ "$filter" -eq 0 ]; then
        echo "Utilisateur: $login"
        echo "Prenom: $first_name"
        echo "Nom: $last_name"
        echo "Groupe Principal: $GroupMain"
        echo "Autre groupes: $secondary_groups"
        echo "Taille du rep personnel: $dir_size"
        echo "Sudo: $sudo_status"
        echo "-----------------------------------"
    fi
done < <(getent passwd | grep -vE "nologin|false")
