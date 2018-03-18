#!/bin/bash

# Configuration ###################################################################
USERNAME=""                          	    	# Your username at INWX
PASSWORD=""		  								# Your password at INWX
APIHOST="https://api.domrobot.com/xmlrpc/" 	    # API URL from inwx.de
IPV4=""											# Static IP of your server v4
IPV6=""											# Static IP of your server v6
NGINXUSER="www-data"						    # User who runs the NGINX process
###################################################################################

clear
echo ""
echo "Welcome to the INWX+NGINX script!"
echo ""
echo "What do you want to do?"
echo "   1) Add a new subdomain to INWX"
echo "   2) Add a new subdomain/vhost to NGINX"
echo "   3) Install a LetsEncrypt ECC Wildcard certificate via acme.sh"
echo "   4) Force LetsEncrypt ECC Wildcard certificate renewal"
echo "   5) Install / Update / Remove NGINX"
echo "   9) Exit"
echo ""

while [[ $OPTION !=  "1" && $OPTION !=  "2" && $OPTION !=  "3" && $OPTION !=  "4" && $OPTION !=  "5" && $OPTION !=  "9" ]]; 
do
	read -p "Select an option [1-x]: " OPTION
done

case $OPTION in
	1)# add subdomain
		read -p "Please enter the new complete FQDN (eg. test.example.com): " FQDN
		# create strings for the new domain
		DOMAIN=$(echo $FQDN | egrep -o '([a-z0-9]+\.[a-z0-9]+)$')
		SUBDOMAIN=$(echo $FQDN | egrep -o '^[a-z0-9]+')
		# create the A record via XML POST
		XMLDATA=$(cat createA.api | sed "s/%PASSWD%/$PASSWORD/g;s/%USER%/$USERNAME/g;s/%DOMAIN%/$DOMAIN/g;s/%SUBDOMAIN%/$SUBDOMAIN/g;s/%IPV4%/$IPV4/g;")
		RET=$(curl  -s -X POST -d "$XMLDATA" "$APIHOST" --header "Content-Type:text/xml")
		# check success of record creation
		if ! grep -q "Command completed successfully" <<< "$RET";
		then
			echo "Something went wrong with the record creation. Please double-check your credentials and the FQDN you entered."
			exit
		else
			echo "Your new A record has been successfully created. Creating AAAA record now..."
			XMLDATA=$(cat createAAAA.api | sed "s/%PASSWD%/$PASSWORD/g;s/%USER%/$USERNAME/g;s/%DOMAIN%/$DOMAIN/g;s/%SUBDOMAIN%/$SUBDOMAIN/g;s/%IPV6%/$IPV6/g;")
			RET=$(curl  -s -X POST -d "$XMLDATA" "$APIHOST" --header "Content-Type:text/xml")
			if grep -q "Command completed successfully" <<< "$RET";
			then
				echo "Finished creating the DNS records! Exiting now..."
			exit
			fi
		fi
	exit
    ;;
	
	2)# add vhost
		# root user check
		if [[ "$EUID" -ne 0 ]] 
		then
			echo -e "${CRED}Sorry, for this module you need to run the script as root/sudo${CEND}"
			exit 1
		fi
		read -p "Please enter the new complete FQDN (eg. test.example.com): " FQDN
		# create strings for the new domain
		DOMAIN=$(echo $FQDN | egrep -o '([a-z0-9]+\.[a-z0-9]+)$')
		SUBDOMAIN=$(echo $FQDN | egrep -o '^[a-z0-9]+')
		# define location variables
		ROOTDIR="/var/www/$FQDN/html"
		CONF="/etc/nginx/sites-available/$FQDN"
		#create stuff
		#mkdir -p $ROOTDIR
		#chown -R $NGINXUSER:$NGINXUSER $ROOTDIR
		# create NGINX block
		#cat nginx_default.conf | sed "s/%FQDN%/$FQDN/g;s/%DOMAIN%/$DOMAIN/g;s!%ROOTDIR%!$ROOTDIR!g" > $CONF
		#ln -s $CONF /etc/nginx/sites-enabled/$FQDN
		#nginx -t && sudo nginx -s reload
		echo "Finished creating the new NGINX vhost. NGINX has been reloaded as well. Exiting now..."
	exit
	;;
	
	3)# install acme.sh
		# root user check
		if [[ "$EUID" -ne 0 ]] 
		then
			echo -e "${CRED}Sorry, for this module you need to run the script as root/sudo${CEND}"
			exit 1
		fi
		read -p "Please enter the domain you want to issue the wildcard certificate to (eg. example.com): " DOMAIN
		# define INWX credentials for acme.sh
		export INWX_User=$USERNAME && export INWX_Password=$PASSWORD
		# download & install acme.sh
		cd /root/
		git clone https://github.com/Neilpang/acme.sh.git
		cd ./acme.sh && ./acme.sh --install
		# issue cert
		echo "The following process takes about 2+ minutes, as acme.sh has to wait before verifying the created domain entries. Stand by..."
		./acme.sh --issue --dns dns_inwx -d $DOMAIN -d *.$DOMAIN --keylength ec-384
		if ! grep -q "Command completed successfully" <<< "$RET"; #TODO
		then
			echo "Finished creating the DNS records! Exiting now..."
		fi
	exit
	;;
	
	4)# force certificate renewal
		# root user check
		if [[ "$EUID" -ne 0 ]] 
		then
			echo -e "${CRED}Sorry, for this module you need to run the script as root/sudo${CEND}"
			exit 1
		fi
		read -p "Please enter the domain of the certificate you want to renew (eg. example.com): " DOMAIN
		cd /root/.acme.sh
		./acme.sh --renew -d $DOMAIN -d *.$DOMAIN --force --ecc
		# output TODO
	exit
	;;	
	
	5)# nginx installer script
		wget https://raw.githubusercontent.com/Angristan/nginx-autoinstall/master/nginx-autoinstall.sh
		chmod +x nginx-autoinstall.sh
		sudo bash nginx-autoinstall.sh
	exit
	;;	
	
	9)
		exit
	;;
esac