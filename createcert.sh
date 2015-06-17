#!/bin/bash

function try {
    "$@"
    local status=$?
    if [ $status -ne 0 ]; then
        echo -e "\nError with $1" >&2
        exit $?
    fi
    return $status
}

function create_cert() {
    if [[ ! -f $HOME/.config/nuntius/nuntius.pem || ! -f $HOME/.config/nuntius/nuntius.key ]]; then
        echo "Creating cert..."
        cd $HOME/.config/nuntius
        try openssl genrsa -out nuntius.key 2048
        try openssl req -new -key nuntius.key -out nuntius.csr -subj "/O=Holylobster/OU=Nuntius"
        try openssl x509 -req -days 3650 -in nuntius.csr -signkey nuntius.key -out nuntius.crt
        try openssl x509 -in nuntius.crt -out nuntius.pem
        exit $?
    else
        echo "Certificate already exist..."
        exit 0
    fi
}

if [[ ! -d $HOME/.config/nuntius ]]; then
    echo "Creating nuntius config directory..."
    mkdir -p $HOME/.config/nuntius
fi

create_cert

# ex:set ts=4 et:
