COMPOSE_FILE = srcs/docker-compose.yml
SECRETS_DIR = secrets

.PHONY: all build up down clean fclean re

all: build up

build:
	mkdir -p $(SECRETS_DIR)
	docker compose -f $(COMPOSE_FILE) build

up:
	docker compose -f $(COMPOSE_FILE) up -d

down:
	docker compose -f $(COMPOSE_FILE) down

clean:
	docker compose -f $(COMPOSE_FILE) down
	docker system prune -af

fclean: clean
	docker volume prune -f

re: fclean all
