#!/bin/bash

# Configuration ###################################################################
USERNAME=""                          	    	# Your username at INWX
PASSWORD=""		  								# Your password at INWX
APIHOST="https://api.domrobot.com/xmlrpc/" 	    # API URL from inwx.de
IPV4=""											# Static IP of your server v4
IPV6=""											# Static IP of your server v6
NGINXUSER="www-data"						    # User who runs the NGINX process
###################################################################################

# Colors ##########################################################################
CSI="\033["
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
###################################################################################

clear
echo ""
echo -e "${CGREEN}Welcome to the INWX+NGINX script!${CEND}"
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
			echo -e "${CRED}Something went wrong with the record creation. Please double-check your credentials and the FQDN you entered.${CEND}"
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
		echo -e "${CGREEN}Downloading acme.sh ...${CEND}"
		git clone https://github.com/Neilpang/acme.sh.git
		echo -e "${CGREEN}Installing acme.sh ...${CEND}"
		cd ./acme.sh && ./acme.sh --install
		# issue cert
		echo -e "${CGREEN}Requesting certificate ...${CEND}"
		echo "The following process takes about 2+ minutes, as acme.sh has to wait before verifying the created domain entries. Please stand by..."
		RET=$(./acme.sh --issue --dns dns_inwx -d $DOMAIN -d *.$DOMAIN --keylength ec-384)
		if ! grep -q "Cert success." <<< "$RET";
		then
			echo -e "${CRED}Something went wrong with the certificate creation. Please double-check your credentials and the domain you entered.${CEND}"
			exit
		else
			echo -e "${CGREEN}Your wildcard certificate has been successfully created. You will find your files here:${CEND}"
			echo ""
			echo -e "	Certificate:  /root/.acme.sh/${DOMAIN}_ecc/$DOMAIN.cer"
			echo -e "	Private Key:  /root/.acme.sh/${DOMAIN}_ecc/$DOMAIN.key"
			echo -e "	Intermediate Certificate:  /root/.acme.sh/${DOMAIN}_ecc/ca.cer"
			echo -e "	Full Chain Certificate:  /root/.acme.sh/${DOMAIN}_ecc/fullchain.cer"
			echo ""
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
		echo -e "${CGREEN}Requesting certificate ...${CEND}"
		echo "The following process can take about 2+ minutes, as acme.sh has to wait before verifying the newly created domain entries. Please stand by..."
		RET=$(./acme.sh --renew -d $DOMAIN -d *.$DOMAIN --force --ecc)
		if ! grep -q "Cert success." <<< "$RET"; #TODO
		then
			echo -e "${CRED}Something went wrong with the certificate renewal. Please double-check your credentials and the domain you entered.${CEND}"
			exit
		else
			echo -e "${CGREEN}Your wildcard certificate has been successfully renewed. You will find your files here:${CEND}"
			echo ""
			echo -e "	Certificate:  /root/.acme.sh/${DOMAIN}_ecc/$DOMAIN.cer"
			echo -e "	Private Key:  /root/.acme.sh/${DOMAIN}_ecc/$DOMAIN.key"
			echo -e "	Intermediate Certificate:  /root/.acme.sh/${DOMAIN}_ecc/ca.cer"
			echo -e "	Full Chain Certificate:  /root/.acme.sh/${DOMAIN}_ecc/fullchain.cer"
			echo ""
		fi
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