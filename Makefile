SHELL := /bin/sh

COMPOSE ?= docker compose
ENV_FILE ?= .env
PHP_VERSIONS ?= php83 php84 php85
WEBSERVERS ?= nginx httpd
IMAGE_TAG_SUFFIX_LOCAL ?= -local
IMAGE_TAG_SUFFIX_FARGATE ?= -fargate
# Pull base images (builder images, distroless, wordpress) on every build. Set PULL= to skip.
PULL ?= --pull
# WordPress core version to bundle. Precedence: make/env WP_VERSION > WP_VERSION in $(ENV_FILE) > latest.
# "latest" is resolved to a concrete version (e.g. 7.1.4) via the WordPress.org API, because the
# wordpress:php8.x-fpm-alpine image can lag behind the newest point release.
WP_VERSION_API ?= https://api.wordpress.org/core/version-check/1.7/

.DEFAULT_GOAL := help

.PHONY: help build-local build-fargate rebuild-local rebuild-fargate _build

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
		'  IMAGE_TAG_SUFFIX_FARGATE=-fargate' \
		'  PULL=--pull                  (set PULL= to use only locally cached base images)' \
		'  WP_VERSION=7.1.4             (default: WP_VERSION in ENV_FILE, else latest from WordPress.org)'

build-local:
	@$(MAKE) --no-print-directory _build BUILD_ENV=local BUILD_SUFFIX=$(IMAGE_TAG_SUFFIX_LOCAL) BUILD_NO_CACHE=

build-fargate:
	@$(MAKE) --no-print-directory _build BUILD_ENV=fargate BUILD_SUFFIX=$(IMAGE_TAG_SUFFIX_FARGATE) BUILD_NO_CACHE=

rebuild-local:
	@$(MAKE) --no-print-directory _build BUILD_ENV=local BUILD_SUFFIX=$(IMAGE_TAG_SUFFIX_LOCAL) BUILD_NO_CACHE=--no-cache

rebuild-fargate:
	@$(MAKE) --no-print-directory _build BUILD_ENV=fargate BUILD_SUFFIX=$(IMAGE_TAG_SUFFIX_FARGATE) BUILD_NO_CACHE=--no-cache

# Internal: resolve the WordPress version once, then build php / webserver / wp-cli images with it.
_build:
	@set -eu; \
	wp_version='$(WP_VERSION)'; \
	if [ -z "$$wp_version" ] && [ -f '$(ENV_FILE)' ]; then \
		wp_version=$$(sed -n 's/^WP_VERSION=//p' '$(ENV_FILE)' | tail -n 1 | tr -d "\"' "); \
	fi; \
	if [ -z "$$wp_version" ] || [ "$$wp_version" = latest ]; then \
		wp_version=$$(curl -fsSL '$(WP_VERSION_API)' | grep -o '"current":"[0-9][0-9.]*"' | head -n 1 | cut -d '"' -f 4); \
		if [ -z "$$wp_version" ]; then \
			echo 'error: could not resolve the latest WordPress version from $(WP_VERSION_API); pass WP_VERSION=x.y.z' >&2; \
			exit 1; \
		fi; \
	fi; \
	echo "==> WordPress $$wp_version (DEPLOY_ENV=$(BUILD_ENV), tag suffix $(BUILD_SUFFIX))"; \
	export WP_VERSION="$$wp_version" DEPLOY_ENV='$(BUILD_ENV)' IMAGE_TAG_SUFFIX='$(BUILD_SUFFIX)'; \
	for phpv in $(PHP_VERSIONS); do \
		PHPVERSION=$${phpv} $(COMPOSE) --env-file $(ENV_FILE) build $(PULL) $(BUILD_NO_CACHE) php; \
	done; \
	for ws in $(WEBSERVERS); do \
		WEBSERVER=$${ws} $(COMPOSE) --env-file $(ENV_FILE) build $(PULL) $(BUILD_NO_CACHE) webserver; \
	done; \
	$(COMPOSE) --env-file $(ENV_FILE) build $(PULL) $(BUILD_NO_CACHE) wp-cli
