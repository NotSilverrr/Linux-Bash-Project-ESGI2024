#!/bin/bash

while IFS=: read -r username _ _ _ _ _ _; do
    filter=0
    userInfo=$(getent passwd "$username")
    IFS=':' read -ra info <<< "$userInfo"
    login="${info[0]}"
    fullName="${info[4]}"
    homeDirectory="${info[5]}"
    
    GroupMain=$(getent group | awk -F: '$3 == '"$(id -g "$username")"' {print $1}')

    GroupSecond=$(id -nG "$username" | sed -e "s/$GroupMain//" -e "s/ /,/g")

    sudoStatus=""
    if groups "$username" | grep -qw "sudo"; then
        sudoStatus="OUI"
    else
        sudoStatus="NON"
    fi

    dir_size=$(du -sh "$homeDirectory" 2>/dev/null | cut -f1)

    IFS=' ' read -r firstName lastName <<< "$fullName"

    if [ "$1" = "-G" ]; then
        if [ "$GroupMain" != "$2" ]; then
            filter=1
        fi
    fi

    if [ "$1" = "-g" ]; then
        if ! echo "$GroupSecond" | grep -q "$2"; then
            filter=1
        fi
    fi

    if [ "$1" = "-s" ]; then
        if [ "$2" = "0" ] && [ "$sudoStatus" = "OUI" ]; then
            filter=1
        fi
        if [ "$2" = "1" ] && [ "$sudoStatus" = "NON" ]; then
            filter=1
        fi
    fi

    if [ "$1" = "-u" ]; then
        if [ "$login" != "$2" ]; then
            filter=1
        fi
    fi

    if [ "$filter" -eq 0 ]; then
        echo "Utilisateur: $login"
        echo "Prenom: $firstName"
        echo "Nom: $lastName"
        echo "Groupe Principal: $GroupMain"
        echo "Autre groupes: $GroupSecond"
        echo "Taille du rep personnel: $dir_size"
        echo "Sudo: $sudoStatus"
        echo "-----------------------------------"
    fi
done < <(getent passwd | grep -vE "nologin|false")
