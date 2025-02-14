#!/bin/bash
# Script to automate OpenVPN and EasyRSA setup on Linux Mint 22
# Run this script as root.
 
# Check for root privileges
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root." >&2
    exit 1
fi
 
# Update and install OpenVPN and EasyRSA
apt update && apt install -y openvpn easy-rsa
 
# Create necessary directories
mkdir -p /etc/openvpn/server /etc/openvpn/easy-rsa/clients
 
# Copy server configuration file
cat <<EOF > /etc/openvpn/server/server.conf
port 1194
proto tcp
dev tun
ca ca.crt
cert server.crt
key server.key  # This file should be kept secret
dh dh.pem
tls-crypt-v2 server.pem
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist /var/log/openvpn/ipp.txt
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 208.67.222.222"
keepalive 10 120
cipher AES-256-GCM
user nobody
group nogroup
persist-key
persist-tun
status /var/log/openvpn/openvpn-status.log
verb 3
EOF
 
# Set up EasyRSA
cp -Ra /usr/share/easy-rsa/ /etc/openvpn/easy-rsa
cd /etc/openvpn/easy-rsa
cp vars.example vars
cp openssl-easyrsa.cnf openssl.cnf

# Prompt user for EasyRSA details
echo "Enter your country code (e.g., US):"
read COUNTRY
echo "Enter your state/province (e.g., State):"
read PROVINCE
echo "Enter your city (e.g., City):"
read CITY
echo "Enter your organization name:"
read ORG
echo "Enter your email address:"
read EMAIL
echo "Enter your Organizational Unit (OU):"
read OU

# Update EasyRSA vars file
sed -i "s/^set_var EASYRSA_REQ_COUNTRY.*/set_var EASYRSA_REQ_COUNTRY    \"$COUNTRY\"/" vars
sed -i "s/^set_var EASYRSA_REQ_PROVINCE.*/set_var EASYRSA_REQ_PROVINCE   \"$PROVINCE\"/" vars
sed -i "s/^set_var EASYRSA_REQ_CITY.*/set_var EASYRSA_REQ_CITY       \"$CITY\"/" vars
sed -i "s/^set_var EASYRSA_REQ_ORG.*/set_var EASYRSA_REQ_ORG        \"$ORG\"/" vars
sed -i "s/^set_var EASYRSA_REQ_EMAIL.*/set_var EASYRSA_REQ_EMAIL      \"$EMAIL\"/" vars
sed -i "s/^set_var EASYRSA_REQ_OU.*/set_var EASYRSA_REQ_OU         \"$OU\"/" vars
 
# Build PKI and certificates
./easyrsa init-pki
echo | ./easyrsa build-ca nopass
./easyrsa build-server-full server nopass
echo yes | ./easyrsa sign-req server server
./easyrsa gen-dh
openvpn --genkey tls-crypt-v2-server /etc/openvpn/server/server.pem
 
# Move certificates and keys
cp pki/ca.crt pki/dh.pem pki/private/server.key pki/issued/server.crt /etc/openvpn/server/
 
# Enable IP forwarding
sed -i '/^net.ipv4.ip_forward/s/0/1/' /etc/sysctl.conf
sysctl -p
 
# Configure firewall (UFW)
default_int=$(ip route list default | awk '{ print $5 }')
cat <<EOF > /etc/ufw/before.rules
*nat
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -s 10.8.0.0/24 -o $default_int -j MASQUERADE
COMMIT
EOF
 
sed -i 's/^DEFAULT_FORWARD_POLICY.*/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw
ufw allow 1194/tcp
ufw disable
ufw enable
 
# Enable and start OpenVPN service
systemctl enable openvpn-server@server.service
systemctl start openvpn-server@server.service
 
# Prompt user for external IP
echo "Enter your server's external IP or domain:"
read SERVER_IP
 
# Generate client configuration script
cat <<'EOC' > /usr/local/bin/create-client-config.sh
#!/bin/bash
CLIENT_PATH=/etc/openvpn/server/clients
cd /etc/openvpn/easy-rsa
if [ -z "$1" ]; then
  echo "Usage: $0 <client_name>"
  exit 1
fi
 
mkdir -p $CLIENT_PATH/$1
echo | ./easyrsa gen-req $1 nopass
echo yes | ./easyrsa sign-req client $1
openvpn --tls-crypt-v2 /etc/openvpn/server/server.pem --genkey tls-crypt-v2-client /etc/openvpn/server/$1.pem
cp pki/ca.crt pki/issued/$1.crt pki/private/$1.key /etc/openvpn/server/$1.pem $CLIENT_PATH/$1
 
cat <<EOF > /etc/openvpn/server/clients/$1/$1.ovpn
client
dev tun
proto tcp
remote $SERVER_IP 1194
resolv-retry infinite
nobind
tls-client
cipher AES-256-GCM
remote-cert-tls server
persist-key
persist-tun
verb 3
<ca>
$(cat $CLIENT_PATH/$1/ca.crt)
</ca>
<cert>
$(cat $CLIENT_PATH/$1/$1.crt)
</cert>
<key>
$(cat $CLIENT_PATH/$1/$1.key)
</key>
<tls-crypt-v2>
$(cat $CLIENT_PATH/$1/$1.pem)
</tls-crypt-v2>
EOF
 
USER_NAME=$(who | awk 'NR==1{print $1}')
chown $USER_NAME:$USER_NAME $CLIENT_PATH/$1/$1.ovpn
EOC
 
chmod +x /usr/local/bin/create-client-config.sh
 
# Final message
echo "Setup complete. Use /usr/local/bin/create-client-config.sh to create client configurations."
exit 0

