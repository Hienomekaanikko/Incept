# Starting up on the VM

## 1. Install Docker

```bash
sudo apk add docker docker-cli-compose
sudo rc-update add docker default
sudo service docker start
sudo addgroup $USER docker
```

Log out and back in so the group takes effect.

## 2. Clone the repo

```bash
git clone <your-repo-url> inception
cd inception
```

## 3. Add the domain to /etc/hosts

```bash
echo "127.0.0.1 msuokas.hive.fi" | sudo tee -a /etc/hosts
```

## 4. Create the secret files

These are gitignored and must be created manually every time.

```bash
mkdir -p secrets
echo "<db-password>"       > secrets/db_password.txt
echo "<wp-admin-password>" > secrets/wp_admin_password.txt
echo "<wp-user-password>"  > secrets/wp_user_password.txt
```

## 5. Run make

```bash
make
```

Then open `https://msuokas.hive.fi` in the browser. First boot takes a few minutes while WordPress downloads and installs — watch progress with `docker logs -f wordpress`.

---

**Note:** The evaluator will wipe all Docker state before the demo with:

```bash
docker stop $(docker ps -qa); docker rm $(docker ps -qa); docker rmi -f $(docker images -qa); docker volume rm $(docker volume ls -q); docker network rm $(docker network ls -q) 2>/dev/null
```

After that, recreate the secrets (step 4) and run `make` again.
