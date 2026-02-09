# distroless-wp

## Overview
- Docker Compose stack for local WordPress development.
- `php` and `nginx` are custom multi-stage images that copy runtime files into `gcr.io/distroless/base-debian13`.
- WordPress core is served from `/var/www/html/wp`, and user-managed content is served from `/var/www/html/content`.
- Includes MySQL (8.0 or 8.4), phpMyAdmin, Mailpit, and a `wp-cli` helper service.

## Tech Stack
- Nginx (`bin/nginx/Dockerfile`)
- WordPress + PHP-FPM (`bin/php83/Dockerfile`, `bin/php84/Dockerfile`, `bin/php85/Dockerfile`)
- MySQL (`bin/mysql8/Dockerfile`, `bin/mysql84/Dockerfile`)
- phpMyAdmin (`phpmyadmin` image)
- Mailpit (`axllent/mailpit:latest` image)

## Key Paths
- `.env`: default ports, credentials, and image-selection variables
- `docker-compose.yml`: service definitions, mounts, and container environment variables
- `www/wp-config.php`: WordPress config mounted to `/var/www/html/wp/wp-config.php`
- `www/content`: mounted content directories (`languages`, `mu-plugins`, `plugins`, `themes`, `uploads`)
- `config/nginx/nginx.conf`: global Nginx settings
- `config/nginx/conf.d/default.conf`: HTTP virtual host and routing/security rules
- `config/nginx/conf.d/default-ssl.conf`: optional HTTPS server block template (commented)
- `config/php/php.ini`: PHP configuration used by PHP and phpMyAdmin containers
- `bin/update-wordpress-languages.sh`: startup language update script used by `wp-cli`

## Local Development (Docker)
1. Start containers:
   - `docker compose up -d --build`
2. Open:
   - `http://localhost:8080` (site)
   - `http://localhost:8080/wp/wp-admin` (WordPress admin)
   - `http://localhost:9080` (phpMyAdmin)
   - `http://localhost:19980` (Mailpit UI)
3. Stop:
   - `docker compose stop`

If you need to recreate volumes (including DB and WordPress files in `wpdata`):
- `docker compose down -v`
- `docker compose up -d --build`

## Configuration Notes
- `PHPVERSION` controls which PHP Dockerfile is used (`./bin/${PHPVERSION}/Dockerfile`).
- `DATABASE` controls which MySQL Dockerfile is used (`mysql8` or `mysql84`).
- `WP_VERSION` controls WordPress core at build time:
  - `latest`: copy bundled core from the base WordPress image.
  - e.g. `6.9.1`: download and extract that release tarball.
- `TIME_ZONE` sets `/etc/localtime` at build time for `nginx`, `php`, and `database` images.
- `STAGE=production` disables WordPress debug constants in `www/wp-config.php`; other values enable debug mode.

Default `.env` ports:
- HTTP: `8080`
- HTTPS: `8443`
- phpMyAdmin HTTP/HTTPS: `9080` / `9443`
- Mailpit UI: `19980`

Database (`database` service) is not published to the host and is reachable only inside the Compose network (`database:3306`).
Mailpit SMTP (`mail:1025`) is also internal-only and is not published to the host.

## WP-CLI
- Run commands via the helper service:
  - `docker compose exec wp-cli wp <command>`
- Examples:
  - `docker compose exec wp-cli wp core version`
  - `docker compose exec wp-cli wp plugin list`

At startup, the `wp-cli` service runs `bin/update-wordpress-languages.sh`.
- If WordPress is installed, it updates core/plugin/theme language packs and writes `/var/www/html/.wp-language-updated`.
- If WordPress is not installed, it exits without error.

## Mail Testing (Mailpit)
- Mailpit is exposed as SMTP `mail:1025` inside the Compose network and UI on `http://localhost:19980`.
- `www/content/plugins/fluent-smtp` is included in this repository and can be used to route WordPress mail to Mailpit.

## HTTPS (Optional)
1. Place `cert.pem` and `cert-key.pem` in `config/ssl`.
2. Uncomment the server block in `config/nginx/conf.d/default-ssl.conf`.
3. Restart the stack and access `https://localhost:8443`.
