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

DOCKER ?= docker
AWS ?= aws
# Local image repository name used by docker-compose.yml (image: distroless-wp:<tag>).
LOCAL_IMAGE_REPOSITORY ?= distroless-wp
# Amazon ECR push destination: $(ECR_REGISTRY)/$(ECR_REPOSITORY):<same tag as the local image>.
# e.g. ECR_REGISTRY=123456789012.dkr.ecr.ap-northeast-1.amazonaws.com
ECR_REGISTRY ?=
ECR_REPOSITORY ?= distroless-wp
# Region defaults to the one in ECR_REGISTRY (<account>.dkr.ecr.<region>.amazonaws.com).
AWS_REGION ?= $(word 4,$(subst ., ,$(ECR_REGISTRY)))
# Docker Hub push destination for -local images: $(DOCKERHUB_NAMESPACE)/$(DOCKERHUB_REPOSITORY):<same tag>.
DOCKERHUB_NAMESPACE ?= dockerhubcolsis
DOCKERHUB_REPOSITORY ?= distroless-wp

.DEFAULT_GOAL := help

.PHONY: help build-local build-fargate rebuild-local rebuild-fargate _build \
	ecr-login push-local push-fargate _push _require-ecr-registry

help:
	@printf '%s\n' \
		'Usage:' \
		'  make build-local      Build app images for local runtime (DEPLOY_ENV=local, tag suffix -local)' \
		'  make build-fargate    Build app images for Fargate runtime (DEPLOY_ENV=fargate, tag suffix -fargate)' \
		'  make rebuild-local    Build local images without cache' \
		'  make rebuild-fargate  Build fargate images without cache' \
		'  make ecr-login        Log in to Amazon ECR (requires ECR_REGISTRY)' \
		'  make push-local       Tag and push built -local images to Docker Hub (run docker login first)' \
		'  make push-fargate     Tag and push built -fargate images to ECR (requires ECR_REGISTRY)' \
		'' \
		'Optional variables:' \
		'  PHP_VERSIONS="php83 php84 php85"' \
		'  WEBSERVERS="nginx httpd"' \
		'  ENV_FILE=.env' \
		'  IMAGE_TAG_SUFFIX_LOCAL=-local' \
		'  IMAGE_TAG_SUFFIX_FARGATE=-fargate' \
		'  PULL=--pull                  (set PULL= to use only locally cached base images)' \
		'  WP_VERSION=7.1.4             (default: WP_VERSION in ENV_FILE, else latest from WordPress.org)' \
		'  ECR_REGISTRY=123456789012.dkr.ecr.ap-northeast-1.amazonaws.com' \
		'  ECR_REPOSITORY=distroless-wp' \
		'  AWS_REGION=ap-northeast-1    (default: taken from ECR_REGISTRY)' \
		'  DOCKERHUB_NAMESPACE=dockerhubcolsis' \
		'  DOCKERHUB_REPOSITORY=distroless-wp'

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

_require-ecr-registry:
	@if [ -z '$(ECR_REGISTRY)' ]; then \
		echo 'error: ECR_REGISTRY is not set (e.g. ECR_REGISTRY=123456789012.dkr.ecr.ap-northeast-1.amazonaws.com)' >&2; \
		exit 1; \
	fi; \
	if [ -z '$(AWS_REGION)' ]; then \
		echo 'error: could not determine AWS_REGION from ECR_REGISTRY; pass AWS_REGION=...' >&2; \
		exit 1; \
	fi

ecr-login: _require-ecr-registry
	@echo '==> docker login $(ECR_REGISTRY) (region $(AWS_REGION))'
	@$(AWS) ecr get-login-password --region '$(AWS_REGION)' | $(DOCKER) login --username AWS --password-stdin '$(ECR_REGISTRY)'

push-local:
	@if [ -z '$(DOCKERHUB_NAMESPACE)' ] || [ -z '$(DOCKERHUB_REPOSITORY)' ]; then \
		echo 'error: DOCKERHUB_NAMESPACE and DOCKERHUB_REPOSITORY must not be empty' >&2; \
		exit 1; \
	fi
	@$(MAKE) --no-print-directory _push PUSH_SUFFIX=$(IMAGE_TAG_SUFFIX_LOCAL) \
		PUSH_DEST='$(DOCKERHUB_NAMESPACE)/$(DOCKERHUB_REPOSITORY)'

push-fargate: _require-ecr-registry
	@$(MAKE) --no-print-directory _push PUSH_SUFFIX=$(IMAGE_TAG_SUFFIX_FARGATE) \
		PUSH_DEST='$(ECR_REGISTRY)/$(ECR_REPOSITORY)'

# Internal: check that every image exists locally first, then tag and push them all to $(PUSH_DEST).
_push:
	@set -eu; \
	if [ -z '$(PUSH_DEST)' ]; then echo 'error: PUSH_DEST is not set' >&2; exit 1; fi; \
	tags=''; \
	for phpv in $(PHP_VERSIONS); do tags="$$tags wordpress-$${phpv}$(PUSH_SUFFIX)"; done; \
	for ws in $(WEBSERVERS); do tags="$$tags $${ws}$(PUSH_SUFFIX)"; done; \
	tags="$$tags wp-cli$(PUSH_SUFFIX)"; \
	missing=''; \
	for tag in $$tags; do \
		$(DOCKER) image inspect '$(LOCAL_IMAGE_REPOSITORY)':"$$tag" >/dev/null 2>&1 || missing="$$missing $(LOCAL_IMAGE_REPOSITORY):$$tag"; \
	done; \
	if [ -n "$$missing" ]; then \
		echo "error: local images not found:$$missing" >&2; \
		echo 'hint: run make build-local or make build-fargate first' >&2; \
		exit 1; \
	fi; \
	for tag in $$tags; do \
		remote='$(PUSH_DEST)':"$$tag"; \
		echo "==> push $$remote"; \
		$(DOCKER) tag '$(LOCAL_IMAGE_REPOSITORY)':"$$tag" "$$remote"; \
		$(DOCKER) push "$$remote"; \
	done
