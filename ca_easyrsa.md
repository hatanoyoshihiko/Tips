# Hot to set Private CA using easyrsa

## Initial settings

### Install Package

```bash
# apt install easy-rsa
# apt install openssl
```

### Initialize

```bash
# mkdir ~/easy-rsa
# ln -s /usr/share/easy-rsa/* ~/easy-rsa/
# chmod 700 ~/easy-rsa
# cd ~/easy-rsa
# ./easyrsa init-pki
```

### Config setting

- easyrsa var

```bash
# cd ~/easy-rsa
# cp -p vars.example vars
# vi vars
set_var EASYRSA_REQ_COUNTRY	"JP"
set_var EASYRSA_REQ_PROVINCE	"Hyogo"
set_var EASYRSA_REQ_CITY	"Himeji City"
set_var EASYRSA_REQ_ORG		"alessiareyai Ltd."
set_var EASYRSA_REQ_EMAIL	"admin@alessiareya.local"
set_var EASYRSA_REQ_OU		"Devlopment"
set_var EASYRSA_KEY_SIZE	4096
set_var EASYRSA_ALGO		ec
set_var EASYRSA_CURVE		secp384r1
set_var EASYRSA_CA_EXPIRE	365
set_var EASYRSA_CERT_EXPIRE	365
set_var EASYRSA_SSL_CONF	"$EASYRSA/openssl-easyrsa.cnf"
set_var EASYRSA_DIGEST		"sha512"
```

- openssl config

```
# vi openssl-easyrsa.cnf
RANDFILE		= $ENV::EASYRSA_PKI/.rnd
[ ca ]
default_ca	= CA_default		# The default ca section
[ CA_default ]
dir		= $ENV::EASYRSA_PKI	# Where everything is kept
certs		= $dir			# Where the issued certs are kept
crl_dir		= $dir			# Where the issued crl are kept
database	= $dir/index.txt	# database index file.
new_certs_dir	= $dir/certs_by_serial	# default place for new certs.
certificate	= $dir/ca.crt	 	# The CA certificate
serial		= $dir/serial 		# The current serial number
crl		= $dir/crl.pem 		# The current CRL
private_key	= $dir/private/ca.key	# The private key
RANDFILE	= $dir/.rand		# private random number file
x509_extensions	= basic_exts		# The extentions to add to the cert
crl_extensions	= crl_ext
default_days	= $ENV::EASYRSA_CERT_EXPIRE	# how long to certify for
default_crl_days= $ENV::EASYRSA_CRL_DAYS	# how long before next CRL
default_md	= $ENV::EASYRSA_DIGEST		# use public key default MD
preserve	= no			# keep passed DN ordering
unique_subject	= no
policy		= policy_anything
[ policy_anything ]
countryName		= optional
stateOrProvinceName	= optional
localityName		= optional
organizationName	= optional
organizationalUnitName	= optional
commonName		= supplied
name			= optional
emailAddress		= optional
[ req ]
default_bits		= $ENV::EASYRSA_KEY_SIZE
default_keyfile 	= privkey.pem
default_md		= $ENV::EASYRSA_DIGEST
distinguished_name	= $ENV::EASYRSA_DN
x509_extensions		= easyrsa_ca	# The extentions to add to the self signed cert
req_extensions 		= v3_req
basicConstraints 	= CA:TRUE
keyUsage 		= nonRepudiation, digitalSignature, keyEncipherment
subjectAltName 		= @alt_names
[ v3_req ]
basicConstraints	= CA:TRUE
keyUsage 		= nonRepudiation, digitalSignature, keyEncipherment
subjectAltName 		= @alt_names
[ cn_only ]
commonName		= Common Name (eg: your user, host, or server name)
commonName_max		= 64
commonName_default	= $ENV::EASYRSA_REQ_CN
[ org ]
countryName			= Country Name (2 letter code)
countryName_default		= $ENV::EASYRSA_REQ_COUNTRY
countryName_min			= 2
countryName_max			= 2
stateOrProvinceName		= State or Province Name (full name)
stateOrProvinceName_default	= $ENV::EASYRSA_REQ_PROVINCE
localityName			= Locality Name (eg, city)
localityName_default		= $ENV::EASYRSA_REQ_CITY
0.organizationName		= Organization Name (eg, company)
0.organizationName_default	= $ENV::EASYRSA_REQ_ORG
organizationalUnitName		= Organizational Unit Name (eg, section)
organizationalUnitName_default	= $ENV::EASYRSA_REQ_OU
commonName			= Common Name (eg: your user, host, or server name)
commonName_max			= 64
commonName_default		= $ENV::EASYRSA_REQ_CN
emailAddress			= Email Address
emailAddress_default		= $ENV::EASYRSA_REQ_EMAIL
emailAddress_max		= 64
[ basic_exts ]
basicConstraints	= CA:TRUE
subjectKeyIdentifier	= hash
authorityKeyIdentifier	= keyid,issuer:always
[ easyrsa_ca ]
nsCertType                      = client, server, email
subjectKeyIdentifier 		= hash
authorityKeyIdentifier 		= keyid:always,issuer:always
subjectAltName 			= @alt_names
basicConstraints 		= CA:TRUE
keyUsage 			= cRLSign, keyCertSign
[ crl_ext ]
authorityKeyIdentifier = keyid:always,issuer:always
[ alt_names ]
DNS.1 = alessiareya.local
DNS.2 = *.alessiareya.local
```

