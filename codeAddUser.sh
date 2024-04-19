#!/bin/bash

if [ ! -f $1 ]; then
    echo "Le ficher sélectionné est invalide: $1"
    exit 1
fi

while IFS=: read -r firstname lastname groups sudo password
do
    username="${firstname:0:1}$lastname"
    Newusername=$username
    suffix=1
    while id -u $Newusername &>/dev/null; do
        Newusername="${username}${suffix}"
        suffix=$((suffix+1))
    done

    IFS=',' read -ra GroupArray <<< "$groups"
    GroupMain="${GroupArray[0]}"
    GroupSecond="${GroupArray[@]:1}"

    if ! getent group "$GroupMain" &>/dev/null; then
        groupadd "$GroupMain"
    fi
    Hpassword=$(openssl passwd -6 "$password")
    useradd -m -g "$GroupMain" -c "$firstname $lastname" -p "$Hpassword" "$Newusername"

    for group in $GroupSecond; do
        if ! getent group "$group" &>/dev/null; then
            groupadd "$group"
        fi
        usermod -aG "$group" "$Newusername"
    done

    if [ "$sudo" == "oui" ]; then
        usermod -aG sudo "$Newusername"
    fi

    for i in $(seq 1 $((RANDOM % 6 + 5))); do
        touch "/home/$Newusername/fichierNum$i"
        head -c $((RANDOM % 46 + 5))M /dev/urandom > "/home/$Newusername/fichierNum$i" &>/dev/null
    done

    echo 'export PS1="\u@\h:\w\$ "' >> "/home/$Newusername/.bashrc"
    echo "User $Newusername created!"
done < $1