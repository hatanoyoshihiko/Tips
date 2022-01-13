# Hot to set Private CA using openssl

## Create CA

### Install Package

```bash
# apt install openssl
```

### Config setting

- openssl config

```
# mkdir ssl
# mkdir {newcerts,private,certs,req,crl}
# vi /etc/ssl/openssl.cnf
```

### Create CA Certificate

- Create CA private key

`# openssl ecparam -genkey -name secp384r1 -out private/ca.key`

- Create CSR

```bash
# openssl req -new -key private/ca.key -out req/ca.csr -subj "/CN=alessiareya CA"
# openssl req -text -noout -in ca.csr
```

- Sign CSR(Create CA Certificate)

```bash
# openssl x509 -req -in req/ca.csr -signkey private/ca.key -days 365 -out ca.crt -extensions v3_ext -extfile ca.cnf
## openssl ca -policy policy_anything -in private/ca.key -out ca.crt -days 365 -extensions v3_ext -extfile ca.cnf
## openssl ca -policy policy_anything -in req/ca.csr -out /newcerts/ca.crt -days 365 -config ca.cnf -extensions v3_ext -extfile ca.cnf
# openssl x509 -text -in ca.crt -noout
```

---

## Create Server Certificate

`# openssl genrsa 2048 > alessiareya.local.key`

### Create CSR

```bash
# openssl req -new -key alessiareya.local.key -out alessiareya.local.csr \
  -subj "/CN=*.alessiareya.local" \
  -config alessiareya.local.cnf -out alessiareya.local.csr

## openssl req -new -key alessiareya.local.key -out alessiareya.local.csr \
##  -subj "/C=JP/ST=Hyogo/L=Himeji City/O=alessiareya Ltd./OU=Devlopment/CN=*.alessiareya.local" \
##  -config alessiareya.local.cnf -out alessiareya.local.csr


## openssl req -new -key alessiareya.local.key -config alessiareya.local.cnf -out alessiareya.local.csr
# openssl req -text -noout -in alessiareya.local.csr
```

### Sign CSR

```bash
# openssl x509 -req -in alessiareya.local.csr -CA ca.crt -CAkey private/ca.key -CAcreateserial -days 365 \
  -extensions v3_ext -extfile alessiareya.local.cnf -out alessiareya.local.crt

## openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -days 365 \
  -extensions v3_ext -extfile csr.conf \
  -out server.crt
```


### Check CRT

```bash
# openssl x509 -text -in alessiareya.local.crt -noout
CCertificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            16:d3:57:50:05:2d:b4:50:f1:3c:cd:9e:ca:b6:dc:67:f7:02:18:f0
        Signature Algorithm: ecdsa-with-SHA256
        Issuer: CN = ROOT CA
        Validity
            Not Before: Apr 29 03:14:55 2021 GMT
            Not After : Apr 29 03:14:55 2022 GMT
        Subject: CN = *.alessiareya.local
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (2048 bit)
                Modulus:
                    00:d9:78:00:99:4c:ed:37:f6:04:33:89:38:86:60:
                    fe:2b:c3:63:58:0d:3f:7b:05:2e:be:f5:95:48:65:
                    45:9b:a6:21:3e:2c:06:3f:74:5c:48:85:a9:79:86:
                    66:b3:9c:c7:40:60:0b:89:65:84:c4:c0:16:16:bb:
                    32:2c:76:04:e4:18:d6:1b:51:27:be:83:6f:ce:22:
                    54:5f:88:cb:70:e1:2b:f1:c8:79:78:c5:5a:b8:50:
                    60:11:ea:82:77:1f:15:b6:1e:be:40:5c:28:34:70:
                    6d:a0:24:11:a8:b6:89:2f:95:d6:35:8a:a4:a9:5a:
                    0e:f6:39:dd:ab:f5:0e:e9:ef:02:73:e4:ba:cb:35:
                    44:f0:18:54:0a:ed:16:73:18:7a:50:bc:3b:79:56:
                    4a:6a:ca:27:22:f6:af:18:33:6f:5d:1d:13:43:fa:
                    ab:cf:a0:06:7e:1a:c1:62:c5:11:6d:86:bd:3c:55:
                    52:26:b9:c5:08:f7:64:7a:a5:b7:aa:be:89:64:be:
                    25:eb:2b:55:1d:83:2b:4c:fc:2d:3b:af:46:61:b0:
                    ef:c2:8b:a4:c3:2f:0a:2c:46:41:ab:c1:21:dc:89:
                    63:a3:31:ec:b0:3a:1f:9e:ce:79:ed:38:14:d4:6b:
                    e7:01:f2:05:59:10:90:d5:a4:e1:bd:ee:94:06:e5:
                    dd:6f
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Authority Key Identifier:
                DirName:/CN=ROOT CA
                serial:3D:57:A6:CF:4A:AB:E5:86:29:DC:B2:6C:DD:68:15:99:56:FA:5A:2E

            X509v3 Basic Constraints:
                CA:TRUE
            X509v3 Key Usage:
                Digital Signature, Non Repudiation, Key Encipherment, Data Encipherment
            X509v3 Extended Key Usage:
                TLS Web Server Authentication, TLS Web Client Authentication
            X509v3 Subject Alternative Name:
                DNS:alessiareya.local, DNS:*.alessiareya.local
    Signature Algorithm: ecdsa-with-SHA256
         30:65:02:31:00:83:82:2e:b6:f1:94:4f:7d:07:90:15:9c:92:
         3b:13:d9:27:f7:38:29:80:68:a2:cd:66:02:cc:96:5a:cd:29:
         78:6d:8d:cc:a0:6e:2f:28:d2:cd:33:9d:22:7e:f6:f4:53:02:
         30:61:33:0d:35:93:67:cb:af:34:2f:0a:b6:9b:99:ea:62:e1:
         05:90:27:bb:fe:de:52:86:d0:d1:9b:a1:67:07:8d:ed:c6:e5:
         54:f1:f5:f4:7b:a2:eb:c5:78:2a:f1:d8:7e
```

## Distribute certificate

### distribute root certificate

- Ubuntu and Debian distributions

```bash
# scp ca.crt /usr/local/share/ca-certificates/
# update-ca-certificates
```

- Redhat and CentOS distributions

```bash
# cp ca.crt /etc/pki/ca-trust/source/anchors/
# update-ca-trust
```

### distribute server private key and certificate

- Ubuntu and Debian distributions

```bash
# scp alessiareya.local.crt 192.168.11.253:/etc/ssl/certs/
# scp alessiareya.local.key 192.168.11.253:/etc/ssl/private/
# systemctl restart apache2
```

- Redhat and CentOS distributions

```bash
# scp alessiareya.local.crt 192.168.11.253:/etc/pki/tls/certs/
# scp alessiareya.local.key 192.168.11.253:/etc/pki/tls/private/
# systemctl restart apache2
```



## revoke certificate

```bash
# ./easyrsa revoke COMMON_NAME
# ./easyrsa revoke alessiareya.local
```
