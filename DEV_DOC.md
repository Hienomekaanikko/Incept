# Dev notes — Inception

## What you need

Docker Engine 20.10+, Docker Compose v2, Make. Port 443 free on the host.

## First-time setup on the school VM

```bash
# 1. Add your domain to /etc/hosts
echo "127.0.0.1  msuokas.42.fr" | sudo tee -a /etc/hosts

# 2. Create the secret files (passwords only, no quotes)
mkdir -p secrets
echo "your_db_password"    > secrets/db_password.txt
echo "your_admin_password" > secrets/wp_admin_password.txt
echo "your_user_password"  > secrets/wp_user_password.txt

# 3. Build and start
make
```

The `.env` is already in the repo (it has no passwords). The `secrets/` directory is gitignored — you create it locally and never commit it.

## Make targets

```
make          build images + start containers
make up       start containers (skip rebuild)
make down     stop and remove containers
make clean    down + prune all images
make fclean   clean + delete /home/msuokas/data (full reset)
make re       fclean + build + up
```

## Useful commands

```bash
# Live logs
docker logs -f nginx
docker logs -f wordpress
docker logs -f mariadb

# Shell inside a container
docker exec -it nginx sh
docker exec -it wordpress sh
docker exec -it mariadb sh

# Rebuild one service without touching the others
docker compose -f srcs/docker-compose.yml build wordpress
docker compose -f srcs/docker-compose.yml up -d wordpress
```

## How it fits together

```
browser → nginx:443 (TLS 1.2/1.3)
              ↓ FastCGI :9000
          wordpress (php-fpm)
              ↓ TCP :3306
          mariadb
```

nginx is the only container with a published port. WordPress and MariaDB talk over the internal `inception` network only.

## Volumes

| Volume | Host path | Inside container |
|--------|-----------|-----------------|
| wordpress | `/home/msuokas/data/wordpress` | `/var/www/html` |
| mariadb | `/home/msuokas/data/mariadb` | `/var/lib/mysql` |

Both are bind-mounted so data survives container rebuilds. `make fclean` wipes them.

## First boot is slow

On `make re`, WordPress has to download core (~60 MB), install, create users, and install the Astra theme before php-fpm starts. That's 2–5 minutes depending on the network. `docker logs -f wordpress` shows progress. After that, restarts are instant.

## Credentials

Passwords go in `secrets/*.txt` (one value per file, no trailing newline needed). The admin username and second user are set in `srcs/.env`. The admin username must not contain "admin" — currently `kalakukko55`.

## Project layout

```
.
├── Makefile
├── secrets/               ← gitignored, create locally
└── srcs/
    ├── .env               ← committed (no passwords here)
    ├── docker-compose.yml
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/nginx.conf
        │   └── tools/script.sh
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/www.conf
        │   └── tools/script.sh
        └── mariadb/
            ├── Dockerfile
            ├── conf/50-server.cnf
            └── tools/script.sh
```
