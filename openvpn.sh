#!/bin/bash

keys=keys
openssl=/usr/bin/openssl
openvpn=/sbin/openvpn


ca_conf=${keys}/ca.cnf
srv_conf=${keys}/server.cnf
cli_conf=${keys}/client.cnf


if [ -d ${keys} ]; then
 rm -Rf ${keys}/*
else
 mkdir keys
fi

cat >${ca_conf}<<EOF
[ req ]
default_bits = 8192 
default_md = sha256
prompt = no
encrypt_key = no
distinguished_name = dn
[ dn ]
C = RU
O = vrnnet.ru
CN = ca
EOF



cat >${srv_conf}<<EOF
[ req ]
default_bits = 8192 
default_md = sha256
prompt = no
encrypt_key = no
distinguished_name = dn
[ dn ]
C = RU
O = vrnnet.ru
CN = server 
EOF



cat >${cli_conf}<<EOF
[ req ]
default_bits = 8192 
default_md = sha256
prompt = no
encrypt_key = no
distinguished_name = dn
[ dn ]
C = RU
O = vrnnet.ru
CN = client
EOF

echo "Generaing CA private key"
${openssl} genrsa -out ./${keys}/ca.key 8192 

echo "Generating self-signed CA cert"
${openssl} req -x509 -config ${ca_conf} -sha256 -new ${PARAMS} -nodes -key ./${keys}/ca.key -days 3650 -out ./${keys}/ca.crt

echo "Generating server key and cert"
${openssl} req -new -config ${srv_conf} -newkey rsa:8192 -nodes -keyout ./${keys}/server.key -out ./${keys}/server.csr


echo "Generating client key and cert"
${openssl} req -new -config ${cli_conf} -newkey rsa:8192 -nodes -keyout ./${keys}/client.key -out ./${keys}/client.csr

echo "Signing server certificate"
${openssl} x509 -req -days 360 -in ./${keys}/server.csr -CA ./${keys}/ca.crt -CAkey ./${keys}/ca.key -CAcreateserial -out ./${keys}/server.crt



echo "Signing client certificate"
${openssl} x509 -req -days 360 -in ./${keys}/client.csr -CA ./${keys}/ca.crt -CAkey ./${keys}/ca.key -CAcreateserial -out ./${keys}/client.crt


echo "Removing openssl configs"
rm ${ca_conf}
rm ${srv_conf}
rm ${cli_conf}


echo "Removing CA key"
rm ${keys}/ca.key

echo "Removing signing requests"
rm ${keys}/server.csr
rm ${keys}/client.csr
rm ${keys}/ca.srl

echo "Generating DH"
${openssl} dhparam -out ./${keys}/dh2048.pem 2048

echo "Generating ta.key"
${openvpn} --genkey secret ./${keys}/ta.key

echo "Keys are generated"

echo "Generating OpenVPN Server config"
cat >server.conf<<EOF
proto tcp
port 10194
dev tun0
ca /etc/openvpn/keys/ca.crt
cert /etc/openvpn/keys/server.crt
key /etc/openvpn/keys/server.key
dh /etc/openvpn/keys/dh2048.pem
tls-auth /etc/openvpn/keys/ta.key 0
topology subnet
server 172.31.217.64 255.255.255.224
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
keepalive 5 35
cipher AES-256-GCM
persist-key
persist-tun
status openvpn-status.log
verb 0
daemon
EOF

echo "Generating OpenVPN Client config"
cat >client.conf<<EOF
client
proto tcp
dev tun0
remote 90.156.230.243 10194
dhcp-option DNS 8.8.8.8
dhcp-option DNS 8.8.4.4
resolv-retry infinite
nobind
persist-key
persist-tun
ca /etc/openvpn/keys/ca.crt
cert /etc/openvpn/keys/client.crt
key /etc/openvpn/keys/client.key
tls-auth /etc/openvpn/keys/ta.key 1
key-direction 1
cipher AES-256-GCM
verb 3
keepalive 5 35
daemon
EOF

