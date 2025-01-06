generate-csr.sh
===============

Create a Certificate Signing Request file either by creating and editing a config
file for the CSR options first:

```
./generate-csr.sh -create-config -domain www.example.com
Config file 'example.com.cnf' created. Make necessary changes then run again:
./generate-csr.sh -domain www.example.com
```

or by running it more interactively:

```
./generate-csr.sh -domain www.example.com
```

Usage:

```
$ ./generate-csr.sh
Create RSA private key and Certificate Signing Request file (CSR)

Usage: ./generate-csr.sh -create-config -domain <domain>
       Create a config file for openssl for unattended CSR generation

       ./generate-csr.sh [[-win] [-bits <key bit length; default 2048>] [-algo <default -aes-256-cbc>] [-nopass]] -domain <domain>
       -nopass          Do not ask for a pass phrase to protect the key
       -win             Same as -nopass to make it work for Apache on Windows
```
