# distroless-wp

## Overview
- Docker Compose stack for local WordPress development.
- WordPress core is placed under `/var/www/html/wp`, and mutable content is placed under `/var/www/html/content`.
- `php` and the `webserver` are custom multi-stage images that run on `gcr.io/distroless/base-debian13`.
- The stack includes `wp-cli`, phpMyAdmin, and Mailpit.

## Tech Stack
- Apache HTTP Server 2.4 (`bin/apache24/Dockerfile`)
- Nginx 1.29 (`bin/nginx/Dockerfile`)
- WordPress + PHP-FPM (`bin/php83/Dockerfile`, `bin/php84/Dockerfile`, `bin/php85/Dockerfile`)
- MySQL (`bin/mysql8/Dockerfile` or `bin/mysql84/Dockerfile`)
- phpMyAdmin (`phpmyadmin`)
- Mailpit (`axllent/mailpit`)

## Key Paths
- `.env`: default environment variables, ports, and image selectors
- `docker-compose.yml`: service definitions, mounts, and networking
- `www/wp-config.php`: WordPress runtime configuration (mounted to `/var/www/html/wp/wp-config.php`)
- `www/content`: host-mounted content (`languages`, `mu-plugins`, `plugins`, `themes`, `uploads`)
- `config/php/php.ini`: PHP configuration for `php` image and phpMyAdmin
- `config/httpd/httpd.conf`: Apache global configuration copied into the image when `WEBSERVER=apache24`
- `config/httpd/conf.d/default.conf`: Apache vhost rules and PHP-FPM proxy settings
- `config/nginx/nginx.conf`: top-level Nginx configuration copied into the image
- `config/nginx/conf.d/default.conf`: HTTP server rules and WordPress routing
- `config/nginx/conf.d/default-ssl.conf`: optional HTTPS server block template
- `bin/update-wordpress-languages.sh`: one-time language update script for `wp-cli`

## WordPress Layout (in Container)
```text
/var/www/html
├── index.php                # loads /wp/wp-blog-header.php
├── content
│   ├── languages
│   ├── mu-plugins
│   ├── plugins
│   ├── themes
│   └── uploads
└── wp
    ├── wp-admin
    ├── wp-includes
    ├── wp-config.php
    └── ...
```

## Local Development (Docker)
1. Start (first run, or after Dockerfile/config changes): `docker compose up -d --build`
2. Open:
   - `http://localhost:8080` (site)
   - `http://localhost:8080/wp/wp-admin` (WordPress admin)
   - `http://localhost:9080` (phpMyAdmin)
   - `http://localhost:19980` (Mailpit UI)
3. Stop: `docker compose stop`

To reset all persistent volumes (`wpdata`, `dbdata`, `mailpitdata`):
- `docker compose down -v`
- `docker compose up -d --build`

Default ports in `.env`:
- HTTP: `HOST_MACHINE_UNSECURE_HOST_PORT=8080`
- HTTPS: `HOST_MACHINE_SECURE_HOST_PORT=8443`
- phpMyAdmin HTTP/HTTPS: `HOST_MACHINE_PMA_PORT=9080`, `HOST_MACHINE_PMA_SECURE_PORT=9443`
- Mailpit UI: `HOST_MACHINE_MAILPIT_PORT=19980` (`mail:1025` is available only inside the Docker network)

Database access:
- The `database` service is exposed only inside the Compose network (`expose: 3306`).
- Use service name `database:3306` from other containers, or phpMyAdmin from the host.

### Run WP-CLI (via Docker Compose)
- Command format: `docker compose exec wp-cli wp <command>`
- Examples:
  - `docker compose exec wp-cli wp core version`
  - `docker compose exec wp-cli wp plugin list`
  - `docker compose exec wp-cli wp core update-db`
  - `docker compose exec -T wp-cli wp option get home`

### Image and Version Selection
- `PHPVERSION` selects the PHP image Dockerfile (`php83`, `php84`, `php85`), default: `php84`
- `DATABASE` selects the database Dockerfile (`mysql8`, `mysql84`), default: `mysql84`
- `WEBSERVER` selects the web server image Dockerfile (`apache24`, `nginx`), default: `nginx`
- `WP_VERSION` controls WordPress core source for the PHP build, default: `latest`
- After changing these values in `.env`, rebuild with `docker compose up -d --build`
- `docker ps` shows the active web server via container name (`wp-apache24` or `wp-nginx`)

### Mail Testing with Mailpit (FluentSMTP)
To send mail to the bundled Mailpit service from WordPress:
1. Activate `FluentSMTP`.
2. Configure SMTP settings:
   - Host: `mail`
   - Port: `1025`
   - Authentication: `disable`
   - Encryption: `none`
   - Auto TLS: `disable`

### HTTPS (optional)
- Put `cert.pem` and `cert-key.pem` in `config/ssl`.
- If using Nginx, uncomment the HTTPS server block in `config/nginx/conf.d/default-ssl.conf`.
- Access `https://localhost:8443`.

## Environment Notes
- `STAGE` controls WordPress debug-related constants in `www/wp-config.php` (`production` disables debug flags).
- DB credentials and auth salts are injected through Compose environment variables.
- Persistent WordPress, MySQL, and Mailpit data are stored in named volumes (`wpdata`, `dbdata`, `mailpitdata`).
- Log mount directories are configurable via `.env` (`NGINX_LOG_DIR`, `HTTPD_LOG_DIR`, `PHP_FPM_LOG_DIR`, `MYSQL_LOG_DIR`).
- Replace placeholder auth salts in `.env` before any non-local use.
- On startup, `wp-cli` runs language updates once and writes `/var/www/html/.wp-language-updated`.
