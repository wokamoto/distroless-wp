SHELL := /bin/sh

COMPOSE ?= docker compose
ENV_FILE ?= .env
SERVICES ?= php webserver wp-cli
IMAGE_TAG_SUFFIX_LOCAL ?= -local
IMAGE_TAG_SUFFIX_FARGATE ?= -fargate

.DEFAULT_GOAL := help

.PHONY: help build-local build-fargate rebuild-local rebuild-fargate

help:
	@printf '%s\n' \
		'Usage:' \
		'  make build-local      Build app images for local runtime (DEPLOY_ENV=local, tag suffix -local)' \
		'  make build-fargate    Build app images for Fargate runtime (DEPLOY_ENV=fargate, tag suffix -fargate)' \
		'  make rebuild-local    Build local images without cache' \
		'  make rebuild-fargate  Build fargate images without cache' \
		'' \
		'Optional variables:' \
		'  SERVICES="php webserver wp-cli" (default)' \
		'  ENV_FILE=.env' \
		'  IMAGE_TAG_SUFFIX_LOCAL=-local' \
		'  IMAGE_TAG_SUFFIX_FARGATE=-fargate'

build-local:
	DEPLOY_ENV=local IMAGE_TAG_SUFFIX=$(IMAGE_TAG_SUFFIX_LOCAL) $(COMPOSE) --env-file $(ENV_FILE) build $(SERVICES)

build-fargate:
	DEPLOY_ENV=fargate IMAGE_TAG_SUFFIX=$(IMAGE_TAG_SUFFIX_FARGATE) $(COMPOSE) --env-file $(ENV_FILE) build $(SERVICES)

rebuild-local:
	DEPLOY_ENV=local IMAGE_TAG_SUFFIX=$(IMAGE_TAG_SUFFIX_LOCAL) $(COMPOSE) --env-file $(ENV_FILE) build --no-cache $(SERVICES)

rebuild-fargate:
	DEPLOY_ENV=fargate IMAGE_TAG_SUFFIX=$(IMAGE_TAG_SUFFIX_FARGATE) $(COMPOSE) --env-file $(ENV_FILE) build --no-cache $(SERVICES)
