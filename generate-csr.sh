#!/bin/bash
# 
# Generate CSR 
#
# Repo:
# https://github.com/eidenschink/generate-csr.git
#

PATH=/bin:/usr/bin

if [ "$#" -eq 0 ]; then
    cat <<USAGE
Usage: $0 [[-win] [-bits <key bit length; default 2048>] [-nopass]] -domain <domain>
       -nopass          Do not ask for a pass phrase to protect the key
       -win             Same as -nopass to make it work for Apache on Windows
USAGE
exit 6
fi

# defaults
DES="-aes128"
BITS="2048"

while test $# -gt 0; do
    case "$1" in
    "-win")
        DES=""
        ;;
    "-nopass")
        DES=""
        ;;
    "-bits")
        shift
        BITS=$1
        ;;
    "-domain")
        shift
        DOM=$1
        ;;
    *)
        echo "unknown arg"
        exit 12
    esac;
    shift
done

# admin, be careful.
for i in ${DOM}.key ${DOM}.csr; do
    test -f "$i" && {
        echo "$i already exists."
        exit 18
    }
done

# generate the key
echo -e "\n\nGenerating the key file ${DOM}.key with ${BITS} bit key-length"
openssl genrsa $DES -out ${DOM}.key $BITS

# generate the csr
echo -e "\n\nGenerating the CSR file ${DOM}.csr from ${DOM}.key"
echo "When asked for the 'Common Name', enter the domain like www.example.com"
openssl req -new -key ${DOM}.key -out ${DOM}.csr

# display certificate information
# this would be for the generated certificate:
# openssl x509 -in ${DOM}.crt.pem -noout -text
test -f ${DOM}.csr && {
    openssl req -in ${DOM}.csr -noout -text
    echo "Successfully created"
    ls ${DOM}*
    exit 0
}

exit 24
