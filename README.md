# Scripts
This is a small collection of scripts related to linux server administration.

## inwx_nginx
The main purpose of this script is to automate the creation of nginx-vhost-files for serveral web services which need nginx as a proxy, including an easy way to create the required DNS entries when using INWX as domain provider. With the arrival of LetsEncrypt wildcard certificates (+ ECC certificate support via acme.sh), the script provides a secure web server config out of the box for all your subdomain needs.

## docker
The `installDocker.sh` script makes installing docker and docker-compose easy. Additionally you can add yourself to the docker group (for easy container management) even if this might be a potential security risk. Currently the script is tested with Ubuntu 18.04+.

## bashrc
The `.bashrc` file contains useful shortcuts for different daily tasks like looking at the disk usage with `df -kTh` in a human-readable format and removing files with `rm -i` to prevent accidentally removing of files. Also the `docker` function has been overwritten so that you can use `docker containers` like `docker images` instead of `docker container ls`.

### Usage
Clone the repository, make the script itself executable and enter your INWX/server details. Voila, you are ready to go!

```
git clone https://github.com/theforcer/scripts
cd scripts/inwx_nginx
chmod +x inwx_nginx.sh
<Open the script with an editor of your choice - Edit the configuration section>
./inwx_nginx.sh
```