### Create CA

`# ./easyrsa build-ca nopass`

### copy ca file to other server

```bash
- Ubuntu and Debian distributions
# scp ~/easy-rsa/pki/ca.crt /usr/local/share/ca-certificates/
# update-ca-certificates

- Redhat and CentOS distributions
# cp ~/easy-rsa/pki/ca.crt /etc/pki/ca-trust/source/anchors/
# update-ca-trust
```

## Create Private Key and CSR Request

```bash
# ./easyrsa --subject-alt-name='DNS:alessiareya.local,DNS:*.alessiareya.local' gen-req alessiareya.local nopass
```

## Import and Sign CSR

```
# ./easyrsa import-req alessiareya.local.server.csr alessiareya.local
# ./easyrsa --subject-alt-name='DNS:alessiareya.local,DNS:*.alessiareya.local' sign-req server alessiareya.local
```


## Check CRT

```
# openssl x509 -text -in pki/issued/alessiareya.local.crt -noout
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            d3:7e:f5:9c:23:da:b4:c5:2d:26:83:ee:6e:9d:44:96
        Signature Algorithm: ecdsa-with-SHA512
        Issuer: CN = Easy-RSA CA
        Validity
            Not Before: Apr 29 00:41:24 2021 GMT
            Not After : Apr 29 00:41:24 2022 GMT
        Subject: CN = *.alessiareya.local
        Subject Public Key Info:
            Public Key Algorithm: id-ecPublicKey
                Public-Key: (384 bit)
                pub:
                    04:d1:97:88:3b:0d:38:9a:18:06:c3:4d:ba:cd:7b:
                    40:38:97:eb:18:b6:8d:39:a4:d1:38:8f:c9:27:70:
                    fd:d9:2c:53:38:a4:2e:ab:e8:c7:61:d2:d2:f0:f4:
                    22:ef:07:a7:01:3b:43:89:8b:f3:ff:ef:3c:1d:85:
                    26:75:27:0f:b9:98:72:67:9f:8e:47:bf:d8:34:93:
                    9f:c9:ac:9f:a4:08:af:9a:c9:7f:bc:01:df:a0:97:
                    6f:34:7c:bd:e0:b2:3c
                ASN1 OID: secp384r1
                NIST CURVE: P-384
        X509v3 extensions:
            X509v3 Basic Constraints:
                CA:FALSE
            X509v3 Subject Key Identifier:
                91:20:65:6B:4B:30:C7:19:31:B4:9B:80:60:24:B9:C6:E7:16:90:D7
            X509v3 Authority Key Identifier:
                keyid:EC:8C:C7:2D:C7:13:49:45:3F:A9:E3:D7:91:1D:47:F8:9E:EC:E2:9F
                DirName:/CN=Easy-RSA CA
                serial:53:BF:C2:27:9D:CC:4E:34:48:49:89:91:E7:C4:93:65:C5:A1:57:7C

            X509v3 Extended Key Usage:
                TLS Web Server Authentication
            X509v3 Key Usage:
                Digital Signature, Key Encipherment
            X509v3 Subject Alternative Name:
                DNS:alessiareya.local, DNS:*.alessiareya.local
    Signature Algorithm: ecdsa-with-SHA512
         30:64:02:30:1a:17:4d:14:5b:2b:ab:b2:b9:59:d2:79:37:19:
         07:94:38:20:f7:cc:a2:a4:03:15:b9:14:1f:f2:bb:da:92:1a:
         e6:ab:79:d4:20:05:1f:e0:92:76:3e:fa:59:e2:10:f8:02:30:
         40:22:9b:b2:f2:d0:cc:36:a9:e4:26:89:07:4b:74:29:e5:9c:
         2b:94:eb:98:cc:8d:b4:1c:fc:88:c7:a0:44:72:ec:f4:b6:b9:
         57:8a:bd:f8:b9:15:bd:e2:16:07:94:3b
```

## Distribute CRT and Private Key

```bash
# ls ../easy-rsa/pki/issued/alessiareya.local.crt
# ls ../easy-rsa/private-csr/alessiareya.local.server.key
```

## revoke certificate

```bash
# ./easyrsa revoke COMMON_NAME
# ./easyrsa revoke alessiareya.local
```
