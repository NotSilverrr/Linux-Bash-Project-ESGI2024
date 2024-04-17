#!/bin/bash

# User data source file path
SOURCE_FILE="user_data.txt"

# Check if the source file exists
if [ ! -f "$SOURCE_FILE" ]; then
    echo "Source file does not exist: $SOURCE_FILE"
    exit 1
fi

while IFS=: read -r firstname lastname groups sudo password
do
    # Generate the username (first letter of firstname + lastname)
    username=$(echo "${firstname:0:1}$lastname" | tr '[:upper:]' '[:lower:]')

    # Handle duplicate usernames
    orig_username=$username
    suffix=1
    while id -u $username &>/dev/null; do
        username="${orig_username}${suffix}"
        suffix=$((suffix+1))
    done

    # Parse groups
    IFS=',' read -ra ADDR <<< "$groups"
    primary_group="${ADDR[0]}"
    secondary_groups="${ADDR[@]:1}"

    # Create primary group if it does not exist
    if ! getent group "$primary_group" &>/dev/null; then
        groupadd "$primary_group"
    fi

    # Create user with primary group
    useradd -m -g "$primary_group" -c "$firstname $lastname" -p "$(openssl passwd -crypt $password)" "$username"

    # Set user to change password on first login
    chage -d 0 "$username"

    # Add user to secondary groups
    for group in $secondary_groups; do
        if ! getent group "$group" &>/dev/null; then
            groupadd "$group"
        fi
        usermod -aG "$group" "$username"
    done

    # Check if user should have sudo privileges
    if [ "$sudo" == "oui" ]; then
        usermod -aG sudo "$username"
    fi

    # Populate user's home directory with random files
    for i in $(seq 1 $((RANDOM % 6 + 5))); do
        dd if=/dev/urandom of="/home/$username/file_$i" bs=1M count=$((RANDOM % 46 + 5)) &>/dev/null
    done

done < "$SOURCE_FILE"

echo "User creation completed."
