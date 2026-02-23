SHELL := /bin/sh

COMPOSE ?= docker compose
ENV_FILE ?= .env
PHP_VERSIONS ?= php83 php84 php85
WEBSERVERS ?= nginx httpd
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
		'  PHP_VERSIONS="php83 php84 php85"' \
		'  WEBSERVERS="nginx httpd"' \
		'  ENV_FILE=.env' \
		'  IMAGE_TAG_SUFFIX_LOCAL=-local' \
		'  IMAGE_TAG_SUFFIX_FARGATE=-fargate'

build-local:
	@set -eu; \
	for phpv in $(PHP_VERSIONS); do \
		DEPLOY_ENV=local IMAGE_TAG_SUFFIX=$(IMAGE_TAG_SUFFIX_LOCAL) PHPVERSION=$${phpv} $(COMPOSE) --env-file $(ENV_FILE) build php; \
	done; \
	for ws in $(WEBSERVERS); do \
		DEPLOY_ENV=local IMAGE_TAG_SUFFIX=$(IMAGE_TAG_SUFFIX_LOCAL) WEBSERVER=$${ws} $(COMPOSE) --env-file $(ENV_FILE) build webserver; \
	done; \
	DEPLOY_ENV=local IMAGE_TAG_SUFFIX=$(IMAGE_TAG_SUFFIX_LOCAL) $(COMPOSE) --env-file $(ENV_FILE) build wp-cli

build-fargate:
	@set -eu; \
	for phpv in $(PHP_VERSIONS); do \
		DEPLOY_ENV=fargate IMAGE_TAG_SUFFIX=$(IMAGE_TAG_SUFFIX_FARGATE) PHPVERSION=$${phpv} $(COMPOSE) --env-file $(ENV_FILE) build php; \
	done; \
	for ws in $(WEBSERVERS); do \
		DEPLOY_ENV=fargate IMAGE_TAG_SUFFIX=$(IMAGE_TAG_SUFFIX_FARGATE) WEBSERVER=$${ws} $(COMPOSE) --env-file $(ENV_FILE) build webserver; \
	done; \
	DEPLOY_ENV=fargate IMAGE_TAG_SUFFIX=$(IMAGE_TAG_SUFFIX_FARGATE) $(COMPOSE) --env-file $(ENV_FILE) build wp-cli

rebuild-local:
	@set -eu; \
	for phpv in $(PHP_VERSIONS); do \
		DEPLOY_ENV=local IMAGE_TAG_SUFFIX=$(IMAGE_TAG_SUFFIX_LOCAL) PHPVERSION=$${phpv} $(COMPOSE) --env-file $(ENV_FILE) build --no-cache php; \
	done; \
	for ws in $(WEBSERVERS); do \
		DEPLOY_ENV=local IMAGE_TAG_SUFFIX=$(IMAGE_TAG_SUFFIX_LOCAL) WEBSERVER=$${ws} $(COMPOSE) --env-file $(ENV_FILE) build --no-cache webserver; \
	done; \
	DEPLOY_ENV=local IMAGE_TAG_SUFFIX=$(IMAGE_TAG_SUFFIX_LOCAL) $(COMPOSE) --env-file $(ENV_FILE) build --no-cache wp-cli

rebuild-fargate:
	@set -eu; \
	for phpv in $(PHP_VERSIONS); do \
		DEPLOY_ENV=fargate IMAGE_TAG_SUFFIX=$(IMAGE_TAG_SUFFIX_FARGATE) PHPVERSION=$${phpv} $(COMPOSE) --env-file $(ENV_FILE) build --no-cache php; \
	done; \
	for ws in $(WEBSERVERS); do \
		DEPLOY_ENV=fargate IMAGE_TAG_SUFFIX=$(IMAGE_TAG_SUFFIX_FARGATE) WEBSERVER=$${ws} $(COMPOSE) --env-file $(ENV_FILE) build --no-cache webserver; \
	done; \
	DEPLOY_ENV=fargate IMAGE_TAG_SUFFIX=$(IMAGE_TAG_SUFFIX_FARGATE) $(COMPOSE) --env-file $(ENV_FILE) build --no-cache wp-cli
