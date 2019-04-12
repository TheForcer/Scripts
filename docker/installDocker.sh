#!/bin/bash

# Colors ##########################################################################
CSI="\033["
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
###################################################################################

clear
echo ""
echo -e "${CGREEN}Welcome to the docker installation script!${CEND}"
echo ""
echo "What do you want to do?"
echo "   1) Install docker"
echo "   2) Install docker-compose"
echo "   3) Add yourself to the docker group (potential security risk!)"
echo "   4) Exit"
echo ""

while [[ $OPTION !=  "1" && $OPTION !=  "2" && $OPTION !=  "3" && $OPTION !=  "4" && $OPTION !=  "5" && $OPTION !=  "6" && $OPTION !=  "7" && $OPTION !=  "8" && $OPTION !=  "9" ]]; 
do
	read -p "Select an option [1-4]: " OPTION
done

case $OPTION in
	1)# install docker
        # root user check
		if [[ "$EUID" -ne 0 ]] 
		then
			echo -e "${CRED}Sorry, for this module you need to run the script as root/sudo${CEND}"
			exit 1
        fi
        # install required dependencies
        sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common
        # dowload docker and add the gpg key
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo apt-key fingerprint 0EBFCD88
        # add stable repo for docker
        sudo add-apt-repository \
            "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
            $(lsb_release -cs) stable"
        # update sources and install docker-ce
        sudo apt-get update
        sudo apt-get -y install docker-ce
        # enable docker at system start
        sudo systemctl enable docker
        echo -e "${CGREEN}Finished installing docker. Exiting now...${CEND}"
	exit
    ;;

	2)# install docker-compose
    	# root user check
		if [[ "$EUID" -ne 0 ]] 
		then
			echo -e "${CRED}Sorry, for this module you need to run the script as root/sudo${CEND}"
			exit 1
		fi
        # download binary and make it executable
        sudo curl -L https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        read -p "Do you want to install the bash-completion for docker-compose [Y/n]? " -n 1 -r
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            sudo curl -L https://raw.githubusercontent.com/docker/compose/1.24.0/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose
        fi
        echo -e "${CGREEN}Finished installing docker-compose. Exiting now...${CEND}"
	exit
	;;

	3)# add yourself to the docker group
		# root user check
		if [[ "$EUID" -ne 0 ]] 
		then
			echo -e "${CRED}Sorry, for this module you need to run the script as root/sudo${CEND}"
			exit 1
		fi
		sudo groupadd docker
        sudo usermod -aG docker $USER
        echo -e "${CGREEN}Finished adding yourself to the docker group. Exiting now...${CEND}"
	exit
	;;
	
	4)
	exit
	;;
esac
