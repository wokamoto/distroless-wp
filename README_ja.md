# distroless-wp

## 概要
- Docker Compose で動作するローカル WordPress 開発スタックである。
- WordPress コアは `/var/www/html/wp`、変更対象コンテンツは `/var/www/html/content` に配置される。
- `php`、`webserver`、`wp-cli` は、`gcr.io/distroless/static-debian13` を実行イメージとして利用する。
- `wp-cli`、phpMyAdmin、Mailpit を同梱する。

## 技術スタック
- Nginx（`bin/webserver/nginx/Dockerfile`）
- Apache HTTP Server（`bin/webserver/httpd/Dockerfile`）
- WordPress + PHP-FPM（`bin/wordpress/php83/Dockerfile` ほか）
- MySQL（`bin/database/mysql80/Dockerfile` または `bin/database/mysql84/Dockerfile`）
- phpMyAdmin（`phpmyadmin`）
- Mailpit（`axllent/mailpit`）

## 主要パス
- `.env`: 既定の環境変数、ポート、イメージ選択
- `docker-compose.yml`: サービス定義、マウント、ネットワーク
- `www/wp-config.php`: WordPress 実行時設定（`/var/www/html/wp/wp-config.php` にマウント）
- `www/content`: ホスト側コンテンツ（`languages` / `mu-plugins` / `plugins` / `themes` / `uploads`）
- `config/php/php.ini`: `php` イメージおよび phpMyAdmin 用の PHP 設定
- `config/nginx/nginx.conf`: イメージへコピーされる Nginx 全体設定
- `config/nginx/conf.d/default.conf`: HTTP サーバー設定と WordPress ルーティング
- `config/nginx/conf.d/default-ssl.conf`: 任意で使う HTTPS サーバーブロック雛形
- `config/httpd/httpd.conf`: `WEBSERVER=httpd` の場合にイメージへコピーされる Apache 全体設定
- `config/httpd/conf.d/default.conf`: Apache の vhost 設定と PHP-FPM プロキシ設定
- `config/initdb`: DB 初期化 SQL/スクリプトを `/docker-entrypoint-initdb.d` にマウントする既定パス
- `bin/wordpress/cli/update-wordpress-languages.sh`: `wp-cli` で言語更新を1回実行するスクリプト

## WordPress ディレクトリ構成（コンテナ内）
```text
/var/www/html
├── index.php                # /wp/wp-blog-header.php を読み込み
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

## ローカル開発（Docker）
1. 起動（初回、または Dockerfile/設定変更後）: `docker compose up -d --build`
2. アクセス:
   - `http://localhost:8080`（サイト）
   - `http://localhost:8080/wp/wp-admin`（WordPress 管理画面）
   - `http://localhost:9080`（phpMyAdmin）
   - `http://localhost:19980`（Mailpit UI）
3. 停止: `docker compose stop`

永続 named volume（`dbdata`、`mailpitdata`）の初期化。
- `docker compose down -v`
- `docker compose up -d --build`

`.env` の既定ポート。
- HTTP: `HOST_MACHINE_UNSECURE_HOST_PORT=8080`
- HTTPS: `HOST_MACHINE_SECURE_HOST_PORT=8443`
- phpMyAdmin HTTP/HTTPS: `HOST_MACHINE_PMA_PORT=9080`、`HOST_MACHINE_PMA_SECURE_PORT=9443`
- Mailpit UI: `HOST_MACHINE_MAILPIT_PORT=19980`（`mail:1025` は Docker ネットワーク内のみ利用可能）

データベース接続。
- `database` サービスは Compose 内部ネットワークのみ公開（`expose: 3306`）である。
- 他コンテナからは `database:3306` で接続し、ホストからは phpMyAdmin を利用する。

### WP-CLI 実行手順（Docker Compose 経由）
- コマンド形式: `docker compose exec wp-cli wp <command>`
- 実行例:
  - `docker compose exec wp-cli wp core version`
  - `docker compose exec wp-cli wp plugin list`
  - `docker compose exec wp-cli wp core update-db`
  - `docker compose exec -T wp-cli wp option get home`

### イメージとバージョンの選択
- `PHPVERSION` は PHP イメージ Dockerfile を選択（`php83`、`php84`、`php85`）。既定値: `php84`
- `DATABASE` は DB イメージ Dockerfile を選択（`mysql80`、`mysql84`）。既定値: `mysql84`
- `WEBSERVER` は Web サーバーイメージ Dockerfile を選択（`httpd`、`nginx`）。既定値: `nginx`
- `WP_VERSION` は PHP ビルド時の WordPress コア取得元を指定。既定値: `latest`
- `.env` のこれらを変更後は `docker compose up -d --build` で再ビルドする。
- コンテナ名には `COMPOSE_PROJECT_NAME`（既定: `wp`）が接頭辞として付与される。
- Web サーバーのコンテナ名は `${COMPOSE_PROJECT_NAME}-httpd` または `${COMPOSE_PROJECT_NAME}-nginx` となる。

### Mailpit を使ったメール送信テスト（FluentSMTP）
WordPress から同梱 Mailpit に送信する設定手順。
1. `FluentSMTP` を有効化する。
2. SMTP は次の値で設定する。
   - Host: `mail`
   - Port: `1025`
   - Authentication: `disable`
   - Encryption: `none`
   - Auto TLS: `disable`

### HTTPS（任意）
- `config/ssl` に `cert.pem` と `cert-key.pem` を配置する。
- Nginx を使う場合は `config/nginx/conf.d/default-ssl.conf` の HTTPS サーバーブロックを有効化する。
- `https://localhost:8443` にアクセスする。

## 環境変数メモ
- `STAGE` に応じて `www/wp-config.php` のデバッグ系定数が切り替わる（`production` で無効化）。
- DB 認証情報と Salt は Compose 環境変数として注入される。
- WordPress コンテンツは `${WP_CONTENT_DIR-./www/content}` の bind mount で保持される。
- MySQL と Mailpit のデータは named volume（`dbdata`、`mailpitdata`）に保存される。
- ログのマウント先は `.env` で変更できる（`NGINX_LOG_DIR`、`HTTPD_LOG_DIR`、`PHP_FPM_LOG_DIR`、`MYSQL_LOG_DIR`）。
- ローカル以外で利用する場合は `.env` の Salt プレースホルダーを置き換える。
- `wp-cli` 起動時に言語更新を1回実行し、`/var/www/html/.wp-language-updated` を作成する。
