#!/bin/bash
# === Startup script Symfony + Firebase ===

# Installation des dépendances
composer install --no-interaction --prefer-dist --optimize-autoloader

# Configuration des droits d'accès
chmod -R 777 var/cache var/log

# Chemin du fichier attendu par Symfony
FIREBASE_PATH=/home/site/wwwroot/public/config/firebase/firebase-credentials.json

# Créer le dossier si inexistant
mkdir -p /home/site/wwwroot/public/config/firebase

# Écrire la variable d'environnement dans le fichier
echo "$FIREBASE_CREDENTIALS_JSON" > $FIREBASE_PATH
chmod 600 $FIREBASE_PATH

# Configuration Nginx pour Symfony
cat > /etc/nginx/sites-available/default << 'EOL'
server {
    listen 80;
    server_name localhost;
    root /home/site/wwwroot;  # Point vers la racine du projet

    location / {
        try_files $uri /index.php$is_args$args;
    }

    location ~ ^/index\.php(/|$) {
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_split_path_info ^(.+\.php)(/.*)$;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT $realpath_root;
        internal;
    }

    location ~ \.php$ {
        return 404;
    }
}
EOL

# Vérifier la configuration Nginx
nginx -t

# Démarrer PHP-FPM et Nginx
service php8.2-fpm start
service nginx start

# Garder le conteneur actif
tail -f /dev/null
