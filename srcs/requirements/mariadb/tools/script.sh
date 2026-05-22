#!/bin/sh
set -e

db_pwd=$(cat /run/secrets/db_password)

# If .firstmount doesn't exist, do initialization
if [ ! -f /var/lib/mysql/.firstmount ]; then
    echo "First boot: initializing database..."
    
    # Clean up any partial/corrupt datadir
    if [ -d /var/lib/mysql/mysql ]; then
        echo "Removing corrupted datadir..."
        rm -rf /var/lib/mysql/*
    fi
    
    mariadb-install-db \
        --datadir=/var/lib/mysql \
        --skip-test-db \
        --user=mysql \
        --group=mysql \
        --auth-root-authentication-method=socket
    
    mariadbd --bootstrap --user=mysql --skip-networking << EOF
CREATE DATABASE IF NOT EXISTS $db_name;
CREATE USER IF NOT EXISTS '$db_user'@'%' IDENTIFIED BY '$db_pwd';
GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'%';
FLUSH PRIVILEGES;
EOF
    
    touch /var/lib/mysql/.firstmount
    echo "Database initialized successfully"
else
    echo "Database already initialized, starting server..."
fi

exec mariadbd --user=mysql
