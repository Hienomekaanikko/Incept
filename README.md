*This project has been created as part of the 42 curriculum by msuokas*

## Description

Inception is a system administration project that involves setting up a small infrastructure using Docker and Docker Compose. The stack consists of three services — NGINX (with TLS), WordPress (with php-fpm), and MariaDB — each running in its own container built from a custom Dockerfile based on Alpine Linux 3.20.

- **NGINX**: reverse proxy serving HTTPS on port 443 with a self-signed TLS 1.2/1.3 certificate, forwarding PHP requests to the WordPress container.
- **WordPress**: runs php-fpm to serve the WordPress application, connected to MariaDB.
- **MariaDB**: relational database storing all WordPress data.

## Instructions

### Prerequisites

- Docker Engine and Docker Compose installed
- Port 443 available on the host
- Add the domain to `/etc/hosts`:
  ```
  127.0.0.1   msuokas.42.fr
  ```
- Create the data directories:
  ```bash
  mkdir -p /home/msuokas/data/wordpress /home/msuokas/data/mariadb
  ```
- Create `srcs/.env` with the required environment variables (see DEV_DOC.md)

### Start

```bash
make
```

### Stop

```bash
make down
```

### Access

- Website: `https://msuokas.42.fr`
- Admin panel: `https://msuokas.42.fr/wp-admin`

## Project description

### Docker usage and design choices

Each service runs in its own container built from a custom Dockerfile based on Alpine Linux 3.20. No pre-built images from DockerHub are used — only the base Alpine image is pulled, and everything else is installed and configured manually. The three services communicate over a dedicated Docker network called `inception`. Persistent data is stored in named volumes mounted to the host filesystem.

### Virtual Machines vs Docker

A virtual machine emulates an entire operating system, including its own kernel, running on top of a hypervisor. This makes VMs heavyweight — they consume significant memory and disk space and are slow to start. Docker containers share the host kernel and only package the application and its dependencies. This makes containers lightweight, fast to start, and much more efficient with resources. The trade-off is that containers provide less isolation than VMs since they share the kernel.

### Secrets vs Environment Variables

Environment variables (used via `.env` in this project) are simple key-value pairs injected into the container at runtime. They are convenient but stored in plaintext and visible to any process inside the container. Docker secrets are a more secure alternative — they are stored encrypted in the Docker swarm and mounted as files inside the container, never exposed as environment variables. For this project, environment variables via a local `.env` file (excluded from git) are used as required by the subject.

### Docker Network vs Host Network

With host networking (`network: host`), the container shares the host's network stack directly — no isolation, no port mapping needed, but the container can conflict with host services and there is no separation between containers. Docker network (used here: `network: inception`) creates an isolated virtual network. Containers communicate by service name (DNS resolution within the network), and only explicitly published ports (443) are accessible from outside. This is the correct and required approach for this project.

### Docker Volumes vs Bind Mounts

Both persist data outside the container lifecycle. A Docker-managed volume stores data in Docker's internal storage area and is fully managed by Docker — portable and independent of host path structure. A bind mount links a specific host path directly into the container. This project uses bind mounts configured as named volumes (via `driver: local` with `o: bind`), which means data is stored at explicit host paths (`/home/msuokas/data/wordpress` and `/home/msuokas/data/mariadb`) while still being declared as named volumes in docker-compose. This satisfies both the volume naming requirement and the `/home/login/data` path requirement.

## Resources

### References

- [Docker documentation](https://docs.docker.com/)
- [Alpine Linux packages](https://pkgs.alpinelinux.org/)
- [WordPress CLI](https://wp-cli.org/)
- [MariaDB documentation](https://mariadb.com/kb/en/)
- [NGINX documentation](https://nginx.org/en/docs/)

### AI usage

Claude (claude.ai) was used as a reference tool during development to look up Alpine Linux package names, understand differences between Debian and Alpine package layouts, and review configuration syntax. All code was written, reviewed, and understood by the student.
