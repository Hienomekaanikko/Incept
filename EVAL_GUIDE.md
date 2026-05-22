# Eval guide — Inception

## Before it starts

The evaluator wipes all Docker state first. This is expected — your project must build cleanly from scratch.

```bash
docker stop $(docker ps -qa); docker rm $(docker ps -qa); docker rmi -f $(docker images -qa); docker volume rm $(docker volume ls -q); docker network rm $(docker network ls -q) 2>/dev/null
```

After the wipe, recreate your secrets and run `make`:

```bash
mkdir -p secrets
echo "your_db_password"    > secrets/db_password.txt
echo "your_admin_password" > secrets/wp_admin_password.txt
echo "your_user_password"  > secrets/wp_user_password.txt
make
```

---

## Credentials check

They'll look for passwords in the repo.

```bash
cat .gitignore                   # shows: secrets/ is gitignored
ls secrets/                      # the secret files exist locally but aren't in git
cat srcs/.env                    # no passwords here — just domain, usernames, db name
git log --oneline                # clean history, nothing sensitive ever committed
```

**Say:** "Passwords live in `secrets/*.txt` which is gitignored. The `.env` is committed but only has non-sensitive config — domain name, usernames, database name. No credentials anywhere in git."

---

## Project structure

```bash
ls -la                           # Makefile at root, srcs/ folder present
ls srcs/                         # docker-compose.yml, .env, requirements/
ls srcs/requirements/            # nginx/, wordpress/, mariadb/ — each has a Dockerfile
```

---

## General checks

**No `network: host`, no `links:`, no `--link`:**
```bash
grep -E "network: host|links:" srcs/docker-compose.yml || echo "not found"
grep -r "\-\-link" srcs/ || echo "not found"
```

**No infinite loops or background hacks:**
```bash
grep -rE "tail -f|sleep infinity|while true" srcs/requirements/ || echo "not found"
```
**Say:** "Every entrypoint script ends with `exec <daemon>` — the shell is replaced by the process as PID 1. No background tricks."

**Base images are pinned Alpine, not `latest`:**
```bash
grep "^FROM" srcs/requirements/nginx/Dockerfile
grep "^FROM" srcs/requirements/wordpress/Dockerfile
grep "^FROM" srcs/requirements/mariadb/Dockerfile
# All show: FROM alpine:3.21
```

---

## Run it

```bash
make
```

First boot takes a few minutes — WordPress downloads and installs itself. Watch it:

```bash
docker logs -f wordpress
```

When you see `Starting PHP-FPM...` it's ready.

---

## Verify containers and images

```bash
docker ps                                        # all three Up, no restarts
docker images | grep -E "nginx|wordpress|mariadb"  # nginx:42, wordpress:42, mariadb:42
docker compose -f srcs/docker-compose.yml ps
```

---

## Network

```bash
grep -A5 "networks:" srcs/docker-compose.yml
docker network ls | grep inception
docker network inspect inception
```

**Say:** "Containers communicate by container name over the `inception` bridge network. MariaDB and WordPress are not reachable from outside — only nginx is exposed to the host on port 443."

---

## NGINX and TLS

```bash
curl -k https://msuokas.42.fr          # returns WordPress HTML
curl http://msuokas.42.fr              # connection refused — port 80 not exposed
```

**Verify TLS versions:**
```bash
openssl s_client -connect msuokas.42.fr:443 -tls1_2 2>/dev/null | grep "Cipher"
openssl s_client -connect msuokas.42.fr:443 -tls1_3 2>/dev/null | grep "Cipher"
openssl s_client -connect msuokas.42.fr:443 -tls1_1 2>/dev/null | grep "Cipher"  # should fail
```

**Say:** "nginx enforces `ssl_protocols TLSv1.2 TLSv1.3` — nothing older is accepted. The self-signed cert is generated at container startup with openssl. nginx is the only entry point; it proxies PHP requests to the WordPress container on port 9000 via FastCGI."

---

## WordPress

Open `https://msuokas.42.fr` in the browser — site loads.

**Log in as admin:**
- URL: `https://msuokas.42.fr/wp-admin`
- Username: `kalakukko55` (no "admin" in the name)
- Password: whatever you put in `secrets/wp_admin_password.txt`

**Show two users exist:**
```bash
docker exec -it mariadb mariadb -u awesomeuser -p \
  -e "SELECT user_login, user_email, user_registered FROM awesomedb.wp_users;"
```
Password is in `secrets/db_password.txt`. You'll see `kalakukko55` (admin) and `msuokas` (author).

**No nginx in WordPress container:**
```bash
grep -i nginx srcs/requirements/wordpress/Dockerfile || echo "not found"
```

**Volume:**
```bash
docker volume inspect wordpress
# "device" shows /home/msuokas/data/wordpress
ls /home/msuokas/data/wordpress    # WordPress files on host
```

---

## MariaDB

```bash
docker volume inspect mariadb
# "device" shows /home/msuokas/data/mariadb

docker exec -it mariadb mariadb -u awesomeuser -p
# password: secrets/db_password.txt
```

Inside MariaDB:
```sql
show databases;
use awesomedb;
show tables;
select count(*) from wp_posts;
```

**No nginx in MariaDB container:**
```bash
grep -i nginx srcs/requirements/mariadb/Dockerfile || echo "not found"
```

**Say:** "MariaDB is initialized with `mariadb-install-db` on first boot. A temporary daemon runs to create the database and user, then shuts down. After that `exec mariadbd` takes over as PID 1. Subsequent starts skip the init entirely."

---

## Persistence

1. `make down` then `make up` (or reboot the VM)
2. Open `https://msuokas.42.fr` — all content still there

**Say:** "Both volumes are bind-mounted to `/home/msuokas/data/` on the host. The data lives on the host filesystem — destroying containers doesn't affect it. WordPress also has a `.firstmount` guard so the installer never re-runs on restart."

---

## Verbal questions

**"How does Docker / docker compose work?"**
Docker builds containers from Dockerfiles — isolated processes with their own filesystem and network. `docker compose` reads a YAML file and manages the whole stack: builds images, creates networks and volumes, starts containers in the right order. The images are identical to what you'd build manually — compose is just orchestration.

**"Docker vs VMs?"**
VMs emulate a full OS including kernel — heavy, slow to start, gigabytes each. Containers share the host kernel and only package the app and its dependencies — they start in seconds and are much lighter. Same image runs identically on any Docker host.

**"Why this directory structure?"**
`Makefile` at root is the single entry point. Everything inside `srcs/` — compose file, env, one folder per service each with its own Dockerfile. `secrets/` is at root and gitignored so credentials never touch git.

---

## Port change demo

They may ask you to change the NGINX port. Edit `srcs/docker-compose.yml`:

```yaml
ports:
  - "4343:443"    # was 443:443
```

Then:
```bash
docker compose -f srcs/docker-compose.yml up -d
curl -k https://msuokas.42.fr:4343
```

Change it back when done.
