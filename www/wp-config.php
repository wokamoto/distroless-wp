<?php
/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the installation.
 * You don't have to use the website, you can copy this file to "wp-config.php"
 * and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * Database settings
 * * Secret keys
 * * Database table prefix
 * * ABSPATH
 *
 * @link https://developer.wordpress.org/advanced-administration/wordpress/wp-config/
 *
 * @package WordPress
 */

// ** Database settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define( 'DB_NAME', getenv( 'DB_NAME' ) ?: 'docker' );

/** Database username */
define( 'DB_USER', getenv( 'DB_USER' ) ?: 'docker' );

/** Database password */
define( 'DB_PASSWORD', getenv( 'DB_PASSWORD' ) ?: 'docker' );

/** Database hostname */
define( 'DB_HOST', getenv( 'DB_HOST' ) ?: 'database' );

/** Database charset to use in creating database tables. */
define( 'DB_CHARSET', 'utf8' );

/** The database collate type. Don't change this if in doubt. */
define( 'DB_COLLATE', '' );

/**#@+
 * Authentication unique keys and salts.
 *
 * Change these to different unique phrases! You can generate these using
 * the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}.
 *
 * You can change these at any point in time to invalidate all existing cookies.
 * This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define( 'AUTH_KEY',         getenv( 'AUTH_KEY' ) ?: 'put your unique phrase here' );
define( 'SECURE_AUTH_KEY',  getenv( 'SECURE_AUTH_KEY' ) ?: 'put your unique phrase here' );
define( 'LOGGED_IN_KEY',    getenv( 'LOGGED_IN_KEY' ) ?: 'put your unique phrase here' );
define( 'NONCE_KEY',        getenv( 'NONCE_KEY' ) ?: 'put your unique phrase here' );
define( 'AUTH_SALT',        getenv( 'AUTH_SALT' ) ?: 'put your unique phrase here' );
define( 'SECURE_AUTH_SALT', getenv( 'SECURE_AUTH_SALT' ) ?: 'put your unique phrase here' );
define( 'LOGGED_IN_SALT',   getenv( 'LOGGED_IN_SALT' ) ?: 'put your unique phrase here' );
define( 'NONCE_SALT',       getenv( 'NONCE_SALT' ) ?: 'put your unique phrase here' );

/**#@-*/

/**
 * WordPress database table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 *
 * At the installation time, database tables are created with the specified prefix.
 * Changing this value after WordPress is installed will make your site think
 * it has not been installed.
 *
 * @link https://developer.wordpress.org/advanced-administration/wordpress/wp-config/#table-prefix
 */
$table_prefix = 'wp_';

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the documentation.
 *
 * @link https://developer.wordpress.org/advanced-administration/debug/debug-wordpress/
 */
$stage = getenv( 'STAGE' );
$is_production_stage = is_string( $stage ) && 'production' === strtolower( trim( $stage ) );

define( 'WP_DEBUG', ! $is_production_stage );
define( 'WP_DEBUG_LOG', ! $is_production_stage );
define( 'SCRIPT_DEBUG', ! $is_production_stage );
define( 'WP_ENVIRONMENT_TYPE', $stage );
define( 'WP_DEVELOPMENT_MODE', ! $is_production_stage ? 'theme' : '' );

/* Add any custom values between this line and the "stop editing" line. */
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && strpos($_SERVER['HTTP_X_FORWARDED_PROTO'], 'https') !== false) {
	$_SERVER['HTTPS'] = 'on';
}
$server_name = $_SERVER['SERVER_NAME'] ?? 'localhost';
$scheme = ( ! empty( $_SERVER['HTTPS'] ) && 'off' !== $_SERVER['HTTPS'] ) ? 'https' : 'http';
$server_port = isset( $_SERVER['SERVER_PORT'] ) ? (string) $_SERVER['SERVER_PORT'] : '';

$is_default_port =
	( 'http' === $scheme && '80' === $server_port ) ||
	( 'https' === $scheme && '443' === $server_port );
$host = $server_name;
if ( '' !== $server_port && ! $is_default_port ) {
	$host .= ':' . $server_port;
}

if ( isset($_SERVER['HTTP_X_FORWARDED_PROTO']) ) {
	$scheme = $_SERVER['HTTP_X_FORWARDED_PROTO'];
}
if ( isset($_SERVER['HTTP_HOST']) ) {
	$host = $_SERVER['HTTP_HOST'];
}

define( 'WP_HOME', $scheme . '://' . $host );
define( 'WP_SITEURL', WP_HOME . '/wp' );

define( 'WP_CONTENT_DIR', dirname( __DIR__ ) . '/content' );
define( 'WP_CONTENT_URL', WP_HOME . '/content' );
define( 'WP_PLUGIN_DIR', WP_CONTENT_DIR . '/plugins' );
define( 'WPMU_PLUGIN_DIR', WP_CONTENT_DIR . '/mu-plugins' );
define( 'WP_PLUGIN_URL', WP_CONTENT_URL . '/plugins' );
define( 'WPMU_PLUGIN_URL', WP_CONTENT_URL . '/mu-plugins' );
define( 'PLUGINDIR', WP_CONTENT_URL . '/plugins' );


/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}

/** Sets up WordPress vars and included files. */
require_once ABSPATH . 'wp-settings.php';
