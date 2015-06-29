#!/bin/bash

function createCert(){
	if [[ ! -f $HOME/.config/nuntius/nuntius.pem || ! -f $HOME/.config/nuntius/nuntius.key ]]; then
		echo "Creating cert..."
		cd $HOME/.config/nuntius
		openssl genrsa -out nuntius.key 2048
		openssl req -new -key nuntius.key -out nuntius.csr -subj "/O=Holylobster/OU=Nuntius"
		openssl x509 -req -days 3650 -in nuntius.csr -signkey nuntius.key -out nuntius.crt
		openssl x509 -in nuntius.crt -out nuntius.pem
		exit $?
	else
		echo "Certificate already exist..."
		exit 0
	fi
}

if [[ ! -d $HOME/.config/nuntius ]]; then
	echo "Creating nuntius config directory..."
	mkdir $HOME/.config/nuntius
fi
createCert