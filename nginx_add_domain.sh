#!/bin/bash
echo "Willkommen beim Domaingenerator. Er erstellt eine passende nginx-config, erstellt ein Letsencrypt Zertifikat und eine leere index.html. Lets go!"

if [ $# -eq 0 ]

then echo "Hast du die Domain vergessen?"

else

# Variablendeklarierung
domain=$1
root="/var/www/$domain/html"
block="/etc/nginx/sites-available/$domain"

# Erstellung des Dokumentverzeichnisses
sudo mkdir -p $root

# Benutzerzuweisung
sudo chown -R $USER:$USER $root

# Erstellung des nginx-Blockfiles
sudo tee $block > /dev/null <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $domain;

    # HTTPS Umleitung
    return 301 https://$domain\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $domain;

    # Zertifikate
    ssl_certificate /etc/letsencrypt/live/secureim.de/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/secureim.de/privkey.pem;
    ssl_dhparam /etc/nginx/dhparam.pem;

    # SSL Konfig
    ssl_protocols TLSv1.2;
    ssl_prefer_server_ciphers on;
    ssl_ciphers 'HIGH+kEDH:HIGH+kEECDH:!HIGH+DSA:!HIGH+ECDSA:!aNULL:!eNULL:!LOW:!3DES:!MD5:!EXP:!PSK:!SRP:!DSS:!RC4:!SEED:!AES128:!CAMELLIA128:!SHA';
    ssl_session_timeout  10m;
    ssl_session_tickets off;
    ssl_stapling on;
    ssl_stapling_verify on;

    # DNS IPs
    resolver 130.255.73.90 82.196.9.45 valid=300s; # OpenNIC DNS Server mit Standort in DE und NL +99% Uptime
    resolver_timeout 5s;

    # Header
    add_header Content-Security-Policy " default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload";
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;


    root $root;
    index index.php index.html index.htm;

    location ~ /.well-known { # Verzeichnis für certbot
                allow all;
        }


    location / {
                try_files \$uri \$uri/ =404; # Überprüfung der "physikalischen" Existenz bspw. eines php-Skripts, ansonsten 404
        }


    location ~ /\.ht { # Kein Zugriff auf .ht Dateien
                deny all;
        }

}

EOF

# Verlinkung zur Aktivierung der Seite bei nginx
sudo ln -s $block /etc/nginx/sites-enabled/$domain

# Erstellung leere index.html
sudo touch $root/index.html

# nginx Konfig-Check und non-intrusive reload
sudo nginx -t && sudo nginx -s reload

# Ausführung vom Certbot zum Erstellen der Zertifikate!
sudo certbot --nginx --force-renewal --rsa-key-size=4096 certonly

# Erneutes Laden von nginx zum Einspielen des neuen Zertifikats
sudo nginx -s reload

fi
