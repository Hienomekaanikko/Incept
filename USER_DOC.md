# Using the site

## Opening it

Go to `https://msuokas.42.fr` in your browser. You'll get a certificate warning because the SSL cert is self-signed — click through it (Advanced → Proceed).

## WordPress admin

`https://msuokas.42.fr/wp-admin`

Log in with the admin credentials you put in `secrets/wp_admin_password.txt`. The admin username is `kalakukko55`.

## Starting and stopping

```bash
make          # build + start everything
make up       # start without rebuilding
make down     # stop and remove containers (data stays)
make re       # full reset and restart from scratch
```

## Checking what's running

```bash
docker ps
docker logs wordpress
docker logs mariadb
docker logs nginx
```

## Resetting completely

```bash
make fclean   # stops containers, removes images, deletes all data on disk
make          # rebuild from zero
```

First boot after a reset takes a few minutes — WordPress is being downloaded and installed. Progress shows in `docker logs -f wordpress`.
