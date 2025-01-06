#!/bin/bash
#
# Generate CSR
#
# Repo:
# https://github.com/eidenschink/generate-csr.git
#

# Exit on errors
set -euo pipefail

# Only search executables in these PATHS
PATH=/bin:/usr/bin:/sbin

EXIT_USAGE=1
EXIT_COMMAND_NOT_FOUND=2
EXIT_INVALID_ARGS=3
EXIT_FILE_EXISTS=4
EXIT_OPENSSL_FAILURE=5

REQUIRED_COMMANDS=("openssl" "uuidgen" "md5sum" "ls")

check_commands() {
    for cmd in "${REQUIRED_COMMANDS[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "Error: '$cmd' not found."
            exit "$EXIT_COMMAND_NOT_FOUND"
        fi
    done
}

show_usage() {
    cat <<USAGE
Create RSA private key and Certificate Signing Request file (CSR)

Usage: $0 -create-config -domain <domain>
       Create a config file for openssl for unattended CSR generation

       $0 [[-win] [-bits <key bit length; default 2048>] [-algo <default -aes-256-cbc>] [-nopass]] -domain <domain>
       -nopass          Do not ask for a pass phrase to protect the key
       -win             Same as -nopass to make it work for Apache on Windows
USAGE
    exit "$EXIT_USAGE"
}

create_config() {
    local domain="$1"
    local config_file="${domain#www.}.cnf"

    cat >"$config_file" <<End-of-message
[req]
prompt = no
distinguished_name = dn
req_extensions = ext
# Remove input_password line for no passphrase on key
input_password = $(openssl rand -base64 16)

[dn]
# Note: the CN is ignored if you configure subjectAltName (focus on that)
CN = ${domain}
emailAddress = webmaster@${domain#www.}
O = Organisation Name
L = City
# Country code like DE, EN, ...
C = DE

[ext]
# E.g. DNS:www.example.com,DNS:example.com
subjectAltName = DNS:${domain},DNS:${domain#www.}
End-of-message

    echo "Config file '$config_file' created. Make necessary changes then run again:"
    echo "$0 -domain ${domain}"
    exit "$EXIT_INVALID_ARGS"
}

generate_private_key() {
    local domain="$1"
    local bits="$2"
    local encalgo="$3"

    echo -e "\n\nCreate key file '$domain.key' with a key length of $bits and encryption algorithm '$encalgo'"
    if ! openssl genpkey -out "${domain}.key" \
        -algorithm RSA \
        -pkeyopt rsa_keygen_bits:"$bits" \
        $encalgo; then
        echo "Error: private key could not be created"
        exit "$EXIT_OPENSSL_FAILURE"
    fi
}

generate_csr() {
    local domain="$1"
    local config_file="${domain#www.}.cnf"

    if [[ -f "$config_file" ]]; then
        echo "Found '$config_file', create CSR non-interactively"
        echo "openssl req -new -config $config_file -key ${domain}.key -out ${domain}.csr"
        if ! openssl req -new -config "$config_file" -key "${domain}.key" -out "${domain}.csr"; then
            echo "Error: Creating CSR file failed"
            exit "$EXIT_OPENSSL_FAILURE"
        fi
    else
        echo -e "\n\nCreate CSR file '${domain}.csr' with '${domain}.key'"
        echo "When asked for the 'Common Name', enter the domain like www.example.com"
        if ! openssl req -new -key "${domain}.key" -out "${domain}.csr"; then
            echo "Error: Creating the CSR file failed"
            exit "$EXIT_OPENSSL_FAILURE"
        fi
    fi
}

display_csr_info() {
    local domain="$1"

    if [[ -f "${domain}.csr" ]]; then
        openssl req -text -in "${domain}.csr" -noout
        echo "Successfully created:"
        ls "${domain}"*
        exit 0
    else
        echo "Error: CSR file '${domain}.csr' not created"
        exit "$EXIT_OPENSSL_FAILURE"
    fi
}

main() {
    check_commands

    if [[ "$#" -eq 0 ]]; then
        show_usage
    fi

    if [[ "${1}" == "-create-config" ]]; then
        if [[ "${2:-}" == "-domain" && -n "${3:-}" ]]; then
            create_config "$3"
        else
            echo "Error: '-create-config' expects '-domain <domain>'"
            exit "$EXIT_INVALID_ARGS"
        fi
    fi

    # Defaults
    ENCALGO="-aes-256-cbc"
    BITS="2048"
    DOM=""

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            "-win" | "-nopass")
                ENCALGO=""
                ;;
            "-bits")
                shift
                BITS="$1"
                ;;
            "-algo")
                shift
                ENCALGO="$1"
                ;;
            "-create-config")
                echo "Combining '-create-config' with other options not allowed"
                exit "$EXIT_INVALID_ARGS"
                ;;
            "-domain")
                shift
                DOM="$1"
                ;;
            *)
                echo "Unknown argument: $1"
                exit "$EXIT_INVALID_ARGS"
                ;;
        esac
        shift
    done

    if [[ -z "$DOM" ]]; then
        echo "Error: '-domain' mandatory"
        exit "$EXIT_INVALID_ARGS"
    fi

    for file in "${DOM}.key" "${DOM}.csr"; do
        if [[ -f "$file" ]]; then
            echo "Error: File '$file' already existing"
            exit "$EXIT_FILE_EXISTS"
        fi
    done

    CONFIG_FILE="${DOM#www.}.cnf"
    if [[ -f "$CONFIG_FILE" ]]; then
        if ! grep -q "^input_password\s*=" "$CONFIG_FILE"; then
            ENCALGO=""
            echo "No 'input_password' in '$CONFIG_FILE'. Create key without passphrase"
        else
            echo "'input_password' in '$CONFIG_FILE' found. Key creation with passphrase"
        fi
    fi

    echo "** Generate private key"
    generate_private_key "$DOM" "$BITS" "$ENCALGO"

    echo "** Generate CSR"
    generate_csr "$DOM"

    echo "** Display CSR info"
    display_csr_info "$DOM"
}

main "$@"
