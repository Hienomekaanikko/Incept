#!/bin/sh
set -e

if [ ! -f /var/lib/mysql/.firstmount ]; then
    echo "First boot: initializing database..."

    if [ -d /var/lib/mysql/mysql ]; then
        echo "Removing corrupted datadir..."
        rm -rf /var/lib/mysql/*
    fi

    mariadb-install-db \
        --datadir=/var/lib/mysql \
        --skip-test-db \
        --user=mysql \
        --group=mysql \
        --auth-root-authentication-method=socket \
        2>/dev/null

    mariadbd --user=mysql --bind-address=127.0.0.1 --log-error=/var/log/mysql/error.log &
    DAEMON_PID=$!

    echo "Waiting for daemon..."
    attempts=0
    while ! mariadb -u root -e "SELECT 1" >/dev/null 2>&1; do
        attempts=$((attempts + 1))
        [ $attempts -gt 30 ] && { echo "Daemon startup timeout"; kill $DAEMON_PID 2>/dev/null; exit 1; }
        sleep 1
    done

    db_pwd=$(cat /run/secrets/db_password)
    mariadb -u root << EOF
CREATE DATABASE IF NOT EXISTS \`$db_name\`;
CREATE USER IF NOT EXISTS '$db_user'@'%' IDENTIFIED BY '$db_pwd';
GRANT ALL PRIVILEGES ON \`$db_name\`.* TO '$db_user'@'%';
FLUSH PRIVILEGES;
EOF

    kill $DAEMON_PID
    wait $DAEMON_PID 2>/dev/null || true

    touch /var/lib/mysql/.firstmount
    echo "Database initialized successfully"
else
    echo "Database already initialized"
fi

echo "Starting MariaDB..."
exec mariadbd --user=mysql
