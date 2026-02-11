# distroless-wp

## 概要
- Docker Compose で動作するローカル WordPress 開発スタックです。
- WordPress コアは `/var/www/html/wp`、変更対象コンテンツは `/var/www/html/content` に配置されます。
- `php` と `webserver` はマルチステージビルドされた `gcr.io/distroless/base-debian13` 実行イメージで動作します。
- `wp-cli`、phpMyAdmin、Mailpit を同梱しています。

## 技術スタック
- Apache HTTP Server 2.4（`bin/apache24/Dockerfile`）
- Nginx 1.29（`bin/nginx/Dockerfile`）
- WordPress + PHP-FPM（`bin/php83/Dockerfile`、`bin/php84/Dockerfile`、`bin/php85/Dockerfile`）
- MySQL（`bin/mysql8/Dockerfile` または `bin/mysql84/Dockerfile`）
- phpMyAdmin（`phpmyadmin`）
- Mailpit（`axllent/mailpit`）

## 主要パス
- `.env`: 既定の環境変数、ポート、イメージ選択
- `docker-compose.yml`: サービス定義、マウント、ネットワーク
- `www/wp-config.php`: WordPress 実行時設定（`/var/www/html/wp/wp-config.php` にマウント）
- `www/content`: ホスト側コンテンツ（`languages`, `mu-plugins`, `plugins`, `themes`, `uploads`）
- `config/php/php.ini`: `php` イメージおよび phpMyAdmin 用の PHP 設定
- `config/httpd/httpd.conf`: `WEBSERVER=apache24` のときにイメージへコピーされる Apache 全体設定
- `config/httpd/conf.d/default.conf`: Apache の vhost 設定と PHP-FPM プロキシ設定
- `config/nginx/nginx.conf`: イメージへコピーされる Nginx 全体設定
- `config/nginx/conf.d/default.conf`: HTTP サーバー設定と WordPress ルーティング
- `config/nginx/conf.d/default-ssl.conf`: 任意で使う HTTPS サーバーブロック雛形
- `bin/update-wordpress-languages.sh`: `wp-cli` で言語更新を1回実行するスクリプト

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

永続ボリューム（`wpdata`、`dbdata`、`mailpitdata`）を初期化する場合:
- `docker compose down -v`
- `docker compose up -d --build`

`.env` の既定ポート:
- HTTP: `HOST_MACHINE_UNSECURE_HOST_PORT=8080`
- HTTPS: `HOST_MACHINE_SECURE_HOST_PORT=8443`
- phpMyAdmin HTTP/HTTPS: `HOST_MACHINE_PMA_PORT=9080`、`HOST_MACHINE_PMA_SECURE_PORT=9443`
- Mailpit UI: `HOST_MACHINE_MAILPIT_PORT=19980`（`mail:1025` は Docker ネットワーク内のみ利用可能）

データベース接続:
- `database` サービスは Compose 内部ネットワークのみ公開（`expose: 3306`）です。
- 他コンテナからは `database:3306` で接続し、ホストからは phpMyAdmin を利用します。

### WP-CLI 実行手順（Docker Compose 経由）
- コマンド形式: `docker compose exec wp-cli wp <command>`
- 実行例:
  - `docker compose exec wp-cli wp core version`
  - `docker compose exec wp-cli wp plugin list`
  - `docker compose exec wp-cli wp core update-db`
  - `docker compose exec -T wp-cli wp option get home`

### イメージとバージョンの選択
- `PHPVERSION` は PHP イメージ Dockerfile を選択（`php83`、`php84`、`php85`）。既定値: `php84`
- `DATABASE` は DB イメージ Dockerfile を選択（`mysql8`、`mysql84`）。既定値: `mysql84`
- `WEBSERVER` は Web サーバーイメージ Dockerfile を選択（`apache24`、`nginx`）。既定値: `nginx`
- `WP_VERSION` は PHP ビルド時の WordPress コア取得元を指定。既定値: `latest`
- `.env` のこれらを変更後は `docker compose up -d --build` で再ビルドします
- `docker ps` では `wp-apache24` または `wp-nginx` というコンテナ名で稼働中の Web サーバーを判別できます

### Mailpit を使ったメール送信テスト（FluentSMTP）
WordPress から同梱 Mailpit に送信する場合:
1. `FluentSMTP` を有効化します。
2. SMTP 設定を以下にします。
   - Host: `mail`
   - Port: `1025`
   - Authentication: `disable`
   - Encryption: `none`
   - Auto TLS: `disable`

### HTTPS（任意）
- `config/ssl` に `cert.pem` と `cert-key.pem` を配置します。
- Nginx を使う場合は `config/nginx/conf.d/default-ssl.conf` の HTTPS サーバーブロックを有効化します。
- `https://localhost:8443` にアクセスします。

## 環境変数メモ
- `STAGE` に応じて `www/wp-config.php` のデバッグ系定数が切り替わります（`production` で無効化）。
- DB 認証情報と Salt は Compose 環境変数として注入されます。
- WordPress、MySQL、Mailpit の永続データは named volume（`wpdata`、`dbdata`、`mailpitdata`）に保存されます。
- ログのマウント先は `.env` で変更できます（`NGINX_LOG_DIR`、`HTTPD_LOG_DIR`、`PHP_FPM_LOG_DIR`、`MYSQL_LOG_DIR`）。
- ローカル以外で利用する場合は `.env` の Salt プレースホルダーを必ず置き換えてください。
- `wp-cli` 起動時に言語更新を1回実行し、`/var/www/html/.wp-language-updated` を作成します。
