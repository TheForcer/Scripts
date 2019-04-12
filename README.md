# Scripts
This is a small collection of scripts related to linux server administration.

## docker
The `installDocker.sh` script makes installing docker and docker-compose easy. Additionally you can add yourself to the docker group (for easy container management) even if this might be a potential security risk. Currently the script is tested with Ubuntu 18.04+.

## bashrc
The `.bashrc` file contains useful shortcuts for different daily tasks like looking at the disk usage with `df -kTh` in a human-readable format and removing files with `rm -i` to prevent accidental removal of files. Also the `docker` function has been overwritten so that you can use `docker containers` like `docker images` instead of `docker container ls`.

### Usage
You can simply clone/wget/curl the scripts and execute them. You may have to add the execute bit to the file though.


