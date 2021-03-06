#!/usr/bin/env bash

install() {

ip=$(hostname -I|cut -f1 -d ' ')
echo "Your Server IP address is:$ip"

echo -e "\e[32mInstalling gnutls-bin\e[39m"

apt install gnutls-bin
mkdir certificates
cd certificates
wget https://raw.githubusercontent.com/hybtoy/OpenConnect-VPN-Server/master/gen-client-cert.sh
wget https://raw.githubusercontent.com/hybtoy/OpenConnect-VPN-Server/master/user_add.sh
wget https://raw.githubusercontent.com/hybtoy/OpenConnect-VPN-Server/master/user_del.sh
chmod +x *.sh

cat << EOF > ca.tmpl
cn = "NET CA"
organization = "CDN"
serial = 1
expiration_days = 9999
ca
signing_key
cert_signing_key
crl_signing_key
EOF

certtool --generate-privkey --outfile ca-key.pem
certtool --generate-self-signed --load-privkey ca-key.pem --template ca.tmpl --outfile ca-cert.pem

cat << EOF > server.tmpl
#yourIP
cn=$ip
organization = "CDN"
expiration_days = 9999
signing_key
encryption_key
tls_www_server
EOF

certtool --generate-privkey --outfile server-key.pem
certtool --generate-certificate --load-privkey server-key.pem --load-ca-certificate ca-cert.pem --load-ca-privkey ca-key.pem --template server.tmpl --outfile server-cert.pem

echo -e "\e[32mInstalling ocserv\e[39m"
apt install ocserv apache2 expect lynx -y
chmod -R 777 /var/www/html
cd /etc/ocserv/
rm -rf ocserv.conf
wget https://raw.githubusercontent.com/hybtoy/OpenConnect-VPN-Server/master/ocserv.conf

sed -i -e 's@server-cert = /etc/ssl/certs/ssl-cert-snakeoil.pem@server-cert = /etc/ocserv/server-cert.pem@g' /etc/ocserv/ocserv.conf
sed -i -e 's@server-key = /etc/ssl/private/ssl-cert-snakeoil.key@server-key = /etc/ocserv/server-key.pem@g' /etc/ocserv/ocserv.conf

echo "Enter a username:"
read username

ocpasswd -c /etc/ocserv/ocpasswd $username
iptables -t nat -A POSTROUTING -j MASQUERADE
sed -i -e 's@#net.ipv4.ip_forward@net.ipv4.ip_forward=1@g' /etc/sysctl.conf

sysctl -p /etc/sysctl.conf
cp ~/certificates/server-key.pem /etc/ocserv/
cp ~/certificates/server-cert.pem /etc/ocserv/
echo -e "\e[32mStopping ocserv service\e[39m"
service ocserv stop
echo -e "\e[32mStarting ocserv service\e[39m"
service ocserv start

echo "OpenConnect Server Configured Succesfully"

}

uninstall() {
  sudo apt-get purge ocserv
}

addUser() {

echo "Enter a username:"
read username

ocpasswd -c /etc/ocserv/ocpasswd $username

}

showUsers() {
cat /etc/ocserv/ocpasswd
}

deleteUser() {
echo "Enter a username:"
read username
ocpasswd -c /etc/ocserv/ocpasswd -d $username
}

lockUser() {
echo "Enter a username:"
read username
ocpasswd -c /etc/ocserv/ocpasswd -l $username
}

unlockUser() {
echo "Enter a username:"
read username
ocpasswd -c /etc/ocserv/ocpasswd -u $username
}

if [[ "$EUID" -ne 0 ]]; then
	echo "Please run as root"
	exit 1
fi

cd ~
echo '
 ▒█████   ██▓███  ▓█████  ███▄    █     ▄████▄   ▒█████   ███▄    █  ███▄    █ ▓█████  ▄████▄  ▄▄▄█████▓
