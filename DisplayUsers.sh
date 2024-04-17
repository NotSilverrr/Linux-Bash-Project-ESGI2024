#!/bin/bash

# Function to display user details
display_user() {
    local username=$1
    local user_info=$(getent passwd "$username")
    local IFS=':'
    read -ra info <<< "$user_info"
    local login="${info[0]}"
    local uid="${info[2]}"
    local gid="${info[3]}"
    local full_name="${info[4]}"
    local home_directory="${info[5]}"
    local shell="${info[6]}"

    # Get primary group name
    local primary_group=$(getent group | awk -F: '$3 == '"$gid"' {print $1}')

    # Get secondary groups
    local secondary_groups=$(id -nG "$username" | sed -e "s/$primary_group//" -e "s/ /, /g")

    # Check sudo privileges
    local sudo_status="NON"
    if groups "$username" | grep -qw "sudo"; then
        sudo_status="OUI"
    fi

    # Calculate directory size
    local dir_size=$(du -sh "$home_directory" 2>/dev/null | cut -f1)

    echo "Utilisateur: $login"
    echo "Prénom: ${full_name%% *}"
    echo "Nom: ${full_name##* }"
    echo "Groupe primaire: $primary_group"
    echo "Groupes secondaires: $secondary_groups"
    echo "Répertoire personnel: $dir_size"
    echo "Sudoer: $sudo_status"
    echo "-----------------------------------"
}

# Options handling
while getopts ":G:g:s:u:" opt; do
    case $opt in
        G)
            primary_group_filter=$OPTARG
            ;;
        g)
            secondary_group_filter=$OPTARG
            ;;
        s)
            sudo_filter=$OPTARG
            ;;
        u)
            user_filter=$OPTARG
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

# Filter and display users based on options
while IFS=: read -r username _ _ uid _ _ _; do
    if [ -n "$user_filter" ] && [ "$username" != "$user_filter" ]; then
        continue
    fi
    if [ -n "$primary_group_filter" ] && [ "$(id -gn "$username")" != "$primary_group_filter" ]; then
        continue
    fi
    if [ -n "$secondary_group_filter" ]; then
        local secondary_groups=$(id -nG "$username")
        if [[ "$secondary_groups" != *"$secondary_group_filter"* ]]; then
            continue
        fi
    fi
    if [ -n "$sudo_filter" ]; then
        local is_sudoer=$(groups "$username" | grep -c "sudo")
        if [ "$sudo_filter" -eq 0 ] && [ "$is_sudoer" -ne 0 ] || [ "$sudo_filter" -eq 1 ] && [ "$is_sudoer" -eq 0 ]; then
            continue
        fi
    fi
    display_user "$username"
done < <(getent passwd | grep -vE "nologin|false")
