*This project has been created as part of the 42 curriculum by msuokas*

## Description

Inception is a system administration project that involves setting up a small infrastructure using Docker and Docker Compose. The stack consists of three services: NGINX (with TLS), WordPress (with php-fpm), and MariaDB. Each are running in its own container built from a custom Dockerfile based on Alpine Linux 3.21.

- **NGINX**: reverse proxy serving HTTPS on port 443 with a self-signed TLS 1.2/1.3 certificate, forwarding PHP requests to the WordPress container.
- **WordPress**: runs php-fpm to serve the WordPress application, connected to MariaDB.
- **MariaDB**: relational database storing all WordPress data.

## Instructions

### Start

- make
- make up

### Restart

- make re

### Stop

- make down

## Clean up

- make fclean

### Access

- Website: `https://msuokas.42.fr`
- Admin panel: `https://msuokas.42.fr/wp-admin`

## Project description

### The flow of how everything works

So we have NGINX, WordPress and MariaDB and it all gets build-up to be a one coherent thing via the recipe that is the docker-compose file. After it's 
all running, user can go to the address https://msuokas.hive.fi. What happens next:

1. The https-request gets sent to nginx through port 443. (The only way to the system). 
2. NGINX interprets: 'this is a PHP request, i'll send it to FastCGI through port 9000 as i dont know what to do with this'.
3. FastCGI forwards it to PHP-FPM which executes the request
4. PHP-FPM request queries MariaDB for data through port 3306.
5. MariaDB returns the data to PHP-FPM for it to build a HTML response of it.
6. PHP-FPM returns the response to NGINX and NGINX gives it back to the user via HTTPS.

### TLS 1.2 && TLS 1.3

We have to use the best security practices. Anything less than TLS 1.2 is regarded as old and not acceptable nor safe for modern standards.

What is TLS 1.2?

It's a way to form a secure authenticated connection between the client and a server. This is how it goes (roughly):

1. Client sends to the server: "Hey I want to connect, here's my ciphers!"
2. Server responds: "Alright, use this one. Here's my certificate for you're protection also."
3. Client uses the cipher and the public key to encrypt a session key and sends the session key to the server.
4. Server uses it's private key to decrypt the session key. 
5. If the server can decrypt the client's "finished signal" (which is just a hash for the entire handshake) using the session key, then the session keys are identical.   

What is TLS 1.3?

With this things are more simple:

1. Client sends to the server a list of supported cipher suites and key shares for the most likely ones.
2. Server responds with which cipher it chose, it's own key share, certificate and encrypted finished message.
3. Client decrypts the finished message with the servers key share, verifies the hash and sends its own finished message back. 

Docker usage and design choices
Each service runs in its own container built from a custom Dockerfile based on Alpine Linux 3.21. No pre-built images from DockerHub are used — only the base Alpine image is pulled, and everything else is installed and configured manually. The three services communicate over a dedicated Docker network called inception. Persistent data is stored in named volumes mounted to the host filesystem.

Virtual Machines vs Docker
A virtual machine emulates an entire operating system, including its own kernel, running on top of a hypervisor. This makes VMs heavyweight — they consume significant memory and disk space and are slow to start. Docker containers share the host kernel and only package the application and its dependencies. This makes containers lightweight, fast to start, and much more efficient with resources. The trade-off is that containers provide less isolation than VMs since they share the kernel.

Secrets vs Environment Variables
Environment variables (used via .env in this project) are simple key-value pairs injected into the container at runtime. They are convenient for non-sensitive config like domain names and usernames. Docker secrets are used for passwords — they are mounted as read-only files inside the container at /run/secrets/<name> and never exposed as environment variables. The .env file is committed to git because it contains no credentials. The secrets/ directory is gitignored because it contains passwords.

Docker Network vs Host Network
With host networking (network: host), the container shares the host's network stack directly — no isolation, no port mapping needed, but the container can conflict with host services and there is no separation between containers. Docker network (used here: network: inception) creates an isolated virtual network. Containers communicate by service name (DNS resolution within the network), and only explicitly published ports (443) are accessible from outside. This is the correct and required approach for this project.

Docker Volumes vs Bind Mounts
Both persist data outside the container lifecycle. A Docker-managed volume stores data in Docker's internal storage area and is fully managed by Docker — portable and independent of host path structure. A bind mount links a specific host path directly into the container. This project uses bind mounts configured as named volumes (via driver: local with o: bind), which means data is stored at explicit host paths (/home/msuokas/data/wordpress and /home/msuokas/data/mariadb) while still being declared as named volumes in docker-compose. This satisfies both the volume naming requirement and the /home/login/data path requirement.

## Resources

### References

- [Docker documentation](https://docs.docker.com/)
- [Alpine Linux packages](https://pkgs.alpinelinux.org/)
- [WordPress CLI](https://wp-cli.org/)
- [MariaDB documentation](https://mariadb.com/kb/en/)
- [NGINX documentation](https://nginx.org/en/docs/)

### AI usage

AI was used to find proper resources and to get incredible amount of practical "explain it to me like i'm 5" explanations on the hardest concepts. (as I often need those).  