▒██▒  ██▒▓██░  ██▒▓█   ▀  ██ ▀█   █    ▒██▀ ▀█  ▒██▒  ██▒ ██ ▀█   █  ██ ▀█   █ ▓█   ▀ ▒██▀ ▀█  ▓  ██▒ ▓▒
▒██░  ██▒▓██░ ██▓▒▒███   ▓██  ▀█ ██▒   ▒▓█    ▄ ▒██░  ██▒▓██  ▀█ ██▒▓██  ▀█ ██▒▒███   ▒▓█    ▄ ▒ ▓██░ ▒░
▒██   ██░▒██▄█▓▒ ▒▒▓█  ▄ ▓██▒  ▐▌██▒   ▒▓▓▄ ▄██▒▒██   ██░▓██▒  ▐▌██▒▓██▒  ▐▌██▒▒▓█  ▄ ▒▓▓▄ ▄██▒░ ▓██▓ ░ 
░ ████▓▒░▒██▒ ░  ░░▒████▒▒██░   ▓██░   ▒ ▓███▀ ░░ ████▓▒░▒██░   ▓██░▒██░   ▓██░░▒████▒▒ ▓███▀ ░  ▒██▒ ░ 
░ ▒░▒░▒░ ▒▓▒░ ░  ░░░ ▒
░ ░░ ▒░   ▒ ▒    ░ ░▒ ▒  ░░ ▒░▒░▒░ ░ ▒░   ▒ ▒ ░ ▒░   ▒ ▒ ░░ ▒░ ░░ ░▒ ▒  ░  ▒ ░░   
  ░ ▒ ▒░ ░▒ ░      ░ ░  ░░ ░░   ░ ▒░     ░  ▒     ░ ▒ ▒░ ░ ░░   ░ ▒░░ ░░   ░ ▒░ ░ ░  ░  ░  ▒       ░    
░ ░ ░ ▒  ░░          ░      ░   ░ ░    ░        ░ ░ ░ ▒     ░   ░ ░    ░   ░ ░    ░   ░          ░      
    ░ ░              ░  ░         ░    ░ ░          ░ ░           ░          ░    ░  ░░ ░               
                                       ░                                              ░                 
 ██▒   █▓ ██▓███   ███▄    █      ██████ ▓█████  ██▀███   ██▒   █▓▓█████  ██▀███                        
▓██░   █▒▓██░  ██▒ ██ ▀█   █    ▒██    ▒ ▓█   ▀ ▓██ ▒ ██▒▓██░   █▒▓█   ▀ ▓██ ▒ ██▒                      
 ▓██  █▒░▓██░ ██▓▒▓██  ▀█ ██▒   ░ ▓██▄   ▒███   ▓██ ░▄█ ▒ ▓██  █▒░▒███   ▓██ ░▄█ ▒                      
  ▒██ █░░▒██▄█▓▒ ▒▓██▒  ▐▌██▒     ▒   ██▒▒▓█  ▄ ▒██▀▀█▄    ▒██ █░░▒▓█  ▄ ▒██▀▀█▄                        
   ▒▀█░  ▒██▒ ░  ░▒██░   ▓██░   ▒██████▒▒░▒████▒░██▓ ▒██▒   ▒▀█░  ░▒████▒░██▓ ▒██▒                      
   ░ ▐░  ▒▓▒░ ░  ░░ ▒░   ▒ ▒    ▒ ▒▓▒ ▒ ░░░ ▒░ ░░ ▒▓ ░▒▓░   ░ ▐░  ░░ ▒░ ░░ ▒▓ ░▒▓░                      
   ░ ░░  ░▒ ░     ░ ░░   ░ ▒░   ░ ░▒  ░ ░ ░ ░  ░  ░▒ ░ ▒░   ░ ░░   ░ ░  ░  ░▒ ░ ▒░                      
     ░░  ░░          ░   ░ ░    ░  ░  ░     ░     ░░   ░      ░░     ░     ░░   ░                       
      ░                    ░          ░     ░  ░   ░           ░     ░  ░   ░                           
     ░                                                        ░                                         
'


PS3='Please enter your choice: '
options=("Install" "Uninstall" "Add User" "Change Password" "Show Users" "Delete User" "Lock User" "Unlock User" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Install")
            install
			break
            ;;
        "Uninstall")
            uninstall
			break
            ;;
        "Add User")
            addUser
			break
            ;;
        "Change Password")
            addUser
			break
            ;;
        "Show Users")
	    showUsers
			break
	    ;;
        "Delete User")
	    deleteUser
			break
	    ;;
        "Lock User")
	    lockUser
			break
	    ;;
        "Unlock User")
	    unlockUser
			break
	    ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done

