SHELL := /bin/sh

ENV_FILE ?= .env
ENV_EXAMPLE ?= .env.example
COMPOSE ?= docker compose
COMPOSE_ENV = $(COMPOSE) --env-file $(ENV_FILE)

.PHONY: help env dirs prepare config build start up down restart ps logs

help:
	@printf '%s\n' \
		'Available targets:' \
		'  make prepare  - create .env from .env.example and prepare bind-mount directories' \
		'  make env      - create .env from .env.example if missing' \
		'  make dirs     - create HOST_DB_DIR and HOST_CERT_DIR from .env' \
		'                    optionally apply chown -R when HOST_DIR_OWNER is set' \
		'                    use HOST_DIR_OWNER=current for the current user:group' \
		'  make config   - validate and render docker compose config' \
		'  make build    - prepare and build 3x-ui image' \
		'  make start    - start 3x-ui containers without rebuilding' \
		'  make up       - prepare, build, and start 3x-ui with docker compose' \
		'  make down     - stop 3x-ui containers' \
		'  make restart  - restart 3x-ui containers' \
		'  make ps       - show container status' \
		'  make logs     - follow 3x-ui logs'

env:
	@if [ -f "$(ENV_FILE)" ]; then \
		printf '.env already exists: %s\n' "$(ENV_FILE)"; \
	elif [ -f "$(ENV_EXAMPLE)" ]; then \
		cp "$(ENV_EXAMPLE)" "$(ENV_FILE)"; \
		printf 'Created %s from %s\n' "$(ENV_FILE)" "$(ENV_EXAMPLE)"; \
	else \
		printf 'Missing template file: %s\n' "$(ENV_EXAMPLE)"; \
		exit 1; \
	fi

dirs: env
	@db_dir="$$(sed -n 's/^HOST_DB_DIR=//p' "$(ENV_FILE)" | tail -n 1)"; \
	cert_dir="$$(sed -n 's/^HOST_CERT_DIR=//p' "$(ENV_FILE)" | tail -n 1)"; \
	owner="$$(sed -n 's/^HOST_DIR_OWNER=//p' "$(ENV_FILE)" | tail -n 1)"; \
	db_dir="$${db_dir%\"}"; \
	db_dir="$${db_dir#\"}"; \
	cert_dir="$${cert_dir%\"}"; \
	cert_dir="$${cert_dir#\"}"; \
	owner="$${owner%\"}"; \
	owner="$${owner#\"}"; \
	db_dir="$${db_dir:-./db}"; \
	cert_dir="$${cert_dir:-./cert}"; \
	if [ "$$owner" = "current" ]; then \
		owner="$$(id -un):$$(id -gn)"; \
	fi; \
	mkdir -p "$$db_dir" "$$cert_dir"; \
	if [ -n "$$owner" ]; then \
		chown -R "$$owner" "$$db_dir" "$$cert_dir"; \
		printf 'Prepared directories with owner %s:\n  %s\n  %s\n' "$$owner" "$$db_dir" "$$cert_dir"; \
	else \
		printf 'Prepared directories:\n  %s\n  %s\n' "$$db_dir" "$$cert_dir"; \
	fi

prepare: env dirs
	@printf '3x-ui preparation complete.\n'

config: prepare
	@$(COMPOSE_ENV) config

build: prepare
	@$(COMPOSE_ENV) build

start: prepare
	@$(COMPOSE_ENV) up -d

up: build start

down:
	@$(COMPOSE_ENV) down

restart:
	@$(COMPOSE_ENV) restart

ps:
	@$(COMPOSE_ENV) ps

logs:
	@$(COMPOSE_ENV) logs -f --tail=100
