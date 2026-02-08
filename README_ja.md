# distroless-wp

## 概要
- Docker Compose で動作するローカル WordPress 開発スタックです。
- `php` と `nginx` はマルチステージでビルドされ、実行ファイルを `gcr.io/distroless/base-debian13` にコピーしたカスタムイメージです。
- WordPress コアは `/var/www/html/wp`、ユーザー管理コンテンツは `/var/www/html/content` で提供されます。
- MySQL（8.0 または 8.4）、phpMyAdmin、Mailpit、`wp-cli` 補助サービスを含みます。

## 技術スタック
- Nginx（`bin/nginx/Dockerfile`）
- WordPress + PHP-FPM（`bin/php83/Dockerfile`, `bin/php84/Dockerfile`, `bin/php85/Dockerfile`）
- MySQL（`bin/mysql8/Dockerfile`, `bin/mysql84/Dockerfile`）
- phpMyAdmin（`phpmyadmin` イメージ）
- Mailpit（`axllent/mailpit:latest` イメージ）

## 主要パス
- `.env`: デフォルトポート、認証情報、利用イメージ選択の変数
- `docker-compose.yml`: サービス定義、マウント、コンテナ環境変数
- `www/wp-config.php`: `/var/www/html/wp/wp-config.php` にマウントされる WordPress 設定
- `www/content`: マウント対象のコンテンツディレクトリ（`languages`, `mu-plugins`, `plugins`, `themes`, `uploads`）
- `config/nginx/nginx.conf`: Nginx 全体設定
- `config/nginx/conf.d/default.conf`: HTTP 仮想ホストとルーティング/セキュリティ設定
- `config/nginx/conf.d/default-ssl.conf`: 任意 HTTPS サーバーブロックのテンプレート（コメントアウト状態）
- `config/php/php.ini`: PHP / phpMyAdmin コンテナで使う PHP 設定
- `bin/update-wordpress-languages.sh`: `wp-cli` で起動時に使う言語更新スクリプト

## ローカル開発（Docker）
1. コンテナ起動:
   - `docker compose up -d --build`
2. アクセス先:
   - `http://localhost:8080`（サイト）
   - `http://localhost:8080/wp/wp-admin`（WordPress 管理画面）
   - `http://localhost:9080`（phpMyAdmin）
   - `http://localhost:19980`（Mailpit UI）
3. 停止:
   - `docker compose stop`

ボリューム（DB や `wpdata` 上の WordPress ファイル）を作り直す場合:
- `docker compose down -v`
- `docker compose up -d --build`

## 設定メモ
- `PHPVERSION` は使用する PHP Dockerfile（`./bin/${PHPVERSION}/Dockerfile`）を切り替えます。
- `DATABASE` は使用する MySQL Dockerfile（`mysql8` または `mysql84`）を切り替えます。
- `WP_VERSION` はビルド時の WordPress コアを制御します。
  - `latest`: ベースの WordPress イメージ同梱コアをコピー
  - 例 `6.9.1`: そのバージョンの tarball をダウンロードして展開
- `STAGE=production` の場合は `www/wp-config.php` で WordPress のデバッグ定数が無効化されます。その他の値では有効化されます。

`.env` のデフォルトポート:
- HTTP: `8080`
- HTTPS: `8443`
- phpMyAdmin HTTP/HTTPS: `9080` / `9443`
- Mailpit SMTP/UI: `19925` / `19980`

データベース（`database` サービス）はホストへポート公開しておらず、Compose ネットワーク内（`database:3306`）からのみ接続できます。

## WP-CLI
- 補助サービス経由で実行します。
  - `docker compose exec wp-cli wp <command>`
- 例:
  - `docker compose exec wp-cli wp core version`
  - `docker compose exec wp-cli wp plugin list`

`wp-cli` サービスは起動時に `bin/update-wordpress-languages.sh` を実行します。
- WordPress がインストール済みなら、core/plugin/theme の言語パックを更新し `/var/www/html/.wp-language-updated` を作成します。
- 未インストールならエラーにせず終了します。

## メールテスト（Mailpit）
- Mailpit は Compose ネットワーク内で SMTP `mail:1025` として利用でき、UI は `http://localhost:19980` で確認できます。
- `www/content/plugins/fluent-smtp` が同梱されており、WordPress のメール送信先を Mailpit に向ける用途に使えます。

## HTTPS（任意）
1. `config/ssl` に `cert.pem` と `cert-key.pem` を配置します。
2. `config/nginx/conf.d/default-ssl.conf` の server ブロックをコメント解除します。
3. スタックを再起動し `https://localhost:8443` にアクセスします。
