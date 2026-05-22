#!/bin/sh
set -e

WORKDIR=/var/www/html

# Install WordPress only on first volume mount
if [ ! -f "$WORKDIR/.firstmount" ]; then
    db_pwd=$(cat /run/secrets/db_password)
    wp_admin_pwd=$(cat /run/secrets/wp_admin_password)
    wp_user_pwd=$(cat /run/secrets/wp_user_password)

    echo "Waiting for MariaDB..."
    attempts=0
    while ! mariadb-admin ping --protocol=tcp --host=mariadb \
        -u "$db_user" --password="$db_pwd" --silent 2>/dev/null; do
        attempts=$((attempts + 1))
        if [ $attempts -gt 30 ]; then
            echo "Database not ready after 30 attempts"
            exit 1
        fi
        sleep 1
    done
    echo "Database ready"

    if [ ! -f "$WORKDIR/wp-config.php" ]; then
        echo "Installing WordPress..."

        wp core download --allow-root --path="$WORKDIR" || exit 1

        wp config create --allow-root --path="$WORKDIR" \
            --dbhost=mariadb \
            --dbuser="$db_user" \
            --dbpass="$db_pwd" \
            --dbname="$db_name" || exit 1

        wp core install --allow-root --path="$WORKDIR" \
            --skip-email \
            --url="$DOMAIN_NAME" \
            --title="$WP_TITLE" \
            --admin_user="$WP_ADMIN_USR" \
            --admin_password="$wp_admin_pwd" \
            --admin_email="$WP_ADMIN_EMAIL" || exit 1

        if ! wp user get "$WP_USR" --allow-root --path="$WORKDIR" >/dev/null 2>&1; then
            wp user create "$WP_USR" "$WP_EMAIL" \
                --role=author --user_pass="$wp_user_pwd" --allow-root --path="$WORKDIR" || exit 1
        fi

        wp theme install astra --activate --allow-root --path="$WORKDIR" || true
        wp plugin update --all --allow-root --path="$WORKDIR" || true
        
        echo "WordPress installation complete"
    else
        echo "WordPress already installed"
    fi

    chmod -R o+w "$WORKDIR/wp-content"
    touch "$WORKDIR/.firstmount"
else
    echo "WordPress volume already initialized"
fi

echo "Starting PHP-FPM..."
exec /usr/sbin/php-fpm83 -F
