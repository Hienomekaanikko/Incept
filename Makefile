COMPOSE_FILE = srcs/docker-compose.yml
DATA_DIR = /home/$(USER)/data
SECRETS_DIR = secrets

.PHONY: all build up down clean fclean re

all: build up

build:
	mkdir -p $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress $(SECRETS_DIR)
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
	sudo rm -rf $(DATA_DIR)

re: fclean all
